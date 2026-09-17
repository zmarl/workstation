---
name: tdnet_document_tables.header_json が改行で壊れる
description: table_structurer._escape_json_array が " のみエスケープで \n/\t を素通りさせていたため、multi-line セル（"調整額\n（注）2" 等）を含む header が無効な JSON として保存されていた
type: feedback
originSessionId: 8451be61-e9d9-4275-a77e-958c175252bd
---
2026-04-18 にセグメント抽出の実データ検証で発見。

**問題**: `tools/notifications/tdnet/table_structurer.py:_escape_json_array` が独自実装で `"` のみエスケープしており、改行文字をそのまま JSON 値として埋め込んでいた。結果として `tdnet_document_tables.header_json` が「先頭 `[`、中身に生改行、末尾 `]`」で JSON として無効になり、`_parse_json_array` が silent に `[]` を返すため、下流のセグメント判定や列ラベル取得が機能しなかった。

**影響**: 過去に抽出した全 tdnet_document_tables 行の header_json が JSON パースできず、classify_segment_table / extract_segment_rows_from_table が空結果を返していた。結果として core.segment_financial_facts への書き込みもゼロだった。

**Why**: 既存 tests が multi-line セルを含まないシンプルなケースのみカバーしていた。本番の PDF では `調整額\n（注）2` や `売上高\n(1)外部顧客...\n(2)...` のような改行が普通にある。

**How to apply**:
- `_escape_json_array` / `_parse_json_array` は `json.dumps(..., ensure_ascii=False)` / `json.loads(...)` で統一
- 新しく JSON 文字列を手組みするコードを書くときは標準 `json` モジュールを使う（raw escape は必ずバグる）
- 既存の DB 行は再抽出で上書きすれば直る（schema は不変）
