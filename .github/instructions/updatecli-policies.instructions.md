---
applyTo: "updatecli/policies/**"
---

## Updatecli policy review

- When changing a policy template's source selection or target matching under `updatecli/policies/**`, verify that the upstream release and consumer path are the intended ones. A wrong source or target can write an incorrect tool or image version into consumer repositories.
- When changing policy values or template references, preserve the documented runtime override contract: caller-supplied values override bundle defaults. If an input key stops being consumed, a consumer's target repository, branch, or file setting can be silently ignored, sending updates to the wrong place or preventing consumers from configuring the policy.
- When changing policy implementation, bump its semantic version and add a top `CHANGELOG.md` entry as required by `CONTRIBUTING.md`. The release workflow publishes bundles to GHCR; without a version bump, consumers pinned to the previous OCI policy version cannot receive the changed behavior.
