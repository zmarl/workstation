# Conventional Commits Reference

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

## Types

| Type | Use For |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting (no code change) |
| `refactor` | Code restructure (no behavior change) |
| `test` | Add/fix tests |
| `chore` | Build, config, tooling |
| `perf` | Performance improvement |

## Subject Rules

- Imperative mood ("add" not "added")
- No period at end
- Max 50 characters
- Lowercase

## Body Rules

- Wrap at 72 characters
- Explain what and why, not how
- Use bullet points for multiple changes

## Footer

- `Closes #123` - Link issues
- `BREAKING CHANGE:` - Breaking changes
- `Co-Authored-By:` - Co-authors

## Examples

**Feature:**
```
feat(auth): add OAuth2 login support

- Add Google OAuth provider
- Add Facebook OAuth provider
- Update user model for OAuth tokens

Closes #45
```

**Bug Fix:**
```
fix(api): handle null response from external service

The payment API can return null when service is degraded.
Added null check and fallback behavior.

Closes #89
```

**Breaking Change:**
```
feat(api): change response format for user endpoint

BREAKING CHANGE: The /api/users endpoint now returns
an object with `data` wrapper instead of raw array.

Migration: Update clients to access response.data
```

**Refactor:**
```
refactor(utils): extract validation logic to separate module

No functional changes. Improves testability and reusability.
```
