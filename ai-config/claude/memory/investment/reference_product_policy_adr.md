---
name: 商品ポリシー ETF 除外 ADR
description: ETF/ETN を商品から除外する方針で停止した機能群の恒久停止宣言 ADR。US Market Pulse / Benchmark Proxy Collector / Opportunity Cost / Safe Haven を包括
type: reference
originSessionId: 1c5a8336-52b6-4f3a-bc98-466fa9c828b1
---
ADR 本体: `docs/decisions/product-policy-etf-exclusion.md`（2026-04-18 作成、Status: Accepted）

**カバー範囲**:
- US Market Pulse（スケジューラ disabled + HTTP 410 Gone）
- Benchmark Proxy Collector（スケジューラ disabled）
- Opportunity Cost（feedback_loop のサブコマンドを `OPPORTUNITY_COST_DISABLED_REASON` で停止応答）
- Safe Haven（コード自体は既に削除済み）

**再開条件**:
1. 事業ポリシーとして ETF/ETN 除外が解除される
2. 非 ETF データで同等指標を再構築でき、代替実装が承認される（Superseding ADR が必要）

個別機能を暫定再開することは禁止。`run_manifest.yaml` の該当 disabled_tasks の restore_condition は本 ADR を参照している。

**利用シーン**:
- ETF 関連の機能追加要望 → この方針に抵触しないか確認
- 米国市場データ / ベンチマーク機能の議論 → 現行ポリシーを踏まえた提案が必要
- 停止機能の再開判断 → US Market Pulse 等は事業判断が前提
