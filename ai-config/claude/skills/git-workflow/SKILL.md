---
name: git-workflow
description: Git commit and PR workflow automation. Use when committing code, creating pull requests, or managing branches. Includes Conventional Commits format and PR templates.
---

# Git Workflow

## Commit Timing

**Auto-commit when:**
- Feature implementation complete
- Bug fix complete
- Tests added
- Refactor complete
- User says "commit"

**Do NOT commit when:**
- Work in progress
- Tests failing
- User says "don't commit yet"

## Commit Message Format

Use Conventional Commits (see `references/conventional-commits.md`):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Example:**
```
feat(auth): add password reset functionality

- Add reset password form component
- Add email sending service
- Add password reset API endpoint

Closes #123
```

## Commit Granularity

| Unit | Example |
|------|---------|
| 1 feature = 1 commit | Login feature |
| 1 bug = 1 commit | Null check fix |
| Related changes together | Feature + its tests |

**Split when:**
- Large feature → logical units
- Refactor + feature → separate commits
- Dependency updates → separate commit

## Branch Naming

```
<type>/<issue-number>-<short-description>
```

| Type | Example |
|------|---------|
| `feat/` | `feat/123-add-login` |
| `fix/` | `fix/456-null-pointer` |
| `refactor/` | `refactor/789-extract-service` |
| `docs/` | `docs/update-readme` |
| `chore/` | `chore/update-deps` |

## PR Template

```markdown
## Summary
[1-3 sentence overview]

## Changes
- [Change 1]
- [Change 2]
- [Change 3]

## Test Plan
- [ ] [Test item 1]
- [ ] [Test item 2]

## Screenshots (if applicable)
[Screenshots]

## Related Issues
Closes #[issue]
```

## Pre-Commit Checks

| Check | On Failure |
|-------|------------|
| Lint | Diagnose, then make only scoped fixes |
| Format | Run the repository formatter on explicit paths |
| Type check | Fix errors |
| Tests | Fix errors |

## Forbidden

**Commits:**
- WIP commits (incomplete state)
- "fix" only messages (no info)
- Huge commits (hard to review)
- `.env` files (security)

**PRs:**
- Direct push to main
- Merge without review
- Merge without the verification required by the repository

Do not assume hosted CI is the quality authority. Follow the repository's
documented local gate and treat hosted checks as supplemental unless its policy
explicitly says otherwise.

## Co-Author

Add to Claude-created commits:
```
Co-Authored-By: Claude <noreply@anthropic.com>
```

## Workflow

```
Implementation complete
    ↓
Run tests (verify pass)
    ↓
Run lint/format
    ↓
git add <explicit changed paths>
    ↓
git commit (Conventional Commits)
    ↓
"Create PR?" confirmation
    ↓
Yes → git push + gh pr create
No → Done
```

## Emergency Hotfix

```
User: "Emergency hotfix needed"
    ↓
Confirm: "Push directly to production?"
    ↓
Yes → hotfix branch → immediate PR → merge
```

## WIP Save

```
User: "Save work in progress"
    ↓
Keep the current worktree intact, or commit to a dedicated WIP branch only when requested
    ↓
Do NOT merge to main/develop
```
