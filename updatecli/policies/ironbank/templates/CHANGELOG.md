# Changelog

## 0.3.0

* chore: add changelog URL in the policy

## 0.2.0

- Support manifest entries that cannot be parsed with the yaml kind
- Breaking change: `scm.commitusingapi` is the way to sign commits automatically. Replace `signedcommit`.
- Fix the `beats_packages` that didn't quote the UBI version correctly.
- Skip updating Dockerimage if `skip_dockerfile: true`. Default 'skip_dockerfile: false'.
- Skip updating Manifest if `skip_manifest: true`. Default 'skip_manifest: false'.

## 0.1.0

- Packages are unrelated to the paths data structure, let's be explict it's about beats/elastic-agent

## 0.0.3

- Support packages.yml for Elastic Agent and Beats

## 0.0.2

- Fix quotes

## 0.0.1

- Initial release
