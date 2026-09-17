---
name: serving_repository_proxy_module_split
description: serving/_market・_decision を subpackage 分割する際の monkeypatch 対応（serving_repository の proxy 注入機構）
metadata: 
  node_type: memory
  type: reference
  originSessionId: 867257d0-6d65-48fe-89f5-4aba2f857b02
---

`tools/api/decision_api/serving/_market.py` / `_decision.py`（各 5000+行）を `serving/market/` `serving/decision/` の subpackage に分割したときの monkeypatch 維持の正解パターン。B9 (2026-07-05, refactor/structural-cleanup-p2) で確立。関連: [[bugs_module_split_monkeypatch_binding]]

## 核心機構: serving_repository.py の proxy 注入
`serving_repository.py` は各 domain モジュールに対し、`_PROXYABLE_NAMES` の各名を「呼び出し時に `serving_repository.<name>` を解決して転送する proxy」に差し替える（`_install_proxy` + `for _mod in _PROXY_MODULES` ループ）。これにより、テストが `monkeypatch.setattr(serving_repository, name, ...)` するだけで、その名を持つ全 domain モジュールの呼び出しに patch が波及する。

## 分割時に必ずやること（順序重要）
1. 分割は「純移動＋クラスタ間 `from .sibling import name`（スナップショット）」で行う。**attr_access 化は不要かつ逆効果**（proxy 機構が断片化を吸収するため）。依存グラフは DAG にする（循環したらクラスタ統合。_market では _macro↔_events 統合で解消）。
2. 新サブモジュール（market 8本 / decision 9本）を **`_PROXY_MODULES` タプルに追加**。
3. テストが patch する内部ヘルパ名で `_PROXYABLE_NAMES` に無いものを**追加**（decision は `_get_market_*_items`/`_fetch_rule_classification_candidates`/`_fetch_company_theme_matches_by_codes`/`_build_market_context`/`_fetch_sub_sector_*`/`_get_screening_latest`/`_load_market_expectation_map`/`_load_watchlist_monitor_snapshot`/`get_relative_strength_snapshots` 等 18 名）。
4. **proxy install の前に**、全 proxyable 名を serving_repository 自身に公開する初期化ループを入れる（`if not hasattr(sr, name): setattr(sr, name, <submodule の original>)`）。これが無いと `monkeypatch.setattr(serving_repository, name)` が **AttributeError で raise**（monkeypatch は既存属性を要求）。
5. ファサード（`_market.py`/`_decision.py`）は全シンボルを明示 re-export し、`pg_repository`・`_u`（import 名なので symbol 再エクスポートに載らない）も facade_extra_header で公開。

## テスト patch のリポイント規則
- `serving_repository.<proxyable>` の patch → **そのまま**（proxy が波及）。
- facade 直 patch（`_market.X` / `decision_serving.X`）は proxy を経由しないので要リポイント:
  - proxyable 名 → `serving_repository.X` に付け替え（テストが serving_repository を import していること。test_peer_comparison は未 import だったので追加）。
  - **非** proxyable 名（例 `_classify_monthly_stat_freshness`, `_fetch_sector_stat_rows`, `_build_sector_customs_context`, wind の `get_macro_rates`/`get_leading_composite`/`get_fear_greed_signal`）→ **呼び出し元サブモジュール**の binding に付け替え（`market._sector_norm.X` 等）。`_u.X` / `pg_repository.X` はモジュール属性 patch なので facade 経由でも波及し不要。
- 落とし穴: facade string patch（`"...serving._market._run_with_backend"`）は分割後 **実 DB 挙動任せ**になり単独では通るが**全体実行で順序依存 fail**。`serving_repository._run_with_backend` へ必ず付け替える。

## file-size budget
分割後 `check_file_size_budget.py --write-baseline` を再生成（4-6分割目標だが凝集優先で 8-9 分割可、超過サブモジュールは baseline 記録で可）。旧ファサードは 5000+→200 行台に縮小。

ツール本体（AST スプリッタ・codemod・repoint スクリプト）は scratchpad に残置。
