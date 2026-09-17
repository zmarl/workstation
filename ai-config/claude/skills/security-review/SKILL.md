---
name: security-review
description: Security analysis and hardening guidance. Use when reviewing code for vulnerabilities, handling authentication, working with sensitive data, or auditing dependencies.
---

# Security Review

## Protected Files - NEVER Read/Write

| Pattern | Reason |
|---------|--------|
| `.env`, `.env.*` | API keys, secrets |
| `secrets/**` | Secrets directory |
| `**/credentials*` | Auth credentials |
| `**/*.pem`, `**/*.key` | Private keys |
| `**/id_rsa*`, `**/*_ed25519` | SSH keys |
| `**/.netrc`, `**/.npmrc` | Auth tokens |

**Exceptions:** `.env.example` (template), `*.pub` (public keys)

## Code Security - NEVER Do

| Action | Risk |
|--------|------|
| Hardcode passwords/API keys | Leak exposure |
| Use `eval()` | Code injection |
| Execute unvalidated input | Command injection |
| Concatenate SQL strings | SQL injection |

## Vulnerability Detection

When found, report immediately:

```
Security issue detected

Issue:
- Type: [Hardcoded credential]
- Location: [file:line]
- Content: [masked]

Recommended:
- Move to environment variable
- Use secret management service
```

## Input Validation

**User input:**
```typescript
// Bad - command injection
exec(`echo ${userInput}`);

// Good - safe
execFile('echo', [userInput]);
```

**SQL:**
```typescript
// Bad - SQL injection
const query = `SELECT * FROM users WHERE id = ${userId}`;

// Good - parameterized
const query = 'SELECT * FROM users WHERE id = ?';
db.query(query, [userId]);
```

**HTML/React:**
```typescript
// Bad - XSS
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// Good - auto-escaped
<div>{userContent}</div>

// If HTML needed - sanitize
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
```

## Git Security

**Pre-commit checks:**
- `.env` staged → Block, warn
- Private key patterns → Block
- Large binaries → Confirm
- Credential patterns → Warn

See `references/vulnerability-patterns.md` for detection regex.

## Dependency Security

**Check regularly:**
```bash
npm audit          # Vulnerabilities
npm outdated       # Updates available
```

**On vulnerability found:**
```
Security vulnerability found

Package: [name]@[version]
Severity: [critical/high/moderate/low]
CVE: [number]

Action:
1. Run `npm audit fix`
2. Manual update if needed
```

## Forbidden Commands

| Command | Risk |
|---------|------|
| `rm -rf *` | Mass deletion |
| `git push --force` | History destruction |
| `chmod 777` | Excessive permissions |
| `curl \| sh` | Untrusted execution |

## Auth Best Practices

**Sessions:**
- HttpOnly cookies (XSS protection)
- Secure flag (HTTPS only)
- SameSite attribute (CSRF protection)
- Short expiration

**JWT:**
- Short expiration
- Refresh tokens for UX
- Always verify signature
- Minimal claims

## Security Report Format

```
Security Check Results

[OK] Sensitive files: No issues
[OK] Hardcoded credentials: None found
[WARN] Dependencies: 2 vulnerabilities (moderate)
  - lodash@4.17.20 → 4.17.21
  - axios@0.21.0 → 0.21.1

Recommended: Run `npm audit fix`
```

## On Security Issue

1. **Stop** - Halt dangerous operation
2. **Report** - Inform user clearly
3. **Suggest** - Provide safe alternative
4. **Log** - Record (mask sensitive data)
