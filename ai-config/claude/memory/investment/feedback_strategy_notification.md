---
name: 中期経営計画・成長可能性資料のリッチ通知フォーマット
description: 中期経営計画/成長可能性資料はPDF→LLM抽出→構造化プレーンテキスト通知で送信する
type: feedback
---

中期経営計画・成長可能性資料の開示は、決算短信と同様にリッチなプレーンテキスト通知で送信する。

**Why:** 標準Embed通知（タイトル+コード+URL）では内容が不十分。PDF内の数値目標・施策を即座に把握したい。

**How to apply:** STRカテゴリのうち中期経営計画/成長可能性の開示が来たら、以下のパイプラインで処理:
1. PDF DL → PyMuPDFテキスト抽出 → Qwen 3.5で構造化JSON抽出
2. `strategy_plan_notification_builder.py` でプレーンテキスト整形
3. `notify_strategy_rich()` でSTRチャンネルへ送信

**通知フォーマット:**
```
🟣 中期経営計画 HH:MM
{銘柄コード}
{会社名}
{開示タイトル}
【要約】
期間: {計画期間}
数値目標:
年度 | 売上高 | 営業利益 | 経常利益 | 純利益 | その他KPI
今期 | {ベースライン} |
{各年度} | {金額}(前年比±X.X%) |
年平均 | {CAGR} |
重点施策: {施策1}／{施策2}／{施策3}
株主還元: {配当方針等}
前提/リスク: {前提条件・リスク}
ポイント: {計画の要点1文}
url:{開示URL}
```

**実装ファイル:**
- `tools/notifications/tdnet/strategy_plan_extractor.py` — 抽出
- `tools/notifications/tdnet/strategy_plan_notification_builder.py` — 整形
- `tools/notifications/tdnet/notifier.py` の `notify_strategy_rich()` — 送信
- `tools/notifications/tdnet/main.py` の `_split_strategy_rich()` — フロー接続
