---
name: Industry Tier Inference (Wave E)
description: 自動車・電子・産業機械 3 業界の Tier 1-4 chain を YAML カタログ + コードベース推定 inferer で表現する Wave E の実装ポイント
type: reference
originSessionId: 4e10e725-9fbf-4a7b-bb97-0cdc170ba478
---
# Industry Tier Inference (Wave E)

## 概要

ビジネスモデル図解の supply-chain で Tier 1 (OEM 直接取引先) しか持たなかった情報を、Tier 2-4 まで自動推定。3 業界カバー。

## 実装ファイル

- カタログ: `tools/analytics/business_model_frameworks/industry_tier_chains.yaml`
- 推定: `tools/analytics/business_model_frameworks/tier_inferer.py` (公開関数 `infer_tier_chain`)
- テスト: `tests/analytics/business_model_frameworks/test_tier_inferer.py` (19 cases)

## カバレッジ

| industry | tier1 anchors | tier2 | tier3 | tier4 |
|---|---|---|---|---|
| automotive | 7 (7203/7267/7269/7270/7261/7201/7211) | 8 | 6 | 4 |
| electronics | 7 (6758/6752/6502/6701/6702/7751/7752) | 7 | 6 | 4 |
| industrial_machinery | 7 (6301/6326/6273/6367/6361/7011/7012) | 6 | 5 | 4 |

確度 A-B 相当の有名関係のみ (デンソー / アイシン / 村田 / 京セラ / THK 等)。

## 既存実装との住み分け

`shared/catalogs/tier_inferer.py` (既存) は **keyword/role-label ベース** ("素材・部材" 等の汎用ラベル)。
今回新設の `tools/analytics/business_model_frameworks/tier_inferer.py` は **コードベース** (具体的 4 桁ティッカー)。意図的に並存。

## API

```python
from tools.analytics.business_model_frameworks.tier_inferer import infer_tier_chain

result = infer_tier_chain("7203", depth=3)
# => {"anchor": "7203", "industry": "automotive", "tiers": {"1": [...], "2": [...], "3": [...]}}
```

- `depth` は 1-4 にクランプ
- 未知 anchor → `{"anchor": code, "industry": None, "tiers": {}}` で例外なし
- `industry` 明示指定で曖昧 anchor を強制解決可能

## 未配線

BFF endpoint への配線は **未着手**。`tools/api/decision_api/serving/company/business_model/_frameworks/` 配下 13 builder のいずれも `tier_depth` を受けない構造のため、Wave E では Skip。次セッションで supply-chain 系 endpoint への parameter 追加または専用 endpoint 新設の判断が必要。
