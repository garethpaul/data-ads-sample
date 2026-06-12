.PHONY: build check lint test verify

ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

lint:
	$(ROOT)scripts/check-baseline.sh

test:
	$(ROOT)tests/check-baseline.sh
	@echo "No application runtime tests are configured because this repository is documentation-only."

build:
	$(ROOT)scripts/check-baseline.sh
	@echo "No build artifact is configured because this repository is documentation-only."

verify: lint test build

check: verify
