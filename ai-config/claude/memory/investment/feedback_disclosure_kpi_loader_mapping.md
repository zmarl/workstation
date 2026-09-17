---
name: disclosure_kpi loader の SAMPLE_MAPPINGS は samples/official 追加に追随必須
description: pack YAML 編集だけでは confidence は上がらない。samples/official/*.json 追加と loader の SAMPLE_MAPPINGS 拡張をセットで行う必要がある
type: feedback
originSessionId: 4e10e725-9fbf-4a7b-bb97-0cdc170ba478
---
# disclosure_kpi loader の SAMPLE_MAPPINGS 追随

**Rule**: `tools/analytics/disclosure_kpi_extractor/samples/official/*.json` に IR 公式値を追加するときは、`scripts/load_disclosure_kpi_samples.py` の `SAMPLE_MAPPINGS` 辞書も同時に更新する。

**Why**: 2026-05-10 の Wave D Phase 3 confidence 上書き作業で、`samples/official/` には 12 ファイル分の IR 公式値が既に揃っていたが、`SAMPLE_MAPPINGS` が追随していなかったため、loader 実行時に対象銘柄が認識されず confidence が上がらない状態が放置されていた。pack YAML を見ても気付かない (gap は loader 側)。

**How to apply**:
- 新規 `samples/official/<name>.json` 追加時は **必ず** `scripts/load_disclosure_kpi_samples.py` の `SAMPLE_MAPPINGS` を grep してエントリ追加
- pack 自体に IR 値を追記するのではなく、samples ファイルを介して loader が DB に投入する設計のため、loader を経由しないと反映されない
- 対象銘柄に既に placeholder データ (`source_span` に「サンプル値; 後で IR 公式値で再投入」と明記) がある場合は DELETE してから INSERT （4568 ケース）

## 関連
- worklog: `docs/worklogs/20260510-business-model-phase5-landing-multistream.md` (Stream C 報告)
- 該当 commit: (TODO) このセッション
