thread_id: 019ff4ed-d5c6-7793-be64-a84b3f0b7f23
updated_at: 2026-08-14T15:00:15+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\12\rollout-2026-08-12T16-44-15-019ff4ed-d5c6-7793-be64-a84b3f0b7f23.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# 現行リポジトリと外部調査報告を照合し、実装方針を整理したが、変更は行わなかった

Rollout context: `D:\Dev\Investment`。ユーザーは、Downloads の「拡充調査レポート v3」と「機能目的台帳」を現行コード・正本文書と照合し、課題を事実／未確認／提案に分けたうえで、今後の更新方針へ落とし込むことを依頼した。Plan Mode のため読み取り専用で進めた。

## Task 1: 外部報告書と現行リポジトリの照合

Outcome: partial

Preference signals:

- ユーザーは「現在のリポジトリを調査した上で」報告書の課題・方向性を反映するよう求めており、静的報告書をそのまま採用せず、現HEAD・正本文書・実DB等へ再照合する進め方が適切。
- `OWNER_INTENT.md` は「正確性 > 速度」「根拠と時点のない数値・主張を判断に混ぜない」「結論先出し・平易な日本語」を明記しているため、今後も根拠・時点・検証状態を分離して報告する必要がある。
- ユーザーは実装を急がず、まず調査・方向性整理から始める依頼をしており、今回のような大規模変更では先に計画と承認事項を提示し、勝手に編集しないのが望ましい。

Key steps:

- Matt Pocock Skills の `research` と `codebase-design` を読み、根拠付き調査、deep module、interface、seam、adapter、locality の語彙を確認。
- `docs/OWNER_INTENT.md`、`docs/guides/development-harness.md`、ODR-0001、次アクション台帳、git履歴、現行manifest・コード・テストを読み取り。
- 報告書 v3 と機能目的台帳を読み、現HEAD（2026-08-11時点）との差分を意識して評価。
- 調査を報告書、repo inventory、意図・履歴、重要リスク実装の系統に分けて並列化。

Failures and how to do differently:

- PowerShell の複雑な引用や日本語パスを `exec` のJSラッパーから渡した際、harness が「Use the harness PowerShell directly」と拒否した。今後はコマンドを小さく分け、直接PowerShell形式・単純な単一パス指定を優先する。
- 報告書の主張には静的スナップショット（main ≒ 2026-08-02）由来のものがあり、自動回復などは8月10日の修正で契約が変わっていた。古いレポートの数値や課題を現状事実として扱わず、必ず現HEADと正本文書で再検証する。
- 並列調査は有効だが、最終判断は親が統合し、読み取り専用 explorer と writer の境界を守る。Plan Mode では報告書生成・コード変更を行わず、実装フェーズの保存先・承認点だけを計画する。

Reusable knowledge:

- 正本文書の入口は `docs/OWNER_INTENT.md`、`docs/README.md`、`docs/decisions/20260810-owner-direction-2026q3.md`、`docs/backlog/次アクション管理台帳.md`。外部資料は `docs/research/registry.yaml` の external entry で追跡し、本文を重複コピーしない方針。
- ODR-0001 の恒久優先順位は、(1) DecisionCase の共有DB適用→shadow並走、(2) 意図管理の定着、(3) 保守面積削減・BFF/DB復旧実測。新機能追加より決算閉ループ実運用が優先。
- 恒久境界: 発注・資格情報・外向き発注通信は扱わない、Desktop は FastAPI BFF `127.0.0.1:8010` のみ、DB変更は Alembic のみ、LLMは補助限定、旧経路はshadow/rollback/restore証拠まで削除しない、ETF/ETN/REIT/投信は除外。
- DecisionCase はコード・Alembic・BFF経路まで実装済みだが、ODR-0001 と台帳上、共有DB未適用で実働ゼロ。適用は人手承認境界で、正式昇格はshadow実績後。
- 現行repo inventory（調査時点）では Python入口314件、BFF endpoint契約551件、Scheduler active 282等が生成snapshotに記録されている。ただしsnapshot自体の鮮度を確認してから利用する。
- 報告書の重要候補は、T-stop照会キー、side判定、p*表示誤記、R.2サイズ計算の文書・実装乖離、品質ゲート外のIFIS/JPX需給、分割後価格履歴、バックアップ実効性、自己評価ループのテスト不足。ただし主要なものは実DB・実運用値の確認が必要。
- 報告書 v3 の「ルール台帳」「決断カーネル」「運用実効化」「自己評価テスト」「目的台帳生成物化」は提案であり、ODR承認・既存正本との移行設計なしに実装へ進めない。特に新規 `rule_parameters.yaml` 案は「重複正本を作らない」という機能目的台帳方針と整合させる必要がある。
- 機能目的台帳のユーザー確定方針: アルファの統一原理は「市場の評価と実態のギャップ」、IIPはシリコンサイクル分析、決算ラベルは実リターンで正式検証、purpose-gate群は承認基準を設ける、政策インテリジェンスは保有・監視銘柄への影響アラートへ再設計、Monex Scouterは代替検証後に縮小、台帳はレジストリから生成する。

References:

- `C:\Users\kazum\Downloads\拡充調査レポートv3_2026-08-10.md`
- `C:\Users\kazum\Downloads\機能目的台帳_2026-08-11.md`
- `docs/OWNER_INTENT.md`
- `docs/decisions/20260810-owner-direction-2026q3.md`
- `docs/backlog/次アクション管理台帳.md`
- `docs/research/registry.yaml`
- `docs/guides/development-harness.md`
- `docs/current/generated-repository-snapshot.json`
- 最終作業ツリー確認: `git status --short --branch` → `## main...origin/main`（変更なし）

## Task 2: 重要な運用・証拠境界の調査（別続行部分）

Outcome: partial

Key steps:

- 後半では scheduler recovery canary の reference-only 証拠実装を別worktreeで反復検証し、production apply・DB・Scheduler登録・通知を hard-stop のまま維持。
- 最終候補として複数SHAが生成されたが、途中でwriter差分が入りレビュー対象が無効化されたり、usage limitで実装agentが停止したりしたため、最終的なproduction-ready完了とは扱えない。

Failures and how to do differently:

- clean exact SHAを凍結した後にwriterを動かしたため、独立レビューが「同時編集でexact対象を維持できない」と停止した。今後はレビュー開始後にwriterを絶対に動かさず、変更は別ブランチ・別SHAで再検証する。
- reference evidence は、source authenticity を検査する前にrepo source自体を実行する問題、外部trust anchor未配備、ACL race等が指摘された。現コードに危険呼出しがないことと、検証器が将来の変更を安全に拒否できることを分けて評価する。

Reusable knowledge:

- production apply、Scheduler登録、DB接続、通知は明示承認と外部trust anchorがない限り fail-closed を維持する。
- 「テストがgreen」「evidenceが存在する」だけではproduction権限の証明にならない。execution closure、source authenticity、ACL、seal、runtime provenance、実副作用ゼロを独立に検証する。

References:

- 後半の作業は主repoではなく `D:\Dev\Investment-pr5-scheduler-recovery-canary` の別worktreeで実施された。最終候補として `6137c398...` 等が報告されたが、独立レビューではsource authenticityのpre-import問題が残存課題として指摘された。
