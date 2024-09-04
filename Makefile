POLICY ?=

.PHONY: release
release: ## Release checks for each policy if they can be published on ghcr.io
	.ci/scripts/release.bash --publish

.PHONY: test
test: ## Release checks for each policy if they can be published on ghcr.io
	.ci/scripts/release.bash

.PHONY: e2e-test
e2e-test: ## Release checks for each policy if they can be published on ghcr.io
	.ci/scripts/release.bash --e2e-test

.PHONY: e2e-test
validate-policy: ## Release checks for each policy if they can be published on ghcr.io
	.ci/scripts/release.bash --validate-policy $(POLICY)

.PHONY: help
help: ## Show this Makefile's help
    @grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

