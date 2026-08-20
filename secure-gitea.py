#!/usr/bin/env python3

import argparse
import os
import sys
from urllib.parse import quote

import requests


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

GITEA_URL = "https://" + os.environ.get("GITEA_DOMAIN", "").rstrip("/")
GITEA_TOKEN = os.environ.get("GITEA_TOKEN", "")
USERNAME = os.environ.get("GITEA_ADMIN", "andrew")

BRANCH = "main"
TAG_PATTERN = "v*"

# Number of repositories to request per API page.
PAGE_SIZE = 50


# ---------------------------------------------------------------------------
# Desired branch protection configuration
#
# Only fields listed here are managed by this script.
# Other Gitea branch-protection settings are left untouched.
# ---------------------------------------------------------------------------

BRANCH_DESIRED = {
    "rule_name": BRANCH,

    # Direct pushes
    "enable_push": True,
    "enable_push_whitelist": True,
    "push_whitelist_usernames": [USERNAME],
    "push_whitelist_teams": [],
    "push_whitelist_deploy_keys": False,

    # Force pushes -- explicitly disabled
    "enable_force_push": False,
    "enable_force_push_whitelist": False,
    "force_push_whitelist_usernames": [],
    "force_push_whitelist_teams": [],
    "force_push_whitelist_deploy_keys": False,

    # Pull request approvals
    "required_approvals": 1,
    "enable_approvals_whitelist": True,
    "approvals_whitelist_username": [USERNAME],
    "approvals_whitelist_teams": [],

    # Pull request merging
    "enable_merge_whitelist": True,
    "merge_whitelist_usernames": [USERNAME],
    "merge_whitelist_teams": [],

    # Status checks
    "enable_status_check": False,
    "status_check_contexts": [],
}


# ---------------------------------------------------------------------------
# Gitea nullable branch-protection fields
#
# Gitea returns None for these fields when the corresponding whitelist
# functionality is disabled. Treat those values as equivalent to the
# explicit values above when comparing configurations.
# ---------------------------------------------------------------------------

BRANCH_NULL_EQUIVALENTS = {
    "enable_force_push_whitelist": False,
    "force_push_whitelist_usernames": [],
    "force_push_whitelist_teams": [],
    "force_push_whitelist_deploy_keys": False,
}


# ---------------------------------------------------------------------------
# Desired tag protection configuration
#
# Tags matching TAG_PATTERN are protected. Only USERNAME may create/delete
# those tags.
# ---------------------------------------------------------------------------

TAG_DESIRED = {
    "name_pattern": TAG_PATTERN,
    "whitelist_usernames": [USERNAME],
    "whitelist_teams": [],
}


# ---------------------------------------------------------------------------
# API session
# ---------------------------------------------------------------------------

session = requests.Session()
session.headers.update({
    "Authorization": f"token {GITEA_TOKEN}",
    "Accept": "application/json",
    "Content-Type": "application/json",
})


def api(method, path, **kwargs):
    """Make a request to the Gitea API."""

    url = f"{GITEA_URL}/api/v1{path}"

    response = session.request(method, url, **kwargs)

    if not response.ok:
        print(
            f"ERROR {method} {path}: "
            f"{response.status_code} {response.text}",
            file=sys.stderr,
        )
        response.raise_for_status()

    if response.status_code == 204:
        return None

    return response.json()


# ---------------------------------------------------------------------------
# Value comparison
# ---------------------------------------------------------------------------

def values_equal(key, current, desired):
    """
    Compare a value returned by Gitea against the desired value.

    Some Gitea branch-protection fields are returned as None when their
    associated feature is disabled. Those fields are explicitly handled
    above so that None and their configured disabled value are equivalent.
    """

    if current is None and key in BRANCH_NULL_EQUIVALENTS:
        return desired == BRANCH_NULL_EQUIVALENTS[key]

    return current == desired


def describe_changes(current, desired, ignored=()):
    """
    Return human-readable descriptions of managed fields that differ.
    """

    changes = []

    for key, wanted in desired.items():
        if key in ignored:
            continue

        actual = current.get(key)

        if not values_equal(key, actual, wanted):
            changes.append(
                f"{key}: {actual!r} -> {wanted!r}"
            )

    return changes


