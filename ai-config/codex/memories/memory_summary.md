v1

## User Profile

The user develops `D:\Dev\Investment`, a Japanese discretionary investment decision-support system spanning Desktop, FastAPI BFF, PostgreSQL, ingestion, local Qwen, documents, and a quality harness. They retain investment judgment and want source-grounded causal reasoning, refutation, uncertainty, asymmetric upside/downside, and survivability rather than predicted win probabilities. They work in parallel worktrees and distinguish documentation authority, code implementation, Ready, merge/main, build, and live operation as separate evidence states. They also maintain Windows-local AI tooling and want its storage and Codex configuration discoverable, documented, and genuinely verified.

## User preferences

- For “今どういう状況？”, “これから何すべき？”, or “適用した？”, give conclusion, checked facts, unknowns, and next order; distinguish candidate, merged, main-synced, and first operational success.
- Preserve peer ownership: first inspect read-only; do not stop, delete, clean up, overwrite, or take over another worktree, lock, queue job, port, or process without proven ownership.
- Within approved scope, act autonomously; ask when meaning, investment logic, compatibility, data handling, destructive operation, or external impact changes.
- Treat exact-head proof as perishable: `pending_async`, tests/Ready, Scheduler registration, a successful run, or liveness is not by itself merge/main/operational success.
- For data work, prioritize “正しく取得する”“網羅性を高める基盤”: distinguish official latest, fetched, stored, typed, displayed, revised, and next-publication states; never present pending/unverified as current.
- Qwen analyzes a prior deterministic snapshot; it never chooses numbers, arithmetic, units, periods, or missing-value completion. Preserve unknowns and failed generation separately from screen/build success.
- When consolidating results, verify saved logs, state unmet/unknown items, and end with a reading-order document list—not a conclusion alone.
- For approved storage migration, retain in-use models, duplicates, and compatibility links until verified; centralize both physical files and AI-readable catalogue/instructions. Chat testing is secondary to usable organization.
- Investment-framework documentation is “私の投資法を言語化したもの”: carry adopted decisions forward, keep unresolved proposals/history separate, and do not use p*/win probability for gates, ranking, or sizing.
- Keep conditional valuation and operating-profit scenarios separate from forecasts and stock-price probabilities; preserve disclosure, deterministic, qualitative, external-hypothesis, and unresolved evidence states. [ad-hoc note]

## General Tips

- Start Investment work with `AGENTS.md`, `docs/OWNER_INTENT.md`, `docs/README.md`, current ODR/backlog, and fresh git/runtime evidence.
- Windows: prefer short direct commands, `cmd.exe`, `uv run`, and direct paths over complex PowerShell quoting or encoded wrappers.
- During ODR-0038’s 2026-09-08–10-07 harness freeze, do not add queue/hook/ledger/contract-test/role/runbook/ODR machinery; only short red-to-green fixes, removal, demotion, or notification are allowed.
- For shared queue/audit issues, inspect job owner, claim, phase, terminal event, and resource reason before retrying. Reopen only exact saved failures; use read-only DB diagnosis and never copy credentials.
- For local Desktop delivery, separately prove current taskbar app/build, requested behavior, BFF/SSE, and Qwen/restart state. A staged build or candidate API does not prove ordinary delivery. [ad-hoc note]
- Treat local-model format, storage, and runtime compatibility separately; consult `D:\Models\STATUS.md` and validate visible library/runtime behavior after a settings change.

## What's in Memory

### D:\Dev\Investment

#### 2026-09-13

- J-Quants/EDINET recovery, latest scope, and blank actuals: `PR #368`, `PR #443`, `PR #444`, `dtype={"Code": str}`, `completion-scope latest`, `reflection.drain`, `272A`, `6225`
  - desc: Search first for acquisition-recovery handoff, leading-zero CSV codes, EDINET runner exit 65, saved-capture replay, shared DB repair, or completeness claims.
  - learnings: PR #368 remains unmerged/stale; PR #443 aligned latest-scope JSON and runner success; PR #444 recovered only 9/8–9/9. None proves full history, UI/API, Scheduler registration, or one-hour disclosure reflection.

#### 2026-09-12

