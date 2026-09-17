---
name: project-business-model-phase20-probe-expansion
description: Phase 20 着地 (2026-05-17/18)。169 銘柄全 probe で available 120/169 判明、5 並列 agent で Tier 1 補完して available 123 達成。Stream B で新規候補 125 銘柄リスト化、Stream D は次 Phase 送り。
metadata: 
  node_type: memory
  type: project
  originSessionId: 5ef58e50-8248-4651-9ed2-e99011d2e94b
---

Phase 20 着地 (2026-05-17 開始 / 2026-05-18 完了)。

## 経緯と発見

ユーザーから「probe 母集団 40 → 100-200 拡張」の指示。調査の結果、「40」は monitoring panel 数 (template 種類数) であり、銘柄ベースで見ると SAMPLE_MAPPINGS 169 銘柄が既に登録済と判明。

- 169 銘柄全 probe (`scripts/probe_business_model_frameworks.py`) で 12,118 行出力
- 銘柄ベース内訳: **available ≥ 1 framework = 120 銘柄 (71%)** / partial only = 44 / no signal = 5
- partial 3,500 行のうち 1,120 が metrics_partial_coverage (metric 1〜2 個追加で available 化可能帯域)

**「monitoring 40」と「available 銘柄数」は別軸**。後者は既に 120 まで達成済で、ユーザーの認識ギャップを Phase 20 で解消。

## Stream 編成と成果

| Stream | 内容 | 結果 |
|--------|------|------|
| A | 169 銘柄全 probe | 完了、bg 14 分。available 120 判明 |
| B | 新規 anchor 候補 (業種×時価総額 Top-N) | agent 委任、218 候補抽出、125 が新規、P1=15 / P2=51 / P3=59 |
| C | partial 5 銘柄を 5 並列 agent で IR 補完 | **3 件 available 化** (4751/4755/7453)、2 件 IR に該当 KPI なしで partial 維持 (2433/9449) |
| D | monitoring 設定拡張 | 方針修正のため Phase 21 へ送り |

available 銘柄 **120 → 123**。catalog audit / ruff 全て緑、regression なし。

## 重要な技術発見

- `analytics.business_model_coverage_backlog` は既に 4,066 銘柄登録済 (suggested_template 割当 2,000)。`analytics.v_business_model_panel_health` view は backlog を `suggested_template` で集約 → 「40 panel」は template 種類数
- ad_supported framework の available 条件 = `metrics_count >= 2 AND has_segment_groups` (`tools/api/decision_api/serving/company/business_model/_frameworks/ad_supported.py`)
- ad_supported metric_key alias = ad_revenue / cpm / cpc / impressions / clicks / advertisers / dau / mau (`_ad_metrics.py::_AD_METRIC_ALIASES`)
- 同一 metric_key を 2 行投入しても metrics_count は重複排除で 1 のまま (loader 仕様)
- 169 銘柄中 5 件 (2374/4745/8606/9085/9613) は最新 JPX snapshot に不在 = 上場廃止疑い。probe で no signal、Stream B agent の所見と完全一致

## Phase 21 申し送り

詳細は `docs/worklogs/20260517-phase20-probe-expansion.md` の「残課題と次フェーズへの申し送り」セクション。要点:

1. Stream D 再設計: SAMPLE_MAPPINGS 169 銘柄ベースの週次 probe を `run_manifest.yaml` に追加
2. Stream B P1 15 銘柄の新規 sample 投入 (鉱業 1050 / 繊維 3100 / パルプ 3150 / 非鉄 3500 / 倉庫 5200 / その他金融 7200)
3. Tier 2 partial-only 39 銘柄の sample 投入 (Phase 5/6/7 と同パターン)
4. 5 銘柄上場廃止疑い (2374/4745/8606/9085/9613) を SAMPLE_MAPPINGS から削除 + sample JSON archive
5. 2433 博報堂を ad_supported → advertising_holding pack へ dispatch 改善 (総合広告代理店は財務 KPI のみ開示)
6. 4751 CyberAgent の MAU/WAU 整合: 現在 ABEMA WAU を `mau` に下限格納、本来は WAU 専用 metric_key を pack 追加

## 関連: [[project-business-model-phase19-2026-05-17]] [[project-business-model-aggregator-closeout-2026-05-14]]
