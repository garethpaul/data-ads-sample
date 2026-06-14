---
title: Make Root Override Protection
type: reliability
status: in_progress
date: 2026-06-14
---

# Make Root Override Protection

## Status: In Progress

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

Pending implementation and validation.
