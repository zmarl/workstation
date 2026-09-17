---
name: project-valuation-capital-landing-2026-08-17
description: "資本政策+時価評価マイグレーション着地 (2026-08-17, PR #188)。新Alembic revision追加時の追随箇所3点と、gateのlane毎maxfail=1に隠れていたmain既存赤6件の解消"
metadata: 
  node_type: memory
  type: project
  originSessionId: c288e354-4d4e-4325-9c0d-4bba4c1055cb
  modified: 2026-08-17T10:26:56.583Z
---

# 資本政策 + 時価評価の着地（2026-08-17、PR #188）

処分台帳の優先度 D-1（`Investment-valuation-capital-schema-recovery-20260813`）を完成させて着地。
オーナー判断は「未完成テスト2件とも実装する」。worktree 33 → 32 本。

## 対象だった実障害（着地しても止まらない）

- `capital_cost_scorer` が毎日失敗（`core.capital_cost_disclosures` 不在）
- `mart.vw_daily_valuation` が20日連続20分 timeout（価格行ごとの `LATERAL`）

**取り込んだだけでは日次失敗は止まらない。稼働DBへの適用は別途オーナー承認が要る。**

## 実装した2件

- governance 3行を `ON CONFLICT DO NOTHING` にし、実際に挿入したかを
  `ops.alembic_20260813_01_capital_cost_state` に記録。downgrade は自分が入れた行だけ削除する。
  `DO UPDATE` は再適用時に operator 調整値を無言で戻すため。`core.source_catalog` は共有カタログなので記録のみ
- swap 完了後に `_assert_same_snapshot(_CANONICAL, _LEGACY)` で新旧 MV の行数と対称差を実データ検証。
  **downgrade には置かない**（legacy は migration 時点の snapshot で長期間後は正当に乖離するため）

## 新しい Alembic revision を足したとき必ず追随するもの

pinned SQL / governance yml のほかに **3点**。どれも欠けると gate が落ちる:

1. `db/baseline/LOCAL_COMPOSE_BOOTSTRAP_FINGERPRINTS.json`
   — `uv run python -m tools.db_admin.local_compose_bootstrap.main generate-fingerprints --json` で生成し、
   出力の `contract` を `json.dumps(indent=2, sort_keys=True)` + 末尾改行の **LF** で書き戻す。
   **書き込み機能は無い**（README も「レビュー後に反映」と書いている）。Docker 必須
2. `tools/db_admin/earnings_migration_rehearsal/contract_spec.py`
   — `REPOSITORY_SCHEMA_HEAD` と `EXCLUDED_DESCENDANT_REVISIONS`（手編集）
3. `tests/tools/db_admin/earnings_migration_rehearsal/test_contracts.py`
   — 上の2定数をリテラルタプルで再宣言している

## gate を回す前に lane 全体を通す

**`run_local_pytest.py` の各 lane は `--maxfail=1`。1 lane につき1件しか表面化しない。**
t3 を回すたびに1件ずつ潰すと1回65分×N。先に以下を通してから t3 を1回にする:

- `uv run python scripts/dev/run_pytest_lane.py fast --parallel`（非DB全体、約11分・35,346件）
- `uv run python -I scripts/ci/run_local_pytest.py --profile db-focused --test-path tests/db`（約21分）
- `uv run python -I scripts/ci/run_local_db_gate.py --json`（round trip、約1分）

t3-python の後に9段階（Desktop 依存/lint/vitest/build/cargo/typegen/ratchet + db roundtrip + git-diff-check）が
あり、t3-python が赤だと全部 `blocked_by_previous_failure` で**一度も走らない**。

## テストマーカーの罠

**`db_fresh` と `migration` を同時に付けると全 lane が壊れる。** conftest の
`pytest_collection_modifyitems` が pytest 自身の `-m` 絞り込みより先に走るため、
`tests/db` を collect する全 lane で `UsageError("DB tests must select exactly one of ...")` になる。

`tests/test_revision_operation_call_graph.py` は `module.pytestmark` と関数の `pytestmark` を
**静的に**読む。conftest が collection 時に付けるマーカーは見えないので、リテラルで書く必要がある。

