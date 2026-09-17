---
name: bugs-refactor-tooling-footguns
description: "大規模リファクタで踏んだツール系の罠 4 件（ruff RUF100 の select 置換、モジュール分割時の monkeypatch 束縛、parents[N] 深さ、pytest importlib で conftest import 不可）"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 867257d0-6d65-48fe-89f5-4aba2f857b02
---

# リファクタ用ツールの罠（2026-07-05 structural-cleanup で実地確認）

## ruff の未使用 noqa 掃除は `--extend-select RUF100`
- **問題**: `ruff check --select RUF100 --fix` は設定の select を**置換**するため、有効ルール（T201/F401 等）向けの生きた noqa まで「不要」と誤判定して 2,345 件削除 → 1,936 件の T201 等が噴出した
- **解決**: `--extend-select RUF100 --fix` なら正しく 983 件のみ削除。適用後は必ず素の `ruff check .` で 0 を確認

## モジュール分割時の monkeypatch は「呼び出し元モジュール」に当てる
- **原因**: `from X import f` はスナップショット束縛。façade（re-export 元）をパッチしても、移動先モジュール内の呼び出しには効かない。定義モジュールへのパッチも、別モジュールが名前を import 済みなら効かない
- **解決**: パッチ対象は「被テスト関数が属するモジュールの名前空間」。B5-B7 では AST 解析で 126 箇所を自動リポイントした。逆に「テストが patch する関数とその直接呼び出し元」は同一モジュールに残す（P6 の taint 解析方式）

## ファイル相対パス定数は移動で壊れる
- `Path(__file__).parents[3]` / `parent.parent...` はディレクトリ深さ依存。1 段深い場所へ移すと黙って別ディレクトリを指す（fallback があると**エラーにならず挙動だけ変わる**）。移動時は grep `parents\[|__file__` を必ず確認

## pytest importlib モードでは conftest から import できない
- `--import-mode=importlib` + `__init__.py` なしの分割テストで `from conftest import X` は ModuleNotFoundError。共有 helper は一意名 `_xxx_shared.py` に置き、conftest.py で sys.path bootstrap（fixture は conftest の autouse で自動適用される）

**How to apply:** 大規模な機械変換の後は「変換器の出力が期待形か」を独立の機械検証（diff の形状チェック・AST byte 比較・収集数一致）で確認してからコミットする。今回この方式でゼロ regression を維持できた。
