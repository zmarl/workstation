---
name: performance-optimization
description: Optimization strategies for large codebases (1000+ files). Covers incremental builds, parallel execution, caching, and memory management. Auto-activated for large projects.
user-invocable: false
---

# Performance Optimization

Auto-loaded for large projects.

## Project Scale

| Size | Files | Strategy |
|------|-------|----------|
| Small | < 100 | Standard |
| Medium | 100-1000 | Use caching |
| Large | 1000+ | Incremental, parallel |

## Incremental Builds

| Tool | Option |
|------|--------|
| TypeScript | `--incremental`, `--tsBuildInfoFile` |
| ESLint | `--cache` |
| Prettier | `--cache` |
| Jest | `--changedSince` |
| Vitest | Default incremental |

**TypeScript:**
```bash
# Small
tsc --noEmit

# Large
tsc --noEmit --incremental

# Specific file
tsc --noEmit src/changed.ts
```

## Test Optimization

**Run affected only:**
```bash
npm test -- --changedSince=main
npm test -- src/utils.test.ts
npm test -- --testPathPattern="auth"
```

**Parallel:**
```bash
jest --maxWorkers=4
vitest  # Parallel by default
```

**Order:**
1. Failed tests first
2. Changed-related tests
3. Remaining tests

## Search Optimization

**Always exclude:**
```
node_modules/
.git/
dist/
build/
coverage/
.next/
.cache/
```

**Prefer ripgrep:**
```bash
rg "pattern" --type ts
fd "*.ts" --exclude node_modules
```

## Git Optimization

**Large repos:**
```bash
git clone --depth 1 [repo]           # Shallow
git clone --filter=blob:none [repo]  # Partial
git sparse-checkout set src/         # Sparse
```

**Fast operations:**
```bash
git diff -- src/        # Specific path
git log -n 10           # Recent only
git diff --name-only    # Files only
```

## Memory Management

**Node.js:**
```bash
node --max-old-space-size=4096 script.js
NODE_OPTIONS="--max-old-space-size=4096" tsc
```

**File size handling:**
| Size | Approach |
|------|----------|
| < 1MB | Normal |
| 1-10MB | Consider streaming |
| 10MB+ | Require streaming/chunking |

## Parallel Execution

```bash
# npm-run-all
npm-run-all --parallel lint test build

# concurrently
concurrently "npm run lint" "npm run test"
```

**Claude parallel calls:**
- Run Glob + Grep in parallel
- Read multiple files in parallel
- Independent Bash commands in parallel

## Caching

| Tool | Cache Location |
|------|----------------|
| npm | `node_modules/.cache` |
| ESLint | `.eslintcache` |
| Prettier | `node_modules/.cache/prettier` |
| TypeScript | `tsconfig.tsbuildinfo` |
| Jest | `node_modules/.cache/jest` |

**CI caching (GitHub Actions):**
```yaml
- uses: actions/cache@v3
  with:
    path: |
      node_modules
      .eslintcache
    key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
```

## Long Task Handling

**Progress:**
```
Processing... (100/500 files)
Processing... (200/500 files)
```

**Timeouts:**
| Task | Default | Solution |
|------|---------|----------|
| Bash | 120s | Split task |
| Tests | Config | Check timeout setting |
| Build | None | Monitor progress |

**Checkpoint support:**
```
Step 1/5: Deps ✓
Step 2/5: Lint ✓
Step 3/5: Test ← Current
Step 4/5: Build
Step 5/5: Artifacts

Interrupt? (y/n)
Resume from Step 3.
```

## Recommended Scripts

```json
{
  "scripts": {
    "lint": "eslint . --cache",
    "lint:fix": "eslint . --cache --fix",
    "format": "prettier --write --cache .",
    "test": "vitest run",
    "test:changed": "vitest run --changed",
    "typecheck": "tsc --noEmit --incremental"
  }
}
```

**.gitignore additions:**
```
.eslintcache
*.tsbuildinfo
.cache/
```
