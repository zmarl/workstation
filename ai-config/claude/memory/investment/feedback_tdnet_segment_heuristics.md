---
name: TDnet 決算短信のセグメント表抽出ヒューリスティック
description: tools/notifications/tdnet/table_structurer.py でセグメント表を判定・抽出する際のキーワード群、単位推定、メタ行除外の設計根拠
type: feedback
originSessionId: 8451be61-e9d9-4275-a77e-958c175252bd
---
決算短信の表構造から `core.segment_financial_facts` に書き込む経路を 2026-04-18 に実装した。判定ヒューリスティックと制約メモ。

**Why**: EDINET XBRL のセグメント次元は 52% カバレッジが上限で、キーエンス/任天堂/武田/キヤノン等の大手は空。TDnet 決算短信のセグメント表を補完ソースとして使う必要があり、表判定・抽出の再現可能な規則を保存しておく。

**How to apply**:
- セグメント判定キーワードを追加する時は `_SEGMENT_HEADER_PATTERNS`（table_structurer.py）に regex で追加
- 和名メトリクスを追加する時は `_SEGMENT_METRIC_LABEL_MAP`（table_structurer.py）。**長いキー（「セグメント間の内部売上高」等）を短いキー（「売上高」）より先に** 置くこと。先頭マッチで判定しているため
- メタ行（合計/調整額等）の除外は `_SEGMENT_META_ROW_NAMES`（table_structurer.py）と `_OVERVIEW_SEGMENT_META_NAMES`（tools/api/decision_api/serving/_company.py）の 2 箇所。**両方を同期させる**
- 単位推定は `_infer_unit_hint`。表タイトル→raw_markdown 先頭 400 文字→ヘッダ 2 行の順で「百万円」「千円」「億円」を探す
- 値正規化: `segment_repository._normalize_value` で `million_jpy` などを `jpy` に掛け算して正規化、`unit='jpy'` で保存。EDINET XBRL（既に jpy）と揃える
- segment_catalog は SELECT-first（duplicate 耐性）。`_ensure_segment` を流用
- segment_financial_facts は `ON CONFLICT (instrument_id, segment_id, fiscal_period, metric_name) DO UPDATE` で、TDnet が EDINET 由来データを上書きする運用（lineage で source 追跡）
- 非ブロッキング: `_persist_segment_facts` は全例外を try/except で握り潰し、通知本体を止めない
