---
name: project-framework-docs-overhaul-2026-06
description: 投資フレームワーク総点検 (2026-06-12) の着地内容と、フレームワーク文書編集時の CI 抵触マップ・運用接続3点セット
metadata: 
  node_type: memory
  type: project
  originSessionId: 22eff67e-7af3-4f9a-9eac-2dda50ee503d
---

# 投資フレームワーク総点検 (2026-06-11〜12 着地)

A/B/C 3系統を一括着地（127ファイル変更 + 監査ログ新規1件）。プラン: `C:\Users\kazum\.claude\plans\recursive-coalescing-badger.md`

- **A 残骸・形式**: 02_用語定義4ファイルの Notion 記録先記述を DB+Desktop Control Tower に置換、`07_DB設計/02_Notion_DB設計.md` は Historical バナー（リネームは参照10件+の連鎖で見送り）、R.15 欠番明示、Evidence 章を `## 98.` 採番し末尾章順 97→98→99 に統一（F.2/F.3/E.1〜E.4、本文不変のブロック移動のみ）、更新日 hard-break 正規化113件
- **B 運用接続**: C-005〜C-008 採番（確定期限 2026-09-30）。解像度§4.4 ステージ別最低解像度 / マクロ温度§16.4 16象限マトリクス / R.2 Step3 tail_adj(1.0/0.8/0.5/0.25)+テール予算+流動性 / R.3§1.4 複数トリガー優先順位 / R.5§4.3 22戦略 event_stance デフォルト表（**差分方式**: 戦略側は差分のみ、6戦略に差分セクション） / R.1§2.8 品質→p*→テール→解像度の統合判定フロー / 意思決定プロセス§1.1 1トランシェ=1サイクル
- **C 鮮度**: 00_INDEX Docs群6件最新化、README に運用Docs導線（orphan 48→41）、2026-06 監査ログで月次監査再開（2026-03〜05 は未実施と明記、judge=YELLOW）

## フレームワーク文書編集の CI 抵触マップ（重要）

- `check_framework_html_drift.py`: `09_環境認識/01〜04` の数値・表 ↔ `docs/investment-knowledge-base.html` の JS 定数（REGIME_ALLOCATION 等）を同期チェック。**F.7 追加時に HTML 未追随の既存ドリフトがあった** → HTML 側に行追加で解消。09 の MD を触るなら HTML も同時更新
- `check_framework_structure.py`: orphan-docs は warning（ベースライン41、増やさない統制）。新規ファイルは索引からのリンクをセットで
- `check_strategy_contract_sync.py`: 戦略**ファイル名**と `daily_screener/framework_contract.py` の22戦略 ID 同期。章見出し変更には反応しない
- `check_docs_contract_keywords.py`: スコープに投資フレームワーク/は含まれないが、Notion 旧運用定型文の新規記述は禁止
- リンクチェックは repo 直下 `check_md_links.py --scope 投資フレームワーク`

## 定義→運用接続の3点セット（再発防止パターン）

「定義は充実しているが判断に繋がらない」断絶の修正は必ず: (1) `共通校正タスク.md` に C-xxx 採番（97章 item_status が SSOT、台帳にも同期） → (2) 定義正本に provisional マーク付きで暫定表を追記 → (3) R系実行ルールから参照（数値は1箇所のみ、`last calibrated by C-xxx on date` 注記）。

## 残課題

- C-001/C-004 確定期限超過 → fixed 昇格 or 延期を週次レビューで処理（共通校正タスク 97.1）
- C-005〜C-008 のログ記録開始（gate_failed_step / event_stance / tail_adj / 16象限）→ next_review 2026-06-25
- トレードKPIのDB接続（監査 KPI が N/A のまま）→ 2026-07 監査で可否判断
- 関連: [[feedback-disclosure-kpi-loader-mapping]]
