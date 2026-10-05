# Changelog

## 0.5.1

* Fix GitHub SCM checkout to disable submodule fetches with `scm.submodules: false` to avoid SSH auth failures when Updatecli fetches submodules by default.

## 0.5.0

* Add `scm.singleBranch` configuration for checkout behavior.

## 0.4.1

* Quote the pull request labels so a label starting with a YAML indicator, such as `>non-issue`, no longer breaks the generated manifest.

## 0.4.0

* Use oblt-cli GitHub repository
* Support `force` input - Updatecli won't recreate the working branches that diverged from their base branch.

## 0.3.0

* chore: add changelog URL in the policy

## 0.2.0

* Breaking change: `scm.commitusingapi` is the way to sign commits automatically. Replace `signedcommit`.

## 0.1.0

- Initial release
