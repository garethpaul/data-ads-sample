---
title: Make Root Override Protection
type: reliability
status: completed
date: 2026-06-14
---

# Make Root Override Protection

## Status: Completed

## Problem Frame

The Makefile derives its root from `MAKEFILE_LIST`, but a command-line `ROOT`
assignment can redirect both readiness scanners outside the checkout.

## Scope Boundaries

- Protect the repository-derived Make root without changing gate names or
  scanner behavior.
- Preserve the documentation-only, no-runtime, no-fixture, no-credential, and
  tracked-file shape boundaries.
- Do not add dependencies, application code, private data, or generated output.

## Requirements

- R1. A hostile `ROOT` value must not redirect either readiness scanner.
- R2. Repository and external-working-directory verification must pass.
- R3. The source checker must enforce the protected root assignment.
- R4. Completed plan evidence and isolated mutations must be required.

## Verification

- `sh -n scripts/check-baseline.sh` and `sh -n tests/check-baseline.sh` passed.
- `tests/check-baseline.sh` passed the isolated readiness scanner regression
  suite.
- All four Make gates passed through `make lint`, `make test`, `make build`,
  and `make check`.
- `make ROOT=/tmp check` passed and still executed both repository scanners.
- The full gate passed from `/tmp` through the absolute Makefile path, covering
  the external working directory.
- Four isolated hostile mutations were rejected: overrideable root, missing
  plan, reopened plan, and missing verification evidence.
- `git diff --check`, intended-path review, artifact inspection, and the
  changed-line secret scan passed.
- No runtime manifest, implementation, dependency, credential, private data,
  fixture, symlink, gitlink, or generated artifact was added.
