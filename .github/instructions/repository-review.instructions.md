---
applyTo: "**"
---

## Repository context and deterministic checks

- Policies are declarative YAML bundles; the Updatecli version is pinned in `.tool-versions`.
- CI (`make test` in `.github/workflows/validate.yaml`) checks required policy files, metadata URLs, and that `Policy.yaml` matches the latest changelog version; `make e2e-test` runs Updatecli diffs with test values. Do not repeat these checks or their output.
- Dependabot updates GitHub Actions dependencies; do not comment on routine version updates.
