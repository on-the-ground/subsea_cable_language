#!/usr/bin/env python3
"""Reject incomplete SCP status transitions to Accepted.

This check is a floor, not a proof of complete synchronization. It asks whether
an activation diff touches at least one normative projection and whether the
activated SCP carries its activation metadata. It does not verify that every
affected projection was updated, and with several SCPs activated in one pull
request it does not attribute a projection to a particular SCP. Reviewers still
own completeness.
"""

from __future__ import annotations

import re
import subprocess
import sys


PROPOSAL_PATH = re.compile(r"^proposals/\d{4}-[^/]+\.md$")
STATUS = re.compile(r"^- Status:[ \t]*(.*?)[ \t]*\r?$", re.MULTILINE)
# Normative projections. implementation/RUNTIME_CONTRACT.md belongs here because
# it states its own MUST/MUST NOT conformance requirements: a decision that only
# changes the Runtime contract is correctly activated by touching it alone. The
# rest of implementation/ is deliberately excluded, since a non-normative plan
# such as CAROUSEL_ENGINE_PLAN.md must not satisfy this check on its own.
CORE_PROJECTIONS = {
    "README.md",
    "SubseaCable.g4",
    "SubseaCable.ebnf",
    "implementation/RUNTIME_CONTRACT.md",
}
ACTIVATION_FIELDS = ("Activation pull request", "Effective language revision")
ACTIVATION_RECORD_FIELDS = (
    "Canonical documents synchronized",
    "Grammar projections synchronized",
    "Diagnostics and examples synchronized",
    "Conformance cases synchronized",
    "Compatibility and migration notes synchronized",
    "Verification commands and results",
)
EMPTY_VALUES = {"", "-", "—", "n/a", "na", "none", "pending", "tbd"}


def git(*arguments: str, allow_failure: bool = False) -> str:
    result = subprocess.run(
        ("git", *arguments),
        check=False,
        text=True,
        encoding="utf-8",
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    if result.returncode and not allow_failure:
        raise RuntimeError(result.stderr.strip() or "git command failed")
    return result.stdout if result.returncode == 0 else ""


def status_of(document: str) -> str | None:
    match = STATUS.search(document)
    return match.group(1).strip() if match else None


def field_value(document: str, name: str) -> str | None:
    match = re.search(
        rf"^- {re.escape(name)}:[ \t]*([^\r\n]*?)[ \t]*\r?$",
        document,
        re.MULTILINE,
    )
    return match.group(1).strip() if match else None


def activation_record(document: str) -> str | None:
    match = re.search(
        r"^## Activation record\s*$\n(?P<body>.*?)(?=^## |\Z)",
        document,
        re.MULTILINE | re.DOTALL,
    )
    return match.group("body") if match else None


def is_filled(value: str | None) -> bool:
    return value is not None and value.strip().lower() not in EMPTY_VALUES


def validate_activation_document(path: str, document: str) -> list[str]:
    errors: list[str] = []
    if status_of(document) != "Accepted":
        errors.append(f"{path}: activated status must be exactly 'Accepted'")

    for name in ACTIVATION_FIELDS:
        if not is_filled(field_value(document, name)):
            errors.append(f"{path}: missing non-empty '{name}' metadata")

    record = activation_record(document)
    if record is None:
        errors.append(f"{path}: missing '## Activation record' section")
        return errors

    for name in ACTIVATION_RECORD_FIELDS:
        if not is_filled(field_value(record, name)):
            errors.append(f"{path}: activation record has no '{name}' value")
    return errors


def resolve_comparison_base(base: str, head: str) -> str | None:
    """Return the revision to diff against, or None when there is no usable one.

    A push event supplies the all-zero sha for a branch's first push and after a
    force-push. Failing there would report a governance violation for what is an
    absent baseline, so fall back to the head's first parent and finally to no
    comparison at all.
    """
    merge_base = git("merge-base", base, head, allow_failure=True).strip()
    if merge_base:
        return merge_base
    first_parent = git("rev-parse", "--verify", f"{head}^", allow_failure=True).strip()
    return first_parent or None


def is_core_projection(path: str) -> bool:
    return path in CORE_PROJECTIONS or path.startswith("conformance/")


def activated_proposals(base: str, head: str, changed: set[str]) -> list[tuple[str, str]]:
    activated: list[tuple[str, str]] = []
    for path in sorted(changed):
        if not PROPOSAL_PATH.fullmatch(path):
            continue
        before = git("show", f"{base}:{path}", allow_failure=True)
        after = git("show", f"{head}:{path}", allow_failure=True)
        before_status = status_of(before)
        after_status = status_of(after)
        if after_status is not None and after_status.startswith("Accepted"):
            if before_status is None or not before_status.startswith("Accepted"):
                activated.append((path, after))
    return activated


def main(arguments: list[str]) -> int:
    if len(arguments) != 2:
        print("usage: validate_scp_activation.py <base-revision> <head-revision>", file=sys.stderr)
        return 2

    base, head = arguments
    comparison_base = resolve_comparison_base(base, head)
    if comparison_base is None:
        print(f"No usable comparison base for {base!r}; nothing to validate.")
        return 0
    changed = {
        line.strip()
        for line in git(
            "diff", "--name-only", "--diff-filter=ACMR", comparison_base, head
        ).splitlines()
        if line.strip()
    }
    activated = activated_proposals(comparison_base, head, changed)
    if not activated:
        print("No SCP status transition to Accepted.")
        return 0

    errors: list[str] = []
    if not any(is_core_projection(path) for path in changed):
        names = ", ".join(path for path, _ in activated)
        errors.append(
            f"{names}: activation diff must touch README.md, a grammar, "
            f"implementation/RUNTIME_CONTRACT.md, or conformance/"
        )

    for path, document in activated:
        errors.extend(validate_activation_document(path, document))

    if errors:
        print("Invalid SCP activation:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Validated SCP activation: " + ", ".join(path for path, _ in activated))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
