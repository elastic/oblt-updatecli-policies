# GitHub Actions workflow documentation

Repository workflow definitions are documented here:

| Workflow | Purpose |
| --- | --- |
| [Validate Policies](docs/validate.md) | Checks policy files and metadata; conditionally runs end-to-end diffs. |
| [e2e](docs/e2e.md) | Manually diffs and applies the composed Updatecli configuration. |
| [Publish Policies](docs/release.md) | Publishes policy bundles to GHCR. |
| [forked-pull-requests](docs/forked-pull-requests.md) | Posts reviewer instructions for fork pull requests. |
| [CI Failure Doctor](docs/ci-doctor.md) | Investigates failures from selected CI workflows. |

The repository contains GitHub Actions definitions and no checked-in Buildkite pipeline definitions. These pages describe the local workflow configuration; they do not verify remote workflow settings or current run status.
