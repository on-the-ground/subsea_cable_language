import subprocess
import unittest

from validate_scp_activation import (
    PROPOSAL_PATH,
    is_core_projection,
    resolve_comparison_base,
    status_of,
    validate_activation_document,
)


VALID_DOCUMENT = """\
# SCP-0012 — Example

- Status: Accepted
- Activation pull request: PR #12
- Effective language revision: the commit on `main` produced by squash-merging PR #12

## Activation record

- Canonical documents synchronized: README.md
- Grammar projections synchronized: not applicable; no syntax change
- Diagnostics and examples synchronized: examples.md
- Conformance cases synchronized: conformance/cases.tsv
- Compatibility and migration notes synchronized: compatibility section
- Verification commands and results: validate passed

## Final rationale

Done.
"""


class ActivationValidatorTests(unittest.TestCase):
    def test_numbered_and_draft_proposal_paths_are_validated(self) -> None:
        self.assertIsNotNone(PROPOSAL_PATH.fullmatch("proposals/0014-example.md"))
        self.assertIsNotNone(PROPOSAL_PATH.fullmatch("proposals/draft-example.md"))
        self.assertIsNone(PROPOSAL_PATH.fullmatch("proposals/README.md"))

    def test_complete_activation_document_is_valid(self) -> None:
        self.assertEqual(
            validate_activation_document("proposals/0012-example.md", VALID_DOCUMENT),
            [],
        )

    def test_missing_activation_record_value_is_rejected(self) -> None:
        document = VALID_DOCUMENT.replace(
            "- Conformance cases synchronized: conformance/cases.tsv",
            "- Conformance cases synchronized:",
        )
        errors = validate_activation_document("proposals/0012-example.md", document)
        self.assertTrue(any("Conformance cases synchronized" in error for error in errors))

    def test_qualified_accepted_status_is_rejected(self) -> None:
        document = VALID_DOCUMENT.replace(
            "- Status: Accepted", "- Status: Accepted — details pending"
        )
        self.assertEqual(status_of(document), "Accepted — details pending")
        errors = validate_activation_document("proposals/0012-example.md", document)
        self.assertTrue(any("exactly 'Accepted'" in error for error in errors))

    def test_core_projection_paths(self) -> None:
        self.assertTrue(is_core_projection("README.md"))
        self.assertTrue(is_core_projection("SubseaCable.g4"))
        self.assertTrue(is_core_projection("conformance/cases.tsv"))
        self.assertFalse(is_core_projection("METAPHORS.md"))

    def test_runtime_contract_is_a_normative_projection(self) -> None:
        # A decision that only changes the Runtime contract is correctly
        # activated by touching it alone.
        self.assertTrue(is_core_projection("implementation/RUNTIME_CONTRACT.md"))

    def test_non_normative_implementation_plans_are_not_projections(self) -> None:
        self.assertFalse(is_core_projection("implementation/CAROUSEL_ENGINE_PLAN.md"))
        self.assertFalse(is_core_projection("implementation/README.md"))

    def test_absent_baseline_yields_no_comparison_base(self) -> None:
        # A push event supplies the all-zero sha on a branch's first push and
        # after a force-push; that is an absent baseline, not a violation.
        zero = "0" * 40
        self.assertIsNotNone(resolve_comparison_base("HEAD~1", "HEAD"))
        self.assertEqual(resolve_comparison_base(zero, "HEAD"), _first_parent())

    def test_absent_baseline_on_a_root_commit_is_tolerated(self) -> None:
        root = _root_commit()
        self.assertIsNone(resolve_comparison_base("0" * 40, root))


def _first_parent() -> str:
    return subprocess.run(
        ("git", "rev-parse", "--verify", "HEAD^"),
        check=True, text=True, stdout=subprocess.PIPE,
    ).stdout.strip()


def _root_commit() -> str:
    return subprocess.run(
        ("git", "rev-list", "--max-parents=0", "HEAD"),
        check=True, text=True, stdout=subprocess.PIPE,
    ).stdout.split()[0]


if __name__ == "__main__":
    unittest.main()
