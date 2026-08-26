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
# Desired Git hook configuration
#
# The pre-receive hook refuses any push that would add/modify/delete files
# under the workflow directories unless the ref is a trusted one (main / v*),
# which is already locked down at the permission layer.  It is the
# server-side backstop that makes it impossible for a feature-branch push to
# smuggle in a workflow that could read secrets.
#
# Gitea stores this content at hooks/pre-receive.d/pre-receive.  The
# generated hooks/pre-receive wrapper runs every executable file in that
# directory, so setting this content is all that is needed for it to take
# effect.  The API returns the content verbatim, so "already set properly"
# is an exact-content match against this constant.
# ---------------------------------------------------------------------------

GIT_HOOKS = {
    "pre-receive": r'''#!/usr/bin/env bash
# ============================================================================
#  pre-receive hook: "No workflow changes from untrusted branches"
#
#  WHERE:   Gitea Repo -> Settings -> Git Hooks -> "pre-receive" ->
#           paste this -> Update.  (No restart needed; Gitea installs it
#           server-side in hooks/pre-receive.d/ and its wrapper runs it.)
#
#  WHAT:    Any push that would ADD / MODIFY / DELETE files under the
#           workflow directories is REJECTED before the ref is updated --
#           UNLESS the ref is one of TRUSTED_REFS (main branch / v* tags),
#           which you keep locked down at the permission layer.
#
#  WHY:     A workflow is code that runs with access to repo/org secrets.
#           A feature-branch / PR push is untrusted input, so a workflow
#           arriving that way must never exist server-side.  It can't leak
#           secrets if it was never accepted.  Workflow changes can only
#           land via main or a v* tag -- the refs you already protect.
#
#  NOTES:
#   * Rejects ANY pushed history that touched the workflow dirs -- even an
#     add-then-revert pair.  The server never records that content.  (If you
#     later want "only the resulting tree matters", switch the existing-ref
#     branch to a bare `git diff --name-only` and drop the `--not --all`
#     history scan for new branches.)
#   * Deletion of any ref is always allowed.
# ============================================================================

WORKFLOW_DIRS=( ".gitea/workflows" ".github/workflows" )   # paths to guard
TRUSTED_REFS=( "refs/heads/main" "refs/tags/v*" )          # may touch them

ZERO="0000000000000000000000000000000000000000"

is_trusted() {
    local ref="$1" pat
    for pat in "${TRUSTED_REFS[@]}"; do
        # shellcheck disable=SC2254
        case "$ref" in $pat) return 0 ;; esac
    done
    return 1
}

# Prints (one per line) the workflow files a ref update would change.
workflow_changes() {
    local old="$1" new="$2"
    local args=() i
    for i in "${WORKFLOW_DIRS[@]}"; do
        args+=( "$i" )
    done

    if [ "$old" = "$ZERO" ]; then
        # New ref: only the commits this push actually introduces matter.
        git log --format= --name-only --no-renames "$new" --not --all -- "${args[@]}" 2>/dev/null
    else
        # Existing ref: net diff between what is there and what will be.
        git diff --name-only --no-renames "$old" "$new" -- "${args[@]}" 2>/dev/null
    fi
}

rejected=0
while read -r old new ref; do
    [ -n "$ref" ] || continue
    # deletion of a ref is always allowed
    [ "$new" = "$ZERO" ] && continue
    # trusted refs (main / v*) may modify workflows
    is_trusted "$ref" && continue

    changes="$(workflow_changes "$old" "$new")"
    if [ -n "$changes" ]; then
        echo "*** [pre-receive] PUSH REJECTED ***" >&2
        echo "Ref '$ref' changes files under the workflow dirs, which is not allowed." >&2
        echo "Workflow changes may only arrive via a trusted ref (main / v*):" >&2
        printf '%s\n' "$changes" | sed 's/^/    /' >&2
        echo "The push was not accepted; no refs were updated." >&2
        rejected=1
    fi
done
# shellcheck disable=SC2317
exit "$rejected"
''',
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
# Git hooks
# ---------------------------------------------------------------------------

def get_git_hook(owner, repo, hook_name):
    """
    Return the existing {hook_name} hook, or None if it is not set.

    Gitea returns is_active=false with empty content when the hook is not
    configured.  Treat that as "not set" so it is reported and applied
    like the branch/tag protections below.
    """

    hook = api(
        "GET",
        f"/repos/{quote(owner)}/{quote(repo)}/hooks/git/"
        f"{quote(hook_name)}",
    )

    if not hook.get("is_active"):
        return None

    return hook


def describe_git_hook(hook):
    """Return a concise description of the current hook state."""

    if hook is None:
        return "NOT SET"

    return "SET"


def apply_git_hook(owner, repo, hook_name):
    """Set the hook content to the desired value."""

    api(
        "PATCH",
        f"/repos/{quote(owner)}/{quote(repo)}/hooks/git/"
        f"{quote(hook_name)}",
        json={"content": GIT_HOOKS[hook_name]},
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

    hook_changed = 0
    hook_unchanged = 0

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

            # ---------------------------------------------------------------
            # Pre-receive Git hook
            # ---------------------------------------------------------------

            hook = get_git_hook(owner, name, "pre-receive")

            if hook is None:
                print("  Hook:   NOT SET")
                print("    Would SET pre-receive hook")

                if args.apply:
                    result = apply_git_hook(owner, name, "pre-receive")
                    print(f"    {result}")

                hook_changed += 1

            elif hook.get("content") == GIT_HOOKS["pre-receive"]:
                print("  Hook:   SET (matches desired content)")
                hook_unchanged += 1

            else:
                print("  Hook:   SET (content differs)")
                print("    Would UPDATE pre-receive hook")

                if args.apply:
                    result = apply_git_hook(owner, name, "pre-receive")
                    print(f"    {result}")

                hook_changed += 1

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
    print(f"Hooks changed:     {hook_changed}")
    print(f"Hooks unchanged:   {hook_unchanged}")
    print()
    print(f"Skipped:           {skipped}")
    print(f"Failed:            {failed}")

    if not args.apply:
        print()
        print("Dry run complete. Nothing was changed.")


if __name__ == "__main__":
    main()

