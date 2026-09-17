thread_id: 01a06ee2-d973-7b21-92d3-7cd1d261e9e6
updated_at: 2026-09-07T00:02:01+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\09\05\rollout-2026-09-05T09-05-55-01a06ee2-d973-7b21-92d3-7cd1d261e9e6.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# Qwen3.8-27Bへ渡すTDnet抽出の9B依存を調査し、追加対応が必要と判明

Rollout context: `D:\Dev\Investment`。ユーザーは、Qwen3.8-27Bの決算分析へ文章を渡す前に、既存TDnet抽出で使われるQwen3.5:9Bをどう扱うべきか、Claude側の提案を確認し、抽出側の準備方針を求めた。

## Task 1: TDnet抽出に残るQwen3.5:9B依存の確認

Outcome: partial

Preference signals:

- ユーザーは「9Bを止める」だけでなく、27Bへ渡す文章側を先に整えたいと依頼している。将来同様の移行では、モデル停止判断と、入力品質・不足状態の保存を分けて説明する。
- 既存の取得・決定的抽出を活かし、Qwenは数値正本や抽出成功を無検証で決めないという方針を維持する。

Key steps:

- `ODR-0023`を確認。Qwen3.5:9Bは決算分析へfallbackせず、旧TDnet通知サーバー・監視は退役対象だが取得・保存・本文抽出コードは残す方針。
- 設定確認で、`tdnet_qwen35_mode=shadow`、`tdnet_ocr_model_text_primary/fallback=qwen3.5:9b`、`tdnet_ocr_model_table_primary/fallback=qwen3.5:9b`を確認。
- `tools/notifications/tdnet/document_extractor.py`では、`qwen35_mode=off`で止まる業績概要・受注補助抽出とは別に、空PDFページの画像OCR、画像KPI抽出、本文からの表復元でOllama呼び出しが残ることを確認。
- `scripts/manifest/tdnet_realtime.yaml`では`tdnet-extractor-daily`が`--qwen35-mode shadow`、`tdnet-ollama-runtime-check-daily`が独立タスクとして登録されている。
- `tools/decision_support/earnings_quality_labeler/labeler.py`には`_LLM_REQUIRED_MODEL = "qwen3.5:9b"`があり、`earnings-quality-llm-check-daily`の停止・HOLDだけでなく、label/label-pending呼び出し元も確認対象と判明。

Failures and how to do differently:

- Claude案の「9B依存は2タスクだけ」という整理は不十分。`qwen35-mode=off`だけでは画像OCR・画像KPI・表復元のOllama経路を止められない。今後はモデル名検索だけでなく、実際の呼び出し経路、設定、manifest、呼び出し元を横断確認する。
- 9Bを27Bへ単純置換する提案は未採用。27Bの画像入力品質・処理時間・運用適合性は別途検証が必要。
- 今回は設定変更、Scheduler変更、モデル起動、実抽出、Qwen実行を行っていない。調査・提案段階であり、解決済みとは扱わない。

Reusable knowledge:

- 9B停止後も、通常のPyMuPDF文字抽出とローカル表検出は残せる。読めないページ・図表・表復元失敗は、非開示や抽出成功へ変換せず、ページ/図表単位の不足・再処理対象として保存する。
- 27Bへ渡す前に、原本PDF/XBRL、URL、hash、公表時刻・取得時刻、資料版、全ページ本文、見出し、表行列、注記、locator、期間、原単位、scopeを保持する。検証済み数値は計算モジュール、出典付き原文と計算結果は27Bへ渡す。
- 最終受入は、文字PDF・画像PDF・複雑表で「9B呼出しなし」「取得できた本文・数値を保持」「未取得部分を不足として明示・再処理可能」を確認する。

References:

- `docs/decisions/20260827-qwen38-earnings-agent-durable-queue.md`（ODR-0023、9B fallback禁止、27B固定、取得・保存・本文抽出を保持）
- `shared/config.py:373-399`（TDnet OCR/Qwen35設定）
- `tools/notifications/tdnet/document_extractor.py:240-350,452-641,752-832`（OCR・画像KPI・表復元のOllama経路）
- `tools/notifications/tdnet/extraction_service.py:89-102,185-227`（抽出サービスとshadow/primary処理）
- `scripts/manifest/tdnet_realtime.yaml:18-80`（抽出・runtime-check manifest）
- `tools/decision_support/earnings_quality_labeler/labeler.py:61`（9B必須モデル）
- `tools/decision_support/earnings_quality_labeler/main.py:31-55,129-145`（LLM check/label呼び出し）
