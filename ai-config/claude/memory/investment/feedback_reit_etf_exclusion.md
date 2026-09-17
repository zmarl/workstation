---
name: REIT/ETF/ファンド類は常時運用対象外
description: ETF/REIT/投信/ETN など商品クラスは全ての抽出・通知・集計から恒久的に除外する。商品ポリシー ADR 準拠、個別機能ごとに再指摘が発生している。
type: feedback
originSessionId: 2112c80a-3cf4-4683-b2dd-bd8c405f3842
---
REIT・ETF・投信（ファンドライク証券）は **抽出・要約・通知・カバレッジ集計** のいずれのパスでも扱わない。理由は商品ポリシー ADR（`docs/decisions/product-policy-fund-like-exclusion.md`、Phase 19 で ETF/REIT/投信/インフラファンド統合版にリネーム）で恒久停止が宣言されているため。

**Why:** ユーザーの投資判断対象は日本株（事業会社）のみ。REIT/ETF は運用ロジック・指標体系が異なり、同じ通知フォーマット・同じスクリーナーに載せると誤認を招く。ADR で決定済みの恒久停止事項であり、繰り返し指摘されている。

**How to apply:**
- 新しい開示処理パスや通知経路を追加するときは、**入口で必ず** `shared.instrument_policy.is_fund_like_security(code, name=...)` と `shared.instrument_policy.disclosure_title_has_fund_keyword(title)` を通して除外する
- 既存の除外点:
  - `shared/instrument_policy.py:FUND_LIKE_NAME_KEYWORDS` — Phase 19 で REIT 系キーワードを統合 (REIT / 投資法人 / インフラファンド / インベストメント・コーポレーション / Ｊリート / ＲＥＩＴ など)
  - `tools/notifications/tdnet/extraction_repository.py:get_pending_disclosures` — TDnet セグメント抽出の入口
  - Phase 19 で J-REIT framework `j_reit` は Business Model から完全削除済み (framework 71→70)
- 追加忘れが見つかったら即修正する（例: 2026-04-18 の決算短信リッチ通知は KESSAN の分岐時点で除外を入れておらず、REIT 4 件に対して通知テキストを生成していた）
- カバレッジ KPI・スクリーナー結果・定期レポートでも、母集団から ETF/REIT を外して集計すること

**確認ポイント**: リッチ通知・要約・スクリーニング・レポートを新規実装／改修するとき、レビュー時に「ETF/REIT は弾いたか？」を必ず問う。
