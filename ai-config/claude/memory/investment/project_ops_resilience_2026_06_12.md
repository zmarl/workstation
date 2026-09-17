---
name: project-ops-resilience-2026-06-12
description: "6/2-11 Postgres 長期ダウン障害の真因確定と再発対策 (db_connectivity_watchdog 新設、failure 分類修正、ingest 修復)。持ち越し: Git 分割 / スケジューラ残登録 / 契約レジストリ乖離"
metadata: 
  node_type: memory
  type: project
  originSessionId: b71979e6-2eb7-4359-9ffe-2ed4b4099bc4
---

# 運用レジリエンス修正 (2026-06-12 着地)

- **6/2〜6/11 の大規模失敗 (64.8% / 541件) の真因は Postgres コンテナの長期ダウン**（本物のインフラ障害、6/11 20:58 再起動で終息）。品質ゲートが緑だったのは DB 内基準のため障害中は failed 行すら書けなかったから。run_tool.ps1 が PoolTimeout を runtime_error に誤分類して見かけを増幅していた
- **対策**: `tools/quality/db_connectivity_watchdog/`（DB 無依存・filesystem 状態・P0 アラート・60分再アラート・復旧通知）+ run_tool.ps1 の external_dependency 分類に DB 不達パターン追加。**watchdog の manifest 登録は未実施**（README に推奨設定）
- ollama 再起動でモデルストアが消えることがある → `nomic-embed-text` 404 は `ollama pull` で復旧。embedder は 404 を EmbeddingModelMissingError で即 fail + pull ヒント
- news_detector serve は連続 20 失敗で自走停止 (exit 1, status=failed)。ゾンビ 'running' 行 → stuck_task_detector 強制失敗のパターンを解消
- launcher contract チェックの AttributeError は日本語 PS 5.1 の cp932 出力起因 → errors="replace" + None ガードで修復済み
- **持ち越し** (並行セッション「EDINET 抽出破損修正」完了後): ① Git テーマ別 9 コミット分割 (plan: delightful-finding-cat.md) ② スケジューラ残 6 タスク登録 (-OnlyTaskNames、パスワードは scheduler-registration skill) + panel health digest 新設 ③ ops.ingest_contract_profiles の列要求乖離 (毎日 01:20 の偽 failed、source=multi) の UPDATE ④ fiscal_year ラベル統一 (edinet↔jquants)
- worklog: `docs/worklogs/20260612-ops-resilience-fixes.md`
