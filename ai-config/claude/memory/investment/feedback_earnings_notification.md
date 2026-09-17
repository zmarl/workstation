---
name: 決算短信リッチ通知フォーマット
description: TDNet決算短信はXBRL抽出→プレーンテキストでリッチ通知する方式。フォーマット要件と実装場所。
type: feedback
---

決算短信の通知はリッチなプレーンテキスト形式（embed不使用）で行う。

**Why:** 決算の財務数値（YoY/QoQ/進捗率/セグメント等）を速報性高く一覧表示するため。

**How to apply:**
- `tools/notifications/tdnet/earnings_xbrl_extractor.py` — XBRL ZIPから即時パース（iXBRL scale/sign対応）
- `tools/notifications/tdnet/earnings_notification_builder.py` — 通知テキスト組み立て
- `tools/notifications/tdnet/main.py::_split_earnings_rich()` — 決算短信を自動分岐
- DB保存: `tdnet_earnings_summary` テーブル

**通知フォーマット要件:**
- セクション区切り: `─────` 線
- Emoji: 🚀(>=100%), 🔥(>=50%), ⬆️(>=30%), 📈黒字転換
- 単体実績: YoY/QoQ + 進捗貢献
- 累計実績: YoY + 会社予想比(Q2以降) + 進捗率 + コンセンサス比
- 配当: 中間/期末/合計/前期比 + 配当利回り
- 業績予想: 前期比 + 四季報比
- セグメント: 1行1セグメント縦表示（▸ セグメント名 売X,XXX 利XXX YoY）
- Q1累計は会社予想比を非表示
- IFRS企業のRevenue概念マッチは改善余地あり
