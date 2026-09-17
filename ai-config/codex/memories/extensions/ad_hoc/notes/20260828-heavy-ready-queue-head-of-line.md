# Investment heavy Ready queue の直列化問題

- 2026-08-28、host-wide heavy queue で `full_audit` 1件が実行中の間、別PRの `ready_async` 2件が待機した。後者のうち1件はQwen3.8-27B決算エージェント統合のmerge必須証跡だった。
- 現行はジョブ単位でhost同時1本のため、統合を止めない全域監査が、統合を止めるReadyを非プリエンプティブに先頭ブロックする。複数セッションが並行開発しても、最終段階だけ完全に直列化される。
- 影響は単なる待ち時間ではない。待機中にmainが進むとexact base/headを作り直す必要があり、完了済み同期検査も再実行になり得る。開発並行数を増やすほど、最終統合の待ち行列と再検証が増える。
- 既存 `docs/backlog/20260824-harness-gate-gaps.md` はhost同時1本と、混雑時に監査結果書出しが失敗して約69分を失った事象を記録済み。ただし、非merge用auditによるmerge必須Readyのhead-of-line blockingと、複数Readyの並行処理不足は独立ギャップとして追記が必要。
- 過去にDBレーンを別process・別ローカルPostgreSQLコンテナで並行化する候補commit `441139345f9aac5b6a60417e47518a35252ba800` があるが、旧方式3回・候補3回の同一SHA実測、検査同値、cleanup同値、20%以上の中央値短縮を未確認で未採用。
- 改善の優先順は、(1) Readyをauditより優先しauditをphase境界で譲歩可能にする、(2) ジョブ丸ごとではなくproof packごとのresource classで実行する、(3) CPU/RAM枠、DB/container枠、evidence publish lockを分離し、安全なReady packを2本以上並行化する、(4) 同一SHAの旧方式/候補方式を各3回測定して採否を決める。
- Qwenの現在のexact headを変えて再検証を増やさないため、正式backlog追記はQwen統合後に専用worktreeで行う。