revision 操作を呼ぶ test の正しい形（`tests/db/` の兄弟に合わせる）:
`@pytest.mark.requires_db` + `@pytest.mark.serial` + `@pytest.mark.migration`、fixture は
`pg_connection`（`pg_fresh_connection` ではない）、冒頭で `stamp_revision(_BASELINE)` →
`run_alembic_revision(dsn, "upgrade", _HEAD)` と自分で進める。
`_BASELINE = "20260718_03_vw_financial_derived_metrics"`（= `db/baseline/BASELINE_MANIFEST.yml` の `alembic_head`）。

`migration` マーカーが**無い** test は conftest がリポジトリ現在 head まで進める。
そこで head を自 revision 名の定数と比較していると、新 revision 追加で必ず落ちる
（main では偶然一致していただけ）。`require_stamp_safe_baseline(allow_ancestor=True).current_head` を使う。

## 稼働DBのビューが `%%` を持っている

`mart.vw_hidden_asset_adjusted_valuation` の LIKE ワイルドカードは稼働DBと baseline で
`'%%ETF%%'`（`%%` が32個、単独 `%` は0個）。Python の `%` エスケープが混入したまま適用された痕跡。
LIKE では `%%` と `%` は同義なので**実害は無い**。

依存 view を一時的に向け替える migration は、書き戻す定義が baseline と **text 一致**していないと
`run_local_db_gate.py` の `baseline_equals_downgraded` で必ず落ちる。
pinned SQL 側を `%%` に合わせて解決した（目的外の正規化を持ち込まない）。是正するなら baseline 再生成が要る。

**原因特定は使い捨てDBで実測する。** `check_db_baseline_migration_path` の
`extract_inventory` + `_extract_schema_definitions` を baseline 時点と downgrade 後で取って集合差を出せば
1件に絞れる。fingerprint は行データを含まずスキーマのみ。

## ODR-0002 の後始末漏れ（main の既存赤6件・台帳未記録）

いずれも `4202e6367`（invariants ゲート退役）の取り残し。無改変 main で落ちる:

- `tests/scripts/ci/test_run_check_suite.py` 3件 — 登録検査数が退役前のまま
  （全体 61→**実測60**、local-pr 56→**実測55**、および `financial_data_invariants` の在籍 assert）
- `tests/scripts/test_check_development_test_tiers.py` 3件 — 同PRで `run_pytest_lane.py::main` が
  `targets` / `exit_code` 変数を導入したのに、drift 検出 test の needle が旧文のまま。
  `development_test_tiers.yaml` の `required_statement_sequence` は追随済みで test だけ取り残されていた

**main が赤いと `publish-pr` / `finish-pr` が全面的に使えない**（どちらも evidence の
`overall_status == "passed"` を要求）ため、同一 PR で解消した。

## 既知の赤が1件消えた

`test_rehearsal_uses_only_owned_container_and_writes_fail_closed_packet` は
ローカル `.env` に `DECISION_CASE_SHADOW_ENABLED` の宣言が無いのが原因だった。
`.env.example:236` には `DECISION_CASE_SHADOW_ENABLED=false` がある。ローカル `.env`（tracked 外）へ
追記して解消。`_read_local_shadow_flag()` は**ちょうど1回**の出現を要求する。リポジトリ変更は不要。

## 別タスクへ分離

`check_db_relation_authority_map.py` の `fetch_existing_relations()` が `information_schema.tables` を
読むため、PostgreSQL の materialized view が「存在しない relation」になる。
稼働DBの MV は5本（`mart.vw_activist_portfolio` / `vw_daily_valuation` / `vw_edinet_concept_labels` /
`vw_policy_holdings_latest` / `vw_screening_custom_base`）で、既登録2本はいずれも `required: false`。
`mart.vw_daily_valuation` も同じ扱いにして note に理由を書いた。checker 修正は起票済み。

関連: [[project-worktree-inventory-cleanup-2026-08-16]] /
[[project-scheduler-manual-only-drift-2026-08-17]]
