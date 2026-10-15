# oblt-updatecli-policies

This repository publishes reusable Updatecli policy bundles to GHCR.

## Review guidance

Keep this file and each `.github/instructions/*.instructions.md` file under 4,000 characters. Shared review policy is split across `review-policy-core.instructions.md`, `review-policy-security.instructions.md`, and `review-policy-tests.instructions.md`; these apply to all paths. Follow them for pull-request reviews, plus the applicable repository or path-specific guidance:

- `repository-review.instructions.md` for toolchain and CI context.
- `updatecli-policies.instructions.md` for policy changes.
- `github-actions.instructions.md` for workflow changes.

Keep detailed review rules in the narrowest applicable instruction file and update it when the corresponding repository behavior changes.
