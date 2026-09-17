---
name: 投資フレームワーク SSOT (21戦略 / 共通ゲート / レジーム / 分類)
description: 21戦略カタログ・共通ゲート G1-G5・マクロレジーム配分・subsector 4階層の正本サマリ。docs/handoff/investment-framework-chatgpt-context-20/ を要約
type: project
originSessionId: 06a37e34-9804-430a-aa3a-f36ce72a0a61
---
正本: `docs/handoff/investment-framework-chatgpt-context-20/` (2026-04-21 整備、12ファイル)。本メモリは検索用ダイジェスト。

## 1. 21戦略カタログ (4群)

| 群 | 戦略 | 目的 | 主因子 | 時間軸 | score mode |
|---|---|---|---|---|---|
| **F (Fundamentals)** | F.1 四半期モメンタム / F.2 決算跨ぎ / F.3 バリュー / F.4 配当総還元 / F.5 クオリティ複利 / F.6 統合ミッド / F.7 CAN-SLIM | 業績・割安・還元・品質・成長 | E or M | short〜long | 全て ranked |
| **T (Technical)** | T.1 ブレイクアウト / T.2 レンジスイング / T.3 ファクターニュートラル L/S / T.4 IV ボラ | 価格行動・市場構造・L/S・IV | F (T.3 のみ宣言必須) | short〜mid | T.1/T.2=ranked, T.3=pair_list, T.4=active_list |
| **S (Supply/Demand)** | S.1 テーマ / S.2 IPO セカンダリ / S.3 ショート / S.4 インデックス需給 / S.5 PO / S.6 自社株買い / S.7 投げ拾い | 需給・テーマ・指数イベント | M or F | short〜mid | S.4=active_list, 他=ranked |
| **E (Event-driven)** | E.1 イベントドリブン / E.2 TOB / E.3 アクティビスト / E.4 事業再編 | TOB・アクティビスト・再編 | M/E | mid | E.2=active_list, 他=ranked |

candidate universe バケット: short=T.1/T.2/S.7, mid=F.1/F.2/F.6/F.7/S.1/S.2/S.6, long=F.3/F.4/F.5, special_event=E.1-4/S.4/S.5/T.4。S.3/T.3 は通常キュー無効。

実装正本: `tools/decision_support/daily_screener/framework_contract.py`。

## 2. 共通 Hard Gate (取引前)

| ゲート | 内容 |
|---|---|
| Edge Statement | 優位性を1文で説明できる |
| U/D/p* | 上値・下値・必要勝率を置ける (`p* = D / (U+D)`) |
| Invalidation | Hard/Soft 否定条件 + T-stop |
| Tail/Liquidity | ギャップ・板薄・イベントリスク |
| PF mode | risk_off / freeze は新規禁止 |
| R.0 limits | DD・テーマ集中・ショート・総エクスポ |
| Source quality | 一次情報で重要数値照合 |

スコア軸: 解像度 (info_resolution_score 0-3) / 過熱度 (低/中/高/極端) / Reaction Quality / U/D 推定品質 / 否定条件設計品質 / 主因子 (E/M/F) 明確度。**1 トランシェで主因子は固定**。

## 3. マクロレジーム & 戦略配分

日次スコアカード 7 項目 (ブレッドス / ボラ / 金利 / 為替 / 流動性 / マクロセンチメント / テーマ) を ±1 で採点 → 合計 -7〜+7。

| 合計 | レジーム | スタンス | キャッシュ |
|---|---|---|---|
| +4〜+7 | Risk-On | 押し目買い積極 | 5-15% |
| +1〜+3 | Transition-Up | 選別的・回復初動 | 10-20% |
| -3〜0 | Transition-Down | 慎重・防御寄り | 20-35% |
| -7〜-4 | Risk-Off | 戻り売り・キャッシュ厚 | 30-50% |

confidence は 6項目以上同方向=high / 4-5=medium / 3以下=low。レジーム変更には2営業日連続シグナルを要求。PF mode (Normal/Caution/RiskOff/Freeze) はレジームより優先。サイクル局面 (金融/業績/逆金融/逆業績) は配分レンジ内の強弱調整。

## 4. サブセクター 4 階層分類

| 層 | 粒度 | 多重度 | ソース |
|---|---|---|---|
| 33業種 / 17業種 | 大 | 1:1 | TSE 正本 |
| サブセクター | 中 | **1:N** (多対多) | YAML + 自動推定 + 手動 |
| ピアグループ | 小 | 1:1 主系統 | YAML + 自動推定 + 手動 |

実装: `db/greenfield_postgres/100_sub_sector_registry.sql`, `tools/decision_support/sub_sector_classifier/`, BFF `sub_sector_repository.py`, Desktop `ClassificationBadges/SubSectorOverrideEditor/SectorSubGroupsPanel`。週次再計算 (月曜 04:00)。

## 5. 利用シーン

- 戦略 ID (F.1, T.3, E.2 等) が出てきた時の position 確認
- スクリーニング/decision gate 設計時に framework_contract.py との整合確認
- レジーム変化を見て「今どの戦略を強める/抑える」を判断
- subsector / peer の取り扱いで 1:N と 1:1 の境界を踏み外さない