# ---------------------------------------------------------------------------
# Repository enumeration
# ---------------------------------------------------------------------------

def get_all_repositories():
    """Enumerate every repository the authenticated user can administer."""

    repos = []
    page = 1

    while True:
        batch = api(
            "GET",
            "/user/repos",
            params={
                "limit": PAGE_SIZE,
                "page": page,
            },
        )

        if not batch:
            break

        repos.extend(batch)

        if len(batch) < PAGE_SIZE:
            break

        page += 1

    return repos


# ---------------------------------------------------------------------------
# Branch protection
# ---------------------------------------------------------------------------

def get_branch_protection(owner, repo):
    """Return the existing protection for BRANCH, or None."""

    protections = api(
        "GET",
        f"/repos/{quote(owner)}/{quote(repo)}/branch_protections",
    )

    for protection in protections:
        if protection.get("rule_name") == BRANCH:
            return protection

    return None


def describe_branch_protection(protection):
    """Return a concise description of the current branch protection."""

    if protection is None:
        return "NO PROTECTION"

    return (
        f"push={protection.get('enable_push')} "
        f"push_allowlist={protection.get('push_whitelist_usernames')} "
        f"force_push={protection.get('enable_force_push')} "
        f"approvals={protection.get('required_approvals')} "
        f"approval_allowlist="
        f"{protection.get('approvals_whitelist_username')} "
        f"merge_allowlist="
        f"{protection.get('merge_whitelist_usernames')}"
    )


def apply_branch_protection(owner, repo, existing):
    """Create or update the branch protection."""

    encoded_owner = quote(owner)
    encoded_repo = quote(repo)

    if existing is None:
        api(
            "POST",
            f"/repos/{encoded_owner}/{encoded_repo}/branch_protections",
            json=BRANCH_DESIRED,
        )

        return "CREATED"

    # PATCH only the fields explicitly managed by this script.
    payload = {
        key: value
        for key, value in BRANCH_DESIRED.items()
        if key != "rule_name"
    }

    api(
        "PATCH",
        f"/repos/{encoded_owner}/{encoded_repo}/branch_protections/"
        f"{quote(BRANCH)}",
        json=payload,
    )

    return "UPDATED"


# ---------------------------------------------------------------------------
# Tag protection
# ---------------------------------------------------------------------------

def get_tag_protection(owner, repo):
    """Return the existing protection for TAG_PATTERN, or None."""

    protections = api(
        "GET",
        f"/repos/{quote(owner)}/{quote(repo)}/tag_protections",
    )

    for protection in protections:
        if protection.get("name_pattern") == TAG_PATTERN:
            return protection

    return None


def describe_tag_protection(protection):
    """Return a concise description of the current tag protection."""

    if protection is None:
        return "NO PROTECTION"

    return (
        f"users={protection.get('whitelist_usernames')} "
        f"teams={protection.get('whitelist_teams')}"
    )


