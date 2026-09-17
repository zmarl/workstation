---
name: project-weekly-audit-repair-2026-08-24
description: "週次監査が一度も完走できなかった原因 11 件の修理（08-24, 私の commit 73ee12c6e は Codex の PR #215 経由で main 着地）。合格した監査だけが失敗する summary 上限の非対称と、同型の未修理 2 件"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3f6c93bb-2607-440c-9e37-cb6a33159fc7
  modified: 2026-08-25T11:40:58.721Z
---

ODR-0017 の週次監査（`scripts/dev/weekly_*.py` + proof pack queue）は導入以来 **一度も完走していなかった**。
2026-08-24 に 7 回の実走で原因を 1 つずつ剥がし、**7 回目で全 17 レーン passed**（所要 3,933 秒）に到達。
関連: [[project-harness-redesign-phase0-2026-08-23]]

## 最重要の教訓: 「通ったときだけ確実に失敗する」非対称

summary.json は **書き手が無制限**（実質 4.9 GB まで許容: `MAX_NODEIDS` 100,000 × `MAX_NODEID_LENGTH` 16,384 × 3 リスト）なのに、
**読み手 7 箇所すべてが 4 MiB** だった。全レーンが通ると plan に全 nodeid（41,042 件・22.5 MB）が入るため必ず読み戻せず、
`QueueFilesystemError` → 訂正 summary（`evidence:EvidenceContractError` / `stop_scope: global`）が記録される。
**レーンが途中で落ちれば plan が短く 4 MiB に収まるので、失敗する監査だけが記録できていた。**
→ 修正は Codex 側 `a910bb3b9` が着地（`MAX_SUMMARY_BYTES = 32 MiB` を書き手・読み手 7 箇所で共有）。

**同型の非対称が main にまだ 2 件残っている**（2026-08-24 時点、未修理・オーナー未提示）:

1. attempt log: 生産者 `weekly_audit_execution.py` の capture が 64 MiB 許容 → 消費者 `weekly_audit_logs.py` の
   `MAX_ATTEMPT_LOG_BYTES` が 16 MiB。超過は素の `ValueError` → `evidence:EvidenceContractError` に化け、
   サイズ事故と区別できない。現在値は collect-all が約 7.1 MB（上限の 43%）。
2. DB レーンログ: `run_local_pytest.py` は無制限に書き、`weekly_audit_execution.py` の `MAX_DB_LOG_BYTES` は 16 MiB。
   超過は `except (OSError, UnicodeError, ValueError)`（:316）で「DB 3 レーン全失敗」に畳まれる。
   **この保守的な帰属自体は意図的**（`test_db_failure_conservatively_attributes_missing_weekly_lanes` が存在）だが、
   サイズ超過と実際の失敗が区別できず痕跡も残らないため、**通っている DB レーンが domain stop になっても原因が追えない**。

さらに `weekly_test_audit.py` の evidence 失敗経路は `test_started=False` 固定で、
全レーン実行済みの run を「1 件も走っていない」と誤記録する。

## 修理した 11 件（私の commit 73ee12c6e）

機構: bare `npm` spawn（Windows は npm.cmd しか無く CreateProcess WinError 2）を `process_argv()` で解決（worker の npm-ci と ecosystem lanes の 2 箇所）／
`capture_owned` に `on_heartbeat` 未指定で TypeError／hygiene の重複グループが非決定順／
`FAILED_NODE_RE` が収集済み全 nodeid に一致し全件失敗扱い（**store の失敗 nodeid 上限に当たって必ずクラッシュ**）→ `^(?:FAILED|ERROR)\s+` にアンカー／
`MAX_NODEID_LENGTH` 500 → 16,384（実在の parametrized nodeid は 9,458 文字）／
vitest 収集は **`--root desktop` 必須**（無いと vite.config の alias 解決に失敗）／playwright は `--config=desktop/playwright.config.ts`。

テスト側: `INVESTMENT_WEEKLY_AUDIT=1` は enforcement を**設計上無効化する**ので hygiene の enforcement テストは `monkeypatch.delenv` が要る／
DSN 不在時に error する fixture は `get_postgres_dsn(required=False)` で skip へ／文面固定の SQL アサーションは共有ヘルパー断片一致へ。

## 運用上の罠

- **queue worker が無言で exit 1** する時は、別セッションが残した壊れた job を先に拾って数秒で失敗している。
  `--run-one` を繰り返して滞留 job を終端化すると本命に到達する。job 一覧は
  `.git/investment/proof_pack_queue/v1/jobs/*/events.jsonl` の最終行で判定。
- 監査の実体は `.git/investment/proof_pack_queue/v1/weekly_audit/v1/`（`details/<head>/<job>/summary.json` と `aggregates/`）。
  **merge stop は aggregates の最新 `created_at` で決まる**ので、合格 summary が存在しても後から訂正 summary が書かれると停止したままになる。
- **他セッションの repair_audit が走っている間に full_audit を enqueue したり停止記録を新しくすると、相手の request の
  `blocked_by_*`（immutable）と一致しなくなり、相手の 70 分の証明が機械的に無効になる。** 走行中は待つ。
- git object DB は worktree 間で共有されるため、**push していないローカル commit を別セッションが取り込んで PR にできる**
  （実際 73ee12c6e は Codex の PR #215 の土台として main に入った）。
