# Native Runtime Source Guard Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use executing-plans to implement this plan task-by-task.

**Goal:** Keep C, C++, and Objective-C implementation files out of the documentation-only repository until a complete runtime transition is added.

**Architecture:** Extend the existing exact staged-index extension classifier rather than adding a second scanner. Reuse the filename-redacted runtime-source regression helper for native source and header suffixes, preserving invalid-byte handling, executable allowlists, content scans, and fail-closed Git behavior.

**Tech Stack:** POSIX shell, Perl staged-index classifier, Git index fixtures, GNU Make.

---

## Status: Completed

### Task 1: Add failing native-source regressions

**Files:**
- Modify: `tests/check-baseline.sh`

1. Add a focused helper covering `.c`, `.cc`, `.cpp`, `.cxx`, `.h`, `.hh`, `.hpp`, `.hxx`, `.m`, and `.mm`.
2. Reuse the existing runtime-source fixture and redacted diagnostic assertions.
3. Run `tests/check-baseline.sh` and confirm the first native fixture is accepted before implementation.

### Task 2: Extend the staged-index classifier

**Files:**
- Modify: `scripts/check-baseline.sh`

1. Add only the ten native source and header suffixes to the existing runtime regex.
2. Add durable source, test, documentation, and plan contracts.
3. Run the focused regression suite and confirm all native fixtures are rejected.

### Task 3: Record and verify the boundary

**Files:**
- Modify: `README.md`
- Modify: `SECURITY.md`
- Modify: `VISION.md`
- Modify: `CHANGES.md`
- Modify: `docs/plans/2026-06-26-native-runtime-source-guard.md`

1. Document the native runtime boundary without claiming executable runtime coverage.
2. Run repository and external-directory `make check`.
3. Run shell syntax checks, `git diff --check`, and isolated extension-removal mutations.
4. Mark the plan completed with exact local and hosted verification evidence.

## Verification

- The focused regression suite failed first because `sample/client.c` was accepted.
- `scripts/check-baseline.sh`
- `tests/check-baseline.sh`
- Repository `make check`
- External-directory `make check`
- `/bin/sh -n scripts/*.sh tests/*.sh`
- `git diff --check`
- Ten native source and header fixtures were rejected with filename-only diagnostics.
- Isolated `.c`, `.hpp`, and `.mm` classifier removals failed on the intended fixture filenames.
- No application runtime, build artifact, or external service is configured in this documentation-only repository.
