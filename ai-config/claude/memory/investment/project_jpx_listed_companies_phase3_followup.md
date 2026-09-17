---
name: jpx-listed-companies-phase3-followup
description: Phase 3 残 follow-up 一括クローズ。17 件 sanity residual を分類し 10 件は JPX list 取り込み漏れと判明 → 保護コード機構を sync ETL に永続実装、sync --apply 初回本番投入完了 (2026-05-14)
metadata: 
  node_type: memory
  type: project
  originSessionId: b7ad1896-3e02-4aed-b938-508748a130b3
---

JPX 銘柄マスター同期 Phase 3 残 follow-up 一括クローズ (2026-05-14)。Plan `effervescent-greeting-snowglobe.md` 経由で 5 Step を順次実行、Step 1 で 17 件 sanity residual を分類した際に 10 件の通常 4 市場銘柄が JPX list 取り込み漏れと判明、保護コード機構を sync ETL に永続実装してから F2 sync --apply 本番投入を完遂。

**Why:** Phase 3 worklog (`docs/worklogs/20260514-jpx-listed-companies-phase3.md`) で「scheduler 配線完了」と主張されていたが、commit `caf184c2` 時点では manifest entry 1 件 + bat wrapper 2 本のみで register_schedules.ps1 未配線。さらに sanity_hit_rate=0.996184 の不一致 17 件には誤 deactivate リスクのある通常 4 市場銘柄 10 件 (キヤノン電子 / パシフィック工業 / 三菱ロジスネクスト 等) が含まれていた。これらを補強せず F2 を強行すると active 銘柄を誤って降格させ、R1 ガードで自動復活不可になる。

**How to apply:**
- 新規月次 sync ETL の運用時、`config/jpx_protected_codes.yaml` に登録された code は `core_codes - jpx_codes` でマッチしても自動 deactivate されず `protected_from_removal` finding として記録される (sync.py の `_load_protected_codes` + `_build_plan` の保護分岐)
- 保護コードは `next_review_at` (yaml 内) を過ぎたら手動レビューする運用。2026-06-01 snapshot で再収載されたら yaml から削除
- F2 で deactivate された 523 件のうち 17 件は本 followup 由来 (10 件保護 + 7 件正当)。残 506 件は他経路の正当廃止
- 保護コード機構は `protected_codes_path=None` で完全無効化可能 (tests で legacy 動作を維持する用)
- Phase 4 (`docs/worklogs/20260514-jpx-listed-companies-phase3-followup.md` § 5) で scheduler 配線補完: manifest `jpx-true-monthly` を `jpx-listed-companies-sync-monthly` にリネーム + drift_check entry 新設 + register_schedules.ps1 に Update-InvestmentTask 2 行

**Files of record:**
- 新規実装: `tools/market_data/jpx_listed_companies/sync.py` (保護コード機構 +82/-3)、`config/jpx_protected_codes.yaml` (10 銘柄 entry)、`tests/tools/market_data/jpx_listed_companies/test_sync.py` (regression 2 件追加)
- Desktop UI: `desktop/src/components/panels/JpxDriftReportPanel.tsx` (`protected_from_removal` label + 紫 badge)
- Worklog: `docs/worklogs/20260514-jpx-listed-companies-phase3-followup.md` (Lite)
- Runbook: `docs/runbooks/jpx-listed-companies-scheduler-registration.md` (admin PowerShell 経由 F1 用)
- 証跡: `tmp/jpx_sanity_residual_2026-05-14.json` (commit 対象外、17 件全件分類)
- Plan: `C:/Users/kazum/.claude/plans/effervescent-greeting-snowglobe.md`

**Live state after F2 (2026-05-14 02:11 UTC):**
- `raw.ingest_runs.run_id=0edee8ae-6167-49f1-a8ff-5ee365d6d983` / status=success / error_count=0 / records_out=709
- findings_recorded=1237 (added=9 / removed=523 / segment_changed=176 / legacy_label_resync=1 / protected_from_removal=10 / fund_like_excluded=518)
- `core.instruments` is_active=TRUE 4455 → 3932 / FALSE 922 → 1445
- 保護 10 件 (202A/3541/3902/4690/5259/7092/7105/7250/7739/8209) は is_active=TRUE 維持
- 7 件正当 (5883/7056/9287 + 4 EDINET) は is_active=FALSE に降格
- BFF `/api/v1/ops/jpx-drift-report` 応答正常、sanity_hit_rate=0.996184、Desktop パネルで `protected_from_removal` 紫バッジが summary に表示される

**Multi-agent execution:**
- 1 Explore agent で Phase 3 follow-up 調査 (sync.py / BFF / register_schedules.ps1 状態確認、500 語以内レポート)
- Orchestrator 直接実装で保護コード機構 + apply 実行 + worklog 整備

**Quality gates:**
- `uv run pytest tests/tools/market_data/jpx_listed_companies/` → 32/32 pass (元 30 + 新 2)
- `uv run ruff check tools/market_data/jpx_listed_companies/ tests/tools/market_data/jpx_listed_companies/` → 0 errors
- `pnpm vitest run src/components/panels/JpxDriftReportPanel.test.tsx` → 4/4 pass

**Follow-ups (繰越):**
1. ~~Phase 4 manifest + register_schedules.ps1 配線補完~~ **resolved 2026-05-14** → [[jpx-listed-companies-phase4]] Track A で着地
2. F1 admin PowerShell 実登録 (ユーザー手動、Phase 4 完了後推奨)
3. 10 件保護コードの 2026-06-15 再評価 (next_review_at)。次月 snapshot 収載なら yaml から削除
4. ~~JPX list 取り込み漏れ 10 件の原因調査~~ **resolved 2026-05-14** → [[jpx-listed-companies-phase4]] Track B で P1 (JPX 配信側欠落) 確定、保護コード機構が恒久対策
