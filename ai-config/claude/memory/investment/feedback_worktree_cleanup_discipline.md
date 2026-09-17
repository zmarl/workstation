---
name: worktree-cleanup-discipline
description: 作業終了後の worktree/branch 整理を毎回徹底する（2026-08-28 にオーナーが強い不満を表明。何度も指示済みとのこと）
metadata: 
  node_type: memory
  type: feedback
  originSessionId: cee7513f-74ae-4293-9650-eb9e82ec8684
  modified: 2026-08-28T04:01:03.482Z
---

2026-08-28、実測で worktree 21本・branch 287本の残存を報告した際、オーナーは「作業が終わったら整理するというのを徹底してほしい。何回も指示しまくってるんだけど、全然聞いてくれない」と強い不満を表明した。

**Why:** ODR-0018 は同時書込 worktree を main + 3本までと定めるが、セッションが finish-pr の後片付けを省略して終わるため残骸が蓄積し続け、生成物の再生成競合や claim 外残骸の温床になっている。

**How to apply:** タスクがマージまで到達したら、ExitWorktree → main checkout からの finish-pr → worktree/branch が消えたことの確認までを、そのセッションの完了条件に必ず含める。マージに至らず終わる場合も、自分が作った worktree の処遇（継続 / 破棄）をセッション終了前に明示し、破棄なら実際に消す。定期的な残骸棚卸しセッションの提案も歓迎される。関連: [[parallel-session-worktree]]
