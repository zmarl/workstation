---
name: DATA-14 Phase 2-A vendor readiness scaffold 完了状態
description: DATA-14 enterprise vendor (QUICK/Bloomberg/Refinitiv) は 2026-04-18 にコード側 scaffold 完了、activation は契約後。何をすれば有効化できるか。
type: project
originSessionId: eccc8df5-b239-4e2a-9fc5-fe9ac66f3627
---
DATA-14 の enterprise vendor (QUICK / Bloomberg / Refinitiv) は 2026-04-18 にコード側 readiness scaffold が完了した（`docs/worklogs/20260418-data14-vendor-readiness-scaffold.md`）。SourceSpec は `enabled=False, reason="contract_pending"` のまま維持されており、契約受領時に最小差分で activate できる状態。

**Why:** 実 API 接続は外部契約が前提のためコード側では実装できないが、契約入手の瞬間に ingest を動かせるよう配線を完結させておくことで、activation 時の blast radius を最小化する狙い。

**How to apply:** DATA-14 関連で着手する場合は以下の activation 手順を踏む（README の「Enterprise Vendor Activation Runbook」と同内容）:
1. `.env` の `{QUICK,BLOOMBERG,REFINITIV}_API_KEY` / `_API_ENDPOINT` を設定
2. `auth-status --json` で vendor の `credential_status.status=ready` を確認
3. `sources/{quick,bloomberg,refinitiv}.py` の `fetch` / `fetch_batch` を vendor 仕様で実装（現状は `NotImplementedError`）
4. `main.py::_SOURCE_SPECS[<vendor>].enabled=True` に切替
5. `preferred.py` の vendor seed rule の `effective_from` を `PRECEDENCE_PENDING_DATE=2099-01-01` から契約発効日に書換
6. smoke test: `ingest --sources <vendor> --dry-run --json`
7. `scripts/run_manifest.yaml` の `consensus-collector-daily` に vendor を追加、scheduler 再登録

**姉妹タスクとして同日完了した nikkei_quick operational resilience:**
- `NIKKEI_QUICK_SESSION_WARN_HOURS` (既定 4h) で auth-status に `status=expiring_soon` が出る
- `NikkeiFetchStatus.SESSION_EXPIRED` を連続 3 件検知で batch を early-break
- `_run_sources` が source_result.status=session_expired / ingest_run=partial で伝搬し silent no_data 化を防ぐ

**残件（別フェーズで管理）:** vendor 契約締結後の fetch 本体実装と `effective_from` 書換。日経運用の再安定化は scaffold で改善済みだが、運用投入後に通知経路の live smoke が必要。
