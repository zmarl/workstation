---
name: bugs-module-split-monkeypatch-binding
description: 巨大 py/テストの分割時の落とし穴（monkeypatch 束縛切れ・__file__ 深さずれ・循環 import・importlib テストの conftest helper 共有）
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 867257d0-6d65-48fe-89f5-4aba2f857b02
---

大きな `xxx_repository.py` を「純移動 + 旧パス re-export ファサード」で分割する時（例: BFF の serving_repository_extensions / research_repository / repository を 2026-07-05 の B5-B7 で解体）に踏む2大罠。

**罠1: `from X import name` はスナップショット束縛 → facade へのパッチが効かない**
- テストが `monkeypatch.setattr(facade, "_query", stub)` していても、移動先モジュール F が `from ._core import _query` していると F は F自身の名前空間の `_query` を見るため、facade を patch しても stub が刺さらない。
- **正しい patch 先 = 「テストが実際に呼ぶ関数（被テスト関数）が属するモジュール」**。定義モジュールでも facade でもない。cross-module helper（例: `_compute_next_check_date` を story_tranche が security_audit から import）も同じで、呼び出し元モジュール側を patch する。
- 例外: エンドポイントテストで router が `repository.X()` と**ファサード属性経由**で呼ぶ場合は、facade への patch が実行時解決されるので `repository.X` のまま残す（repoint 不要）。被テスト関数を直接呼ぶかどうかで判定する。
- shared モジュール（`repository.serving_repository`, `.peer_group_repository`, `._u`）への patch は「その共有モジュール自体の属性」を書き換えるのでファサードが再エクスポートしていれば全移動先に効く（repoint 不要）。
- 大量の patch repoint は AST で「被テスト関数 → モジュール」を引いて自動化できる（[[reference_codex_model_locations]] とは別に scratchpad に repoint スクリプトを作った）。

**罠2: `Path(__file__).resolve().parents[N]` は移動でずれる**
- ファイルを `serving/` や `research/` の一段深いサブパッケージへ移すと repo ルートまでの `parents` 段数が +1 必要。B5 で `_REPO_ROOT parents[3]→[4]`、B6 で `parent.parent.parent → ×4` を修正。症状はデータファイル読めず**サイレントにフォールバック**（JPX 正式業種名「水産・農林業」が ファイル名由来の「水産農林業」に化ける等）。分割後は必ず `grep __file__` して深さ補正。

**罠3: ドメイン分割は循環 import で死ぬ**
- research_repository は 4 ドメインが相互参照で全循環。関数コールグラフは DAG なので、循環を作る「戻りエッジ」の**葉ヘルパーを _base（leaf）へ落とす**か、hub 依存のエントリポイントを hub 側へ移すと非循環化できる。AST で SCC / モジュール間エッジを出す checker を先に回すのが速い。最終的にトポロジカル階層でも安全に切れる。

**罠4: 巨大テスト分割（importlib モード）の helper 共有**
- 2026-07-05 B8 で test_decision_api.py(10,600行/405) と test_serving_repository.py(12,200行/227) をドメイン別パッケージ（`tests/tools/api/decision_api/`・`serving_repository/`）へ純移動。`pyproject.toml` は `--import-mode=importlib`、`__init__.py` は置かない。
- **`from conftest import X` は importlib モードで不可**（`ModuleNotFoundError: conftest`。conftest は mangled 名で登録される）。共有 helper は**一意名の `_shared.py`（例 `_serving_shared.py`）に置き、conftest.py に `sys.path.insert(0, os.path.dirname(__file__))` の bootstrap を入れて `from _serving_shared import X`** で import する（一意名にしないと他テスト dir の同名モジュールと sys.modules 衝突）。
- **fixture は subdir conftest.py へ**（autouse なら dir 全体に自動適用、import 不要）。ただし autouse fixture は**その dir の既存テストファイルにも適用される**ので、既存兄弟テストが壊れないか要確認（今回 decision_api/ に既存2ファイルがあった）。
- plain helper は使用ドメインが単一なら**同居**させれば共有不要（AST で呼び出しテストのドメインを引いて判定）。cross-domain のものだけ `_shared.py` へ。
- 分割前後で **collect 数完全一致**を必ず確認（parametrize 展開で top-level def 数≠collect 数。405 collect vs 354 def など）。旧ファイル名は **CI workflow / contract marker / skill docs** に残るので `grep '<old>.py'` して追随（履歴 worklog/backlog の done 記録は当時の記録なので触らない）。

関連: [[bugs]] [[architecture]]
