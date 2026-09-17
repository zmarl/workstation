---
name: project-maintenance
description: Periodic maintenance reports including dependency status, security audits, branch inventory, and project health checks. Use when running maintenance or checking project health.
---

# Project Maintenance

## Dependency Management

### Regular Checks

| Check | Frequency | Command |
|-------|-----------|---------|
| Outdated deps | Weekly | `npm outdated` |
| Security vulns | Per commit | `npm audit` |
| Unused deps | Monthly | `depcheck` |
| Licenses | On new dep | `license-checker` |

### npm outdated Report

```
Dependency updates available

Major (breaking):
- react: 17.0.2 → 18.2.0

Minor:
- axios: 1.4.0 → 1.5.0

Patch:
- typescript: 5.1.3 → 5.1.6

Options:
1. Patch only (safe)
2. Up to Minor
3. All (verify)
4. Skip
```

### npm audit Report

```
Security scan results

Found 3 vulnerabilities

Critical (1):
- lodash < 4.17.21 (Prototype Pollution)

High (2):
- axios < 0.21.1 (SSRF)
- node-fetch < 2.6.1 (Header Injection)

Report the finding and proposed version change. Do not update dependencies or
rewrite a lockfile unless the user explicitly requested that change.
```

## Branch Management

### Merged Branch Cleanup

List candidates read-only with `git branch --merged main`. Exclude protected
branches in the report, then delete only explicitly confirmed branch names.

Propose cleanup:
```
Merged branches found:
- feat/123-login
- fix/456-typo

Delete? (y/n)
```

### Stale Branch Warning

```
Branches not updated in 30+ days:
- feat/old-feature (45 days)
- wip/experiment (60 days)

Consider cleanup.
```

## Pre-Commit Checks

```
Pre-commit:
✓ lint (eslint --cache)
✓ format (prettier --check)
✓ type check (tsc --noEmit)
✓ test (vitest --changed)
✓ secrets check

All passed. Creating commit.
```

**On failure:**
```
Pre-commit:
✓ lint
✓ format
✗ type check - 2 errors
✓ test

Try auto-fix? (y/n)
```

## Large File Detection

| Size | Action |
|------|--------|
| < 1MB | Normal commit |
| 1-10MB | Warning |
| 10MB+ | Require confirmation |
| 100MB+ | Block (recommend LFS) |

```
Large files detected:

- assets/video.mp4 (150MB)
- data/dump.json (50MB)

Options:
1. Add to .gitignore
2. Use Git LFS
3. Commit anyway (not recommended)
```

## Auto-Fix Actions

| Issue | Auto-Fix |
|-------|----------|
| Formatting | `prettier --write` |
| Lint warnings | `eslint --fix` |
| Import order | Auto-sort |
| Unused imports | Auto-remove |

## Project Verification

Use the commands and local gate documented by the repository. Do not assume a
hosted CI service exists or is the quality authority.

**Local verification example:**
```
Running project checks locally:

1. lint: ✓
2. test: ✓
3. build: ✓
4. e2e: run or record a repository-approved skip reason

Required local checks passed. Push? (y/n)
```

**On a reported hosted-check failure:**
```
Hosted check failed

Job: test
Error: src/__tests__/api.test.ts - timeout

Possible causes:
1. Missing env vars
2. Flaky test
3. Timeout config

Reproduce locally? (y/n)
```

## Session Start Suggestions

```
Maintenance suggestions:

□ Dependency check (7 days since last)
□ Security scan (3 days since last)
□ Dead code check (30 days since last)

Run now?
1. All
2. Select
3. Skip
```

## Quick Commands

| Task | Command |
|------|---------|
| Full health check | `npm audit && npm outdated && npm run lint` |
| Report outdated deps | `npm outdated` |
| Report vulnerabilities | `npm audit` |
| List merged branches | `git branch --merged main` |