def apply_tag_protection(owner, repo, existing):
    """Create or update the tag protection."""

    encoded_owner = quote(owner)
    encoded_repo = quote(repo)

    if existing is None:
        api(
            "POST",
            f"/repos/{encoded_owner}/{encoded_repo}/tag_protections",
            json=TAG_DESIRED,
        )

        return "CREATED"

    # PATCH only the fields explicitly managed by this script.
    payload = {
        key: value
        for key, value in TAG_DESIRED.items()
        if key != "name_pattern"
    }

    api(
        "PATCH",
        f"/repos/{encoded_owner}/{encoded_repo}/tag_protections/"
        f"{quote(str(existing['id']))}",
        json=payload,
    )

    return "UPDATED"


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description=(
            "Apply standardized Gitea branch and tag protection."
        )
    )

    parser.add_argument(
        "--apply",
        action="store_true",
        help=(
            "Actually modify repositories. Without this, only show "
            "what would happen."
        ),
    )

    args = parser.parse_args()

    # -----------------------------------------------------------------------
    # Validate configuration
    # -----------------------------------------------------------------------

    if not GITEA_URL or GITEA_URL == "https://":
        print("GITEA_DOMAIN is not set.", file=sys.stderr)
        sys.exit(1)

    if not GITEA_TOKEN:
        print("GITEA_TOKEN is not set.", file=sys.stderr)
        sys.exit(1)

    # -----------------------------------------------------------------------
    # Header
    # -----------------------------------------------------------------------

    print(f"Gitea:       {GITEA_URL}")
    print(f"Branch:      {BRANCH}")
    print(f"Tag pattern: {TAG_PATTERN}")
    print(f"User:        {USERNAME}")
    print()

    if not args.apply:
        print("*** DRY RUN ***")
        print("Use --apply to actually make changes.")
        print()

    # -----------------------------------------------------------------------
    # Enumerate repositories
    # -----------------------------------------------------------------------

    print("Enumerating repositories...")

    repositories = get_all_repositories()

    print(f"Found {len(repositories)} repositories.")
    print()

    # -----------------------------------------------------------------------
    # Counters
    # -----------------------------------------------------------------------

    branch_changed = 0
    branch_unchanged = 0

    tag_changed = 0
    tag_unchanged = 0

    skipped = 0
    failed = 0

    # -----------------------------------------------------------------------
    # Process repositories
    # -----------------------------------------------------------------------

    for repo in repositories:
        owner = repo["owner"]["login"]
        name = repo["name"]

        print(f"[{owner}/{name}]")

        # Archived repositories cannot have their protection modified.
        if repo.get("archived", False):
            print("  SKIP: archived")
            skipped += 1
            print()
            continue

        try:
            # ---------------------------------------------------------------
            # Branch protection
            # ---------------------------------------------------------------

            protection = get_branch_protection(owner, name)

            print(
                f"  Branch: {describe_branch_protection(protection)}"
            )

            if protection is None:
                print(
                    f"    Would CREATE protection for {BRANCH}"
                )

                if args.apply:
                    result = apply_branch_protection(
                        owner,
                        name,
                        protection,
                    )
                    print(f"    {result}")

                branch_changed += 1

            else:
                branch_changes = describe_changes(
                    protection,
                    BRANCH_DESIRED,
                    ignored=("rule_name",),
                )

                if not branch_changes:
                    print("    OK: already matches")
                    branch_unchanged += 1

                else:
                    print(
                        f"    Would UPDATE protection for {BRANCH}"
                    )

                    for change in branch_changes:
                        print(f"      {change}")

                    if args.apply:
                        result = apply_branch_protection(
                            owner,
                            name,
                            protection,
                        )
                        print(f"    {result}")

                    branch_changed += 1

            # ---------------------------------------------------------------
            # Tag protection
            # ---------------------------------------------------------------

            tag_protection = get_tag_protection(owner, name)

            print(
                f"  Tags:   {describe_tag_protection(tag_protection)}"
            )

            if tag_protection is None:
                print(
                    f"    Would CREATE protection for {TAG_PATTERN}"
                )

                if args.apply:
                    result = apply_tag_protection(
                        owner,
                        name,
                        tag_protection,
                    )
                    print(f"    {result}")

                tag_changed += 1

            else:
                tag_changes = describe_changes(
                    tag_protection,
                    TAG_DESIRED,
                    ignored=("name_pattern",),
                )

                if not tag_changes:
                    print("    OK: already matches")
                    tag_unchanged += 1

                else:
                    print(
                        f"    Would UPDATE protection for {TAG_PATTERN}"
                    )

                    for change in tag_changes:
                        print(f"      {change}")

                    if args.apply:
                        result = apply_tag_protection(
                            owner,
                            name,
                            tag_protection,
                        )
                        print(f"    {result}")

                    tag_changed += 1

        except requests.HTTPError:
            print("  FAILED")
            failed += 1

        print()

    # -----------------------------------------------------------------------
    # Summary
    # -----------------------------------------------------------------------

    print("----------------------------------------")
    print(f"Repositories:      {len(repositories)}")
    print()
    print(f"Branch changed:    {branch_changed}")
    print(f"Branch unchanged:  {branch_unchanged}")
    print()
    print(f"Tags changed:      {tag_changed}")
    print(f"Tags unchanged:    {tag_unchanged}")
    print()
    print(f"Skipped:           {skipped}")
    print(f"Failed:            {failed}")

    if not args.apply:
        print()
        print("Dry run complete. Nothing was changed.")


if __name__ == "__main__":
    main()

