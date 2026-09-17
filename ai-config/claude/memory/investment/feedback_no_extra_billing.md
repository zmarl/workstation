---
name: feedback-no-extra-billing
description: サブスクリプション外の課金（extra usage / 従量クレジット / 有料クラウド機能）を発生させない (2026-07-19)
metadata: 
  node_type: memory
  type: feedback
  originSessionId: d0642d87-557f-4e18-bbd9-e124ba0956b9
  modified: 2026-07-19T05:48:31.745Z
---

ユーザーはサブスクリプション範囲内のみでの利用を望んでおり、サブスク外の課金を一切発生させたくない (2026-07-19 指示)。

**Why:** 使用中に「クレジット利用」らしき表記が一瞬見え、サブスク外課金を懸念したため。

**How to apply:**
- 追加課金される機能（例: `/code-review ultra` = ultrareview のクラウドレビュー等、billed と明記されたもの）は自分から実行・提案しない。実行はユーザー起点のみで、その際も課金される旨を先に伝える。
- 大量トークンを消費する多エージェント並列（ultracode / Workflow 大規模 fan-out）は、サブスク上限超過→overage 消費につながり得るため、必要性に見合わない過剰並列は避ける。
- 確実な遮断はアカウント側設定: claude.ai の Settings → Billing/Usage で「Extra usage（上限超過時の追加購入）」をオフにするようユーザーに案内済み。使用状況は Claude Code 内 `/usage` で確認可能。
