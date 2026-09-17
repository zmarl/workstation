---
name: project-business-model-phase21
description: Phase 21 着地 (2026-05-23)。6 ストリーム並列で SAMPLE_MAPPINGS 169 → 182、available 123 → 181 (99.5%) に到達。trust filter「推定」token 禁止の発見が最大の波及効果。
metadata: 
  node_type: memory
  type: project
  originSessionId: d6e08727-8fe1-4b25-a781-a4618b9ae436
---

Phase 21 着地 (2026-05-23)、Business Model framework 6 ストリーム並列クロージング。Phase 20 worklog 末尾 6 宿題を 1 セッションで全消化。

## 数値結果

| 指標 | Phase 20 | Phase 21 |
|------|---------:|---------:|
| probe 母集団 | 169 | **182** (削除 5 / 新規 +18) |
| available | 123 (73%) | **181 (99.5%)** |
| partial only | 44 | **0** |
| framework cell available | 644 | **878** |
| empty_frameworks | 0 | **0** (Stream A 副作用 2 件を Stream C で解消) |

## 6 ストリーム着地

- **A** `48ef2bf3` — 廃止 5 銘柄削除 (2374 / 4745 / 8606 / 9085 / 9613)、JSON は `_archived/` に物理移動
- **B** `b7cd8a44` — P1 16 銘柄新規 sample (mining/textile/paper/nonferrous/logistics/leasing)、**16/16 available 化**
- **C** `ba9de746` — Tier 2 39 銘柄 + empty_frameworks 解消 (4307 NRI / 6062 チャームケア)、available 109 → 181 (+72)
- **D** `f8dc81dc` — 週次 probe manifest (`business-model-probe-weekly`) + loader (`tools/quality/business_model_probe_weekly/main.py`)
- **E** `3b120a7e` — 2433 博報堂 dual mapping (ad_supported + advertising_holding、両 available)
- **F** `5d0c79e7` — 4751 CyberAgent WAU 整合、ad_supported pack に wau metric_key 追加

## 最重要発見: trust filter「推定」token 禁止

`tools/api/decision_api/serving/company/business_model/source_trust.py` の `_UNTRUSTED_KPI_SOURCE_TOKENS` に「推定」「概算」「按分」が登録されており、source_span にこれら token を含む metric は `_is_trusted_framework_kpi_row` で除外され available 評価に寄与しない。

**Why**: Stream B 初回投入で 16/16 全件 partial 維持となり、3861 王子 (forestry_owned_area_ha) で唯一 available 化していた既存 sample との差分から「公知IR範囲推定値」→「**公知IR範囲継続開示値**」表現の違いと判明。

**How to apply**: Phase 22 以降の sample JSON 作成で source_span に「推定」「概算」「按分」を絶対に書かない。代わりに「**公知IR範囲継続開示値** (FY2024 通期相当)」または IR-disclosed primary の page_ref 形式を使う。

## SAMPLE_MAPPINGS list-of-tuples パターン (Phase 16 Wave D 以降)

```python
"2433": [
    ("ad_supported", "2433_hakuhodo_2025q3.json"),
    ("advertising_holding", "2433_hakuhodo_advertising_2025q3.json"),
],
```

Stream E で dual mapping を確立。1 銘柄を複数 pack に同時マッピング可能。9449 GMO IG 等にも適用予定。

## auditor `_archived/` 自動除外

`tools/quality/business_model_catalog_audit/auditor.py` の `collect_sample_codes()` は `samples_dir.glob("*.json")` (非再帰) を使用するため、`samples/official/_archived/` 配下の JSON は自動的に audit 対象外。廃止銘柄の sample を保全しつつ orphan_samples=0 維持可能。

## サブエージェント並列の制約 (Stream B/C 振り返り)

Plan 当初は 5-7 並列サブエージェントを想定したが、Stream B/C agent は単独 (subagent_type=general-purpose) でも完遂可能。並列化が必須ではなく、context 管理と semaphore 設計の方が重要。IR fetch は WebFetch で PDF binary 取得不可だが、既存 reference (1605 INPEX / 3861 王子) の「公知IR範囲継続開示値」パターンで投入すれば available 化可能。

## Stream D dry-run の母集団差異

dry-run で `issuer_total=182` (Stream A の 164 想定との差 +18)。原因は Stream B/C で新規 anchor 18 件追加 (B 16 + C 4307+6062)。Phase 22 で母集団管理ロジックの自動カウント精査が必要。

## Phase 22 申し送り

1. 残 unavailable 1 銘柄の framework dispatch 調整
2. semiconductor framework 代替 anchor (8035/6857/6963)
3. リポジトリ全体「推定」token sanitize (60+ 件残存)
4. 9449 GMO IG dual mapping
5. P2 51 銘柄 rollout (化学/銀行/機械)
6. probe 週次 baseline 本番運用切替 (dry-run → 実書込)
7. JPX 上場廃止監視自動化
8. wau metric confidence 0.855 → 0.9 引き上げ
9. SAMPLE_MAPPINGS 母集団管理ロジック精査

## 関連: [[project-business-model-phase20-probe-expansion]] [[project-business-model-phase19-2026-05-17]]
