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

# Number of repositories to request per API page.
PAGE_SIZE = 50


# ---------------------------------------------------------------------------
# API helpers
# ---------------------------------------------------------------------------

session = requests.Session()
session.headers.update({
    "Authorization": f"token {GITEA_TOKEN}",
    "Accept": "application/json",
    "Content-Type": "application/json",
})


def api(method, path, **kwargs):
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


def get_branch_protection(owner, repo):
    """Return the existing protection for main, or None."""

    protections = api(
        "GET",
        f"/repos/{quote(owner)}/{quote(repo)}/branch_protections",
    )

    for protection in protections:
        if protection.get("rule_name") == BRANCH:
            return protection

    return None


# ---------------------------------------------------------------------------
# Desired configuration
# ---------------------------------------------------------------------------

DESIRED = {
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

    # Explicitly disable status checks.
    #
    # Remove these two entries if you want to preserve whatever
    # status-check configuration each repository currently has.
    "enable_status_check": False,
    "status_check_contexts": [],
}


def describe_current(protection):
    if protection is None:
        return "NO PROTECTION"

    return (
        f"push={protection.get('enable_push')} "
        f"push_allowlist={protection.get('push_whitelist_usernames')} "
        f"force_push={protection.get('enable_force_push')} "
        f"approvals={protection.get('required_approvals')} "
        f"approval_allowlist={protection.get('approvals_whitelist_username')} "
        f"merge_allowlist={protection.get('merge_whitelist_usernames')}"
    )


def needs_update(protection):
    if protection is None:
        return True

    return any(
        protection.get(key) != value
        for key, value in DESIRED.items()
        if key != "rule_name"
    )


def apply_protection(owner, repo, existing):
    encoded_owner = quote(owner)
    encoded_repo = quote(repo)

    if existing is None:
        api(
            "POST",
            f"/repos/{encoded_owner}/{encoded_repo}/branch_protections",
            json=DESIRED,
        )
        return "CREATED"

    # PATCH only the fields we explicitly manage.
    payload = {
        key: value
        for key, value in DESIRED.items()
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
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Apply standardized Gitea main branch protection."
    )

    parser.add_argument(
        "--apply",
        action="store_true",
        help="Actually modify repositories. Without this, only show what would happen.",
    )

    args = parser.parse_args()

    if not GITEA_URL:
        print("GITEA_DOMAIN is not set.", file=sys.stderr)
        sys.exit(1)

    if not GITEA_TOKEN:
        print("GITEA_TOKEN is not set.", file=sys.stderr)
        sys.exit(1)

    print(f"Gitea: {GITEA_URL}")
    print(f"Branch: {BRANCH}")
    print(f"User:   {USERNAME}")
    print()

    if not args.apply:
        print("*** DRY RUN ***")
        print("Use --apply to actually make changes.")
        print()

    print("Enumerating repositories...")

    repositories = get_all_repositories()

    print(f"Found {len(repositories)} repositories.")
    print()

    changed = 0
    unchanged = 0
    skipped = 0
    failed = 0

    for repo in repositories:
        owner = repo["owner"]["login"]
        name = repo["name"]

        print(f"[{owner}/{name}]")

        # Skip archived repositories because Gitea won't allow their
        # branch protection to be modified.
        if repo.get("archived", False):
            print("  SKIP: archived")
            skipped += 1
            continue

        try:
            protection = get_branch_protection(owner, name)

            print(f"  Current: {describe_current(protection)}")

            if not needs_update(protection):
                print("  OK: already matches")
                unchanged += 1
                continue

            if protection is None:
                action = "CREATE"
            else:
                action = "UPDATE"

            print(f"  Would {action} protection for {BRANCH}")

            if args.apply:
                result = apply_protection(owner, name, protection)
                print(f"  {result}")
                changed += 1
            else:
                changed += 1

        except requests.HTTPError:
            print("  FAILED")
            failed += 1

        print()

    print("----------------------------------------")
    print(f"Repositories: {len(repositories)}")
    print(f"Changed:      {changed}")
    print(f"Unchanged:    {unchanged}")
    print(f"Skipped:      {skipped}")
    print(f"Failed:       {failed}")

    if not args.apply:
        print()
        print("Dry run complete. Nothing was changed.")


if __name__ == "__main__":
    main()

