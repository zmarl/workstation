---
name: windows-development
description: Windows-specific development guidance. Covers path handling, line endings, shell differences, and file locking issues. Auto-activated on Windows platform.
user-invocable: false
---

# Windows Development

Auto-loaded context for Windows environments.

## Path Handling

**Use path module, not hardcoded separators:**

```typescript
// Bad
const p = 'src\\components\\Button.tsx';

// Good
import path from 'path';
const p = path.join('src', 'components', 'Button.tsx');
```

**Path length limit:** 260 chars (traditional), keep paths short.

## Line Endings

| Code | Environment |
|------|-------------|
| LF (`\n`) | Unix, Mac, Git |
| CRLF (`\r\n`) | Windows |

**Git config:**
```bash
git config --global core.autocrlf true
```

**.gitattributes:**
```
* text=auto eol=lf
*.bat text eol=crlf
*.cmd text eol=crlf
*.ps1 text eol=crlf
```

## Shell Commands

| Unix | PowerShell |
|------|------------|
| `ls` | `Get-ChildItem` |
| `cat` | `Get-Content` |
| `rm` | `Remove-Item` |
| `cp` | `Copy-Item` |
| `mv` | `Move-Item` |
| `export VAR=val` | `$env:VAR = "val"` |

**Cross-platform npm scripts:**
```json
{
  "scripts": {
    "clean": "rimraf dist",
    "env": "cross-env NODE_ENV=production node index.js"
  }
}
```

Recommended packages: `rimraf`, `cross-env`, `shx`

## File Locking

Windows locks files when open. Errors:
- `EPERM: operation not permitted`
- `EBUSY: resource busy or locked`

**Solutions:**
1. Check if editor has file open
2. Wait and retry
3. Close blocking process

## Environment Variables

```powershell
# Session only
$env:API_KEY = "xxx"

# Permanent (user)
[Environment]::SetEnvironmentVariable("API_KEY", "xxx", "User")
```

Use `dotenv` for cross-platform.

## Character Encoding

Windows console defaults to Shift-JIS. Set UTF-8:

```powershell
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# or
chcp 65001
```

## Recommended Config

**.editorconfig:**
```ini
[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2

[*.{bat,cmd,ps1}]
end_of_line = crlf
```

**package.json:**
```json
{
  "scripts": {
    "clean": "rimraf dist coverage",
    "test": "cross-env NODE_ENV=test vitest"
  }
}
```
