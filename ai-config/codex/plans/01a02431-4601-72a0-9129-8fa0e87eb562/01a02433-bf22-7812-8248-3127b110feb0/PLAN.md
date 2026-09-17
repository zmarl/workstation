# 変更別証明パック型テストゲート／開発ハーネス改革

## Summary

- 調査基準は2026-08-21、cleanなmain `30879dc7…`。直近T3は51〜74分（中央値54分51秒）で、87〜92%を全Python回帰が占める。Readyは直近9件の中央値2分08秒。
- PRごとの単一T3を廃止し、変更が壊し得る振る舞いだけを検証する「証明パック」方式へ移行する。通常は3分目標・10分上限、長い検証だけ非同期でmerge前必須とする。
- 全域回帰はPRゲートではなく、週1回と選択器変更後の非同期監査に限定する。失敗時は影響領域だけ停止し、runner・選択器・未分類の破損だけ全体停止とする。

## 1. ガバナンスと移行順序

- 外部資料をhash付きでresearch registryへ登録し、Full worklogに「採用・変更採用・不採用」の適合表を作る。後発決定により、旧financial-invariants hardening案・同AST cache案・Linux移設案は採用しない。
- 重複しているODR採番を是正し、2026-08-17の金融ゲート退役を`ODR-0012`、本改革を`ODR-0013`とする。新ODRは既存ローカルPRゲート決定を改訂し、次を明文化する。
  - PR前の全域回帰を廃止し、変更別証明を品質判定の正本にする。
  - 高速化だけを目的とするテスト削除は禁止するが、重複・廃止済み仕様・終了条件を満たした一時テストは根拠付きで削除する。
  - latest-base、clean exact-head、独立review、共有DB・本番等の人手境界は維持する。
- 中核切替はrunner排他の1 PRにまとめ、旧T3をclean exact-headで非同期実行するのは原則この1回だけとする。その後は新しい証明パックで、Control Tower、定期監査、個別最適化を別PRとして進める。

## 2. 証明パックとテスト寿命

- 既存の変更選択台帳を、`harness-docs`、`runner-core`、`test-infra`、`python`、`db-txn`、`db-fresh`、`migration`、`bff-contract`、`desktop`、`desktop-release`、`rust`、`audit-full`等の安定したパックIDへ再構成する。
  - AGENTS・説明中心のskillsは文書／role／stub同期だけ。
  - runner変更は選択器・証拠・process隔離の契約テストと代表canaryだけで、製品全回帰を行わない。
  - migrationはAlembic・baseline/head・影響DBテストだけ。
  - BFFはAPI・型生成・該当Desktop契約を検証し、無関係な全VitestやDB全体を起動しない。
  - 未知pathはT3へ逃がさず`classification_required`で停止し、影響関係を登録するまでmerge不可とする。
- 呼び出し側の`--scope`は引き続き追加専用とし、必要検証を省略できない。rebase後は証拠を複雑に再利用せず、必要パックだけ短時間で再実行する。
- 恒久テストは振る舞いを守る限り維持する。一時的な移行・互換・障害回帰テストには`review_by`と`remove_when`を持つmarkerを必須化し、期限超過を赤にする。
- テスト本数は傾向として記録するだけで固定ratchetにしない。パック別実行時間は予算超過を赤とし、予算更新には理由を要求する。新規テストは既存parametrize／fixtureを優先し、重複追加をworklogで説明させる。

## 3. 実行・証拠・ハーネス

- `run_local_pr_gate`は`ready`と`audit`へ整理する。旧`t3`は一時的に`audit`のaliasとして警告付きで残し、週次監査4回連続成功・repo内callerゼロ・2026-09-30以降を満たしたcleanup PRで削除する。
- Readyは全体600秒のhard timeoutと30秒heartbeatを持つ。10分を超える可能性のあるpackは対話中に開始せず、`pending_async`として専用キューへ送る。
- heavy検証キューはホスト全体で同時1本とする。jobには任意コマンドを保存せず、exact base/head、選択digest、承認済みpack IDだけを持たせる。detached runnerを正規helperでclaimし、peer processを停止せず、成功・失敗・timeout・crash recoveryを記録する。
- evidenceをschema v4へ上げ、`head/run_id`単位のappend-onlyにする。同一SHA再実行でも上書きせず、pack、lane、収集数、collection／DB準備／baseline時間、slow test、queue待ち、timeout、選択digest、cold/warm条件を保存する。成功詳細ログは30日、失敗ログは90日、集計値は180日保持する。
- merge helperは、現在のselectorが要求する全packについてexact base/head・選択digest一致の成功証拠を検証する。長いpackがpendingなら該当PRだけmergeを拒否する。
- 通常Codexは`gpt-5.6-sol/xhigh`へ戻し、Planもxhigh、Max/Ultraは一時選択のみとする。repo-local subagent上限4と外部セッション数は維持し、重い検証だけ1本に制限する。Claudeの編集後lintは計測し、p95が2秒を超える場合だけdebounce化する。
- DB template化、DB lane並走、worker数変更、static cacheは計測後に個別導入する。同一SHA・3回中央値で20%以上改善し、収集node・結果・DB隔離が完全一致した案だけ採用する。`-n auto`は決め打ちしない。

## 4. 定期監査とControl Tower

- 全域監査は週1回と、selector／runner変更のmerge後に実行する。通常時刻はScheduler負荷の最小90分枠から選び、同率なら日曜02:00 JSTを使う。
- 失敗したテストを証明パックへ逆引きし、その領域だけmerge停止する。runner・selector・evidence verifier・未分類失敗は全体停止、ホスト障害やtimeoutは該当jobだけ停止とする。既知の一時的インフラ障害だけ同一SHAで1回再試行し、両方の証拠を残す。
- BFFにread-onlyの`GET /api/v1/ops/verification-status`を追加する。`queued/running/passed/failed/timed_out/stale`、job種別、pack、base/head、時刻、所要時間、停止領域、短い失敗要約を返す。
- Desktop Operationsに「開発検証」パネルを追加し、最新監査、待機中の長い検証、失敗領域を平易な日本語で表示する。Desktopから証拠ファイルへ直接アクセスさせず、再実行ボタンや外部送信は追加しない。
- manifestソースと登録パックまでは実装するが、Windows Schedulerへの実登録は別の明示承認とUAC操作まで行わない。Discord依存は追加しない。

## 5. 検証と完了条件

- 過去30件以上の実diffと、docs、runner、conftest、migration、BFF契約有無、shared、release、未知pathの合成ケースで選択結果を固定する。必要packの欠落を意図的に作るmutation testが必ず赤になることを確認する。
- Ready代表10ケースの中央値が3分以内、全ケース10分以内。timeout時は所有する子processだけを終了し、DB・worktree・job状態を安全に回収する。
- 非同期packはexact SHAで1本ずつ動き、agentが完走を監視し続けず、pending／pass／failがmerge helperとControl Towerで一致する。
- 週次監査は全恒久テストを収集し、最終目標30分以内。一時テスト期限、重複候補、未選択test、slow testをレポートする。
- Control TowerはPC幅・狭幅、空、待機、実行中、成功、領域失敗、全体停止をテストし、BFF-only境界とアクセシビリティを確認する。
- global/repo双方のCodex role検査とClaude role検査をgreenにし、中核切替PRだけ旧T3、以後は新selectorが要求するpackでexact-head gateを通す。
- Defender除外は変更しない。計測上15%以上の改善余地が示された場合だけ、対象限定・可逆手順を別承認案として提示する。Linux移設、共有DB、本番、実通知、Desktop配布も本改革の自動実行対象外とする。
