import unittest

from validate_scp_activation import (
    is_core_projection,
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


if __name__ == "__main__":
    unittest.main()
