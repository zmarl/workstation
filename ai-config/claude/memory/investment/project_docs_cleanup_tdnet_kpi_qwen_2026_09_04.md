---
name: project-docs-cleanup-tdnet-kpi-qwen-2026-09-04
description: "文書整理の再開点 (09-04)。PR #366 未マージ（監査状態 unreadable）。旧 KPI 抽出 3 文書が ODR-0024 と矛盾したまま現行正本として並存、tdnet_kpi_resume_gate は入力の生産者が無く常に「再開不可」"
metadata: 
  node_type: memory
  type: project
  originSessionId: 1ca2e71d-888b-4cbd-977b-709f0531b012
  modified: 2026-09-05T01:15:18.058Z
---

# 文書整理 4.5（TDNET品質・KPI と Qwen 分析の責務分離）の調査結果 (2026-09-04)

**状態**: 再開用 worklog `docs/worklogs/20260904-documentation-cleanup-transition.md` は PR #366（branch `codex/documentation-cleanup-transition-20260904`、worktree `D:/Dev/Investment-documentation-cleanup-transition`、claim `564265ebe9e216073d05007bbf4e2a6a`）。main と同期済み・競合なしだが、`harness_status.py` の Merge stop が `unknown / weekly audit state is unreadable` で finish-pr 不可。修復は他セッションの PR #365（open）。触らない。

**4.5 の判断: 09-05 にオーナーが問 1〜3 とも推奨案を採用**（「Qwen 側で使う既存 TDnet 資産は残し、使わないものは残さない」方針を明言）。オーナーの誤解を訂正済み: **OPS-12 は資料抽出 Qwen ではなく上流の入力健全性ゲート**（Ollama 稼働確認／TDNET 抽出／品質チェックの 3 レーン集約）。補正 3 点を提示済み: ①OPS-12 の Ollama レーンは Qwen3.8（自前 8081 サーバ）が使わない旧 Qwen3.5 系だが、TDNET 抽出タスクは今も `--qwen35-mode shadow` で Ollama を併走させているので停止判断は別途（運用変更）／②旧意思決定台帳の 2 条項は 2026-07-20 IR 証拠台帳 ODR が既に範囲限定で上書き済み（先例）／③ユニバース除外契約（時価総額<50億 等）は Qwen オーナー要求「allowlist にしない」と矛盾 → 移設でなく明示却下。**着手順**: wave 1 = 衝突しない部分（台帳 6 件、2026-05 status/proposals 項目 3 の履歴注記、resume gate「未稼働」記録、runbook 索引から旧ランブック除外）→ wave 2 = **PR #351（Qwen 設計 5 本を編集中、未マージ）の後**に旧 3 文書の履歴化 + Qwen 側 supersedes 往復 + 参照 2 文書（business-model/07-kpi-packs、pure-play 決定）の付け替え → wave 3 = resume gate コード削除は別タスク。台帳見込み: KPI-00 再開前提文言を外す／01 は資産 SoR として残し OPS-12 依存を外す／02（IR 補完）05（24h SLA）は要判断／03 GPU 分岐退役・OCR 未決／04 完了扱い／LLM-EXP-01 は ODR-0024 で完了候補。**wave 1 の「はい」はまだ得ていない**（09-05 は PR #353 引き継ぎに時間を使った）。

## 調査で確定した事実（コードから読み直すと 30 分かかる）

- **「四責務分離」は新提案ではない**。`docs/design/qwen38-earnings-analysis-owner-requirements.md` §2 で「資料抽出Qwen／決定論pipeline・計算compiler／評価Qwen」の三役が採用済み。4.5 との差は上流の「入力取得・source品質」層を独立に置くかだけ。
- **旧 KPI 抽出 3 文書が現行正本のまま**: `docs/architecture/kpi-extraction-masterplan.md`（metadata 無し）、`docs/decisions/kpi-extraction-decisions.md`（authority_key `product.kpi_extraction`, Accepted, last_validated 2026-08-31）、`docs/runbooks/kpi-extraction-ops.md`（`runbook.current.kpi_extraction_operations`, Design-Locked, runbook 索引 12 番）。採用決定 16 件のうち「主系=ローカルLLM(Qwen3.5 shadow)」「KPI再開=OPS-12 完了」「拡張は OPS-12 後」が ODR-0024（08-29、Qwen は旧ゲートを待たない）と矛盾。Qwen 設計群はこの 3 文書を一切リンクせず supersedes/superseded_by 空 → **同じ問いに 2 系統の現行正本**。08-31 の last_validated は構造検証のみで意味は未検証。
- **`tools/quality/tdnet_kpi_resume_gate` は何も測っていない**: quality_score / exception_count は呼び出し側引数で、生産者がリポジトリに存在しない。BFF `GET /api/v1/ops/tdnet-kpi-gate/status`、Desktop `TdnetKpiGateBanner`（OpsHub「データオペレーション」タブ、`DataOpsTab.tsx:1155` が引数なしで呼ぶ）は**常に eligible:false を表示**。`db/runtime_schema_governance_allowlist.yml` の `tdnet_kpi_resume_rules` はどのコードも読まない。manifest 登録なし、実行痕跡ゼロ。2026-05 status の「Implementation Achieved」は名目上。
- **本当に動いている TDNET 品質系**: `tdnet-quality-check-daily` と `tdnet-ops12-gate-daily`（09-04 08:35 に evidence 更新）。OPS-12 は 07-12 から blocked（3取引日 pass 0/3）。
- **Qwen3.8-27B worker は Scheduler でなく Tauri 所有の子プロセス**（ODR-0023）。manifest に `earnings_evaluation_assistant` の task は無い。
- **台帳の不整合**: `TDNET-KPI-00〜05` が OPS-12 依存で生存、`LLM-EXP-01` が `TDNET-KPI-05` を blocked_by、改革 program は Gate 3 配下。ODR-0024 と未同期。
- 旧 runbook の運用 KPI 名のうち `asset_capture_rate` だけ `tools/notifications/tdnet/asset_registry.py` に実装あり。他 4 つは未実装。

## 提示した推奨（承認待ち）

1. Qwen オーナー要求 §2 の三役分離を正本とし、旧 3 文書は「後継: Qwen 設計群」として履歴化。Qwen 側に無い要求（入力優先順位 HTML>XBRL>PDF>OCR、ユニバース除外契約、T+1 SLA、retryable/terminal/needs_manual、95-98% 目標）は一件ずつ移すか明示却下。
2. resume gate は文書上「資産はあるが未稼働」と記録し、削除は別タスク・別承認。
3. TDNET-KPI-00/01 は入力取得品質（OPS-12）系として残し、02〜05 は Qwen 証拠パイプラインと照合して付け替え、LLM-EXP-01 の依存を外す。

**How to apply**: 承認後は小 wave（旧 3 文書の履歴化 metadata → Qwen 設計への要求移設 → 台帳 → 2026-05 status/proposals 項目3 注記 → runbook 索引）。意味が変わる編集は各 wave で変更前後と失う情報を提示してから。関連: [[feedback-ask-dont-infer-authorization]]
