.PHONY: build check lint test verify

lint:
	scripts/check-baseline.sh

test:
	scripts/check-baseline.sh
	@echo "No runtime tests are configured because this repository is documentation-only."

build:
	scripts/check-baseline.sh
	@echo "No build artifact is configured because this repository is documentation-only."

verify: lint test build

check: verify
