---
applyTo: ".github/workflows/**"
---

## GitHub Actions review

- Changes to `validate.yaml` must preserve policy validation and the conditions gating credential-bearing end-to-end tests. Those tests run on `main`, manual opt-in, or same-repository pull requests; they are intentionally skipped for fork pull requests because they use repository credentials.
- Changes to `release.yaml` must preserve the intended `main`/manual triggers and package-publishing permissions. An unintended trigger can publish policy bundles to GHCR.
- Changes to `e2e.yml` must account for its write permissions and `compose apply` behavior. Verify the target repository, branch, and credential scope so a workflow dispatch cannot update unintended repositories.
