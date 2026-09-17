---
name: project-db-lane-rot-fix-2026-07-13
description: "db レーン全面修理完了 (2026-07-13, PR #51)。231失敗→0。本番バグ7件発見修理（ml view 喪失・EQL suppress 連鎖等）"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5e52f81c-15d6-4614-9863-83f189d25659
---

# db レーン全面修理 (2026-07-13, PR #51 マージ済み)

worklog: docs/worklogs/20260713-db-lane-rot-fix.md。実行は fix/db-lane-rot worktree（削除済み）、私+dbfix agent の2アクター（DB 実行は単独アクター厳守）。

## 結果
- `-m "db and not e2e"`（investment_test 実 PG）: 230failed+7errors / 122passed → **360 passed / 0 failed**（2連続同一で順序独立確認）
- 回帰なし: fast 並列 11,670 / フル並列 13,706 / ruff / budget / single-head / vitest 全 green

## 発見した本番実装バグ（修理済み・重要）
1. **mart.vw_ml_earnings_labels_v1 / dataset_v1 が本番から喪失**: 旧 db/foundation_postgres 削除時（9607db00）に alembic 未移行。日次 earnings_post_return_5d が存在しない view を参照し続けていた。alembic 20260713_01 で復元・本番適用・baseline 再生成
2. **EQL `_load_event_kpis` の suppress 連鎖**: 存在しない列の SELECT が PG トランザクションを abort → 後続クエリが `contextlib.suppress` 内で InFailedSqlTransaction を握りつぶし空を返す → **presentation KPI が本番で常時欠落**。列マッピング修正 + per-source savepoint 分離（`shared.tooling.repository.fetch_all_dicts_isolated` 新設）
3. consensus_revision `get_consensus_history` も同型の abort 連鎖（契約外テーブル LATERAL JOIN）
4. options_flow の ingest source registry 二重 seed（notes 違いのみ）→ 統合
5. topix bootstrap が information_schema に schema 修飾名を渡し常に誤判定
6. news_detector が failed-run の hash を dedup から除外せず修復不能化 → run status JOIN
7. tdnet backfill の legacy remediation が未配線 dead code → init へ配線（NULL 限定冪等・プロセス内1回）

## 再利用可能な知見
1. **「PG トランザクション abort + suppress」は静かな全滅パターン**: 1つの UndefinedColumn/Table が同一 Tx の後続クエリを全部 InFailedSqlTransaction にし、suppress があると「空の結果」に化ける。optional ソースの読取は `fetch_all_dicts_isolated`（savepoint 分離）を使う
2. **DDL 正本樹替え時はオブジェクト喪失を疑え**: 旧ツリー削除時に alembic 未移行の view がサイレント消失していた。`git grep <name> <削除コミット>^ -- db/` で発掘 → verbatim 復元 revision
3. **conftest の契約 bootstrap は *_test PG にも適用**（dbname サフィックスガード付き）。「Missing migration-managed DB table(s)」系はこれで一括解消
4. **admin-context 接頭辞の罠**: shared/sql_remediation は関数名接頭辞（bootstrap_/init_ 等）で admin 判定。テスト DDL ヘルパーを create_* に改名すると runtime 拒否に落ちる
5. **fail-fast 検証テスト vs 共通 bootstrap fixture の衝突**は「テスト setup で対象 relation を明示 DROP して前提復元」で解決（finalize は readiness が同じ view を要求するため legacy-free スタブ再作成が必要だった）
6. **時刻依存テスト**: toISOString()（UTC）とローカル日付比較の混在は JST 0〜9時のみ落ちる。日付 fixture はローカル組み立てで
7. db レーン検証の DSN は .env の DSN の DB 名を investment_test に差し替えて export（本番 investment に向けたら fixture が全 DROP する。dbname ガードはあるが厳守）
8. dbfix agent 引き継ぎで確立した資産: tests/fixtures/ddl/50/52/54/55/56/82/108/109 系 kit・chase_deps.py（欠落 relation を baseline から自動抽出・topo ソート）

関連: [[project-test-suite-slim-2026-07-12]]（handover 元）