- Ponytail global Codex code-work setup: `ponytail@ponytail`, `defaultMode: full`, `hooks/list`, `SessionStart`, `codex-cli 0.153.4`, `PR #440`
  - desc: Global Windows Codex plugin installation, trusted hooks, scope limits, model compatibility, and worklog metadata rules.
  - learnings: Plugin 4.9.0 is enabled/trusted for code work; mode is shared across tasks, and installation must be followed by actual new/continuation response checks.
- NAS backup policy and harness/product return: `NAS`, `non-device UNC`, `ODR-0038`, `harness_status --summary`, `finish-pr`, `ODR-0039`
  - desc: NAS-only backup enforcement plus exact-head lifecycle, freeze, and product-return boundary.
  - learnings: Recheck historical Ready/main evidence; proposed ODR-0039 is not implementation authority.

#### 2026-09-11

- RTX PRO 5000/Qwen evidence audit and document index: `measured-comparison-14`, `704 records`, `5 requests`, `Qwen27`, `Qwen80`, `8081`, `8010`, `documentation-audit-20260911`
  - desc: Read-only reconciliation of Qwen timing/quality logs and the generated reading-order documentation index.
  - learnings: Do not combine unlike measurement units or infer the unavailable Q8 server’s stop cause; Qwen27 speed change is not MTP/quality proof and Qwen80 was not viable in its tested eager run.

### D:\Models

#### 2026-09-12

- Windows local LLM model library: `D:\Models`, `model_library.py`, `models.json`, `STATUS.md`, `LM Studio`, `Unsloth`, `/mnt/d/Models`
  - desc: Centralized storage, legacy links, catalogue, supported library paths, Windows/WSL caches, and honest per-model verification.
  - learnings: 13 tests/link checks passed, but six catalog findings and untested restart/WSL/Ollama/vLLM paths mean the inventory is not a fully validated runtime catalogue.

### Older Memory Topics

#### D:\Dev\Investment

- Qwen initial analysis and deterministic compiler: `FinancialPerformanceSnapshot`, `Decimal`, `Ebara`, `Qwen3.8-27B-Q8_0`, `PR #434`
  - desc: Deterministic snapshot through BFF/UI, normal runtime cutover, and unresolved full-analysis quality; cwd=D:\Dev\Investment.
- Architecture, refactor, and documentation authority: `FinancialPerformanceCompiler`, `FOR UPDATE SKIP LOCKED`, `Temporal`, `docs/README.md`, `documentation-standard.md`, `Stage 0`
  - desc: Current-stack assessment, refactor-plan boundaries, documentation checks, and decision-history routing; cwd=D:\Dev\Investment.
- Desktop delivery and decision UI: `taskbar`, `visible BUILD`, `BFF-only`, `Macro.tsx`, `CompanySnapshot.tsx`
  - desc: Ordinary local-app proof, dashboard/macro/company UI, statistics, and Qwen graceful updates; cwd=D:\Dev\Investment.
- Ingestion, source freshness, and options: `get_bulk`, `edinet-facts-refresh`, `source_submit_date_mismatch`, `POSTGRES_DSN is empty`, `participant-open-interest`, `NK225OP`
  - desc: First-party recovery, fail-closed collectors, freshness boundaries, and JPX options interpretation; cwd=D:\Dev\Investment and D:\Dev\Investment-data-acquisition-recovery.
- Harness governance and parallel auditing: `Ready gate`, `proof pack`, `resource class`, `WindowsCapabilityBusyError`, `pending_async`
  - desc: Queue admission, exact-head evidence, audit stop isolation, and historical harness reforms; cwd=D:\Dev\Investment.
- Investment methodology and earnings-policy reset: `投資フレームワーク`, `Q1-Q127`, `pstar`, `DecisionCase`, `feat-ratio`
  - desc: Owner-adopted methodology, conditional valuation, and policy against restoring the manual earnings loop; cwd=D:\Dev\Investment.

#### Codex Windows environment

- Personal plugin management: `mattpocock-skills`, `Ponytail`, `codex-plugin`, `marketplace.json`, `validate_plugin.py`
  - desc: Historical personal plugin and current global Ponytail setup; recheck enabled version, trust, and runtime compatibility before action.
