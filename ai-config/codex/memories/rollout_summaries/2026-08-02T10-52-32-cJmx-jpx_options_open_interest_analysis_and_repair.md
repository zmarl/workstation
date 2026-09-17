thread_id: 019fc21a-9de8-7742-abfe-e153f09f55d9
updated_at: 2026-08-12T08:35:58+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\08\02\rollout-2026-08-02T19-52-32-019fc21a-9de8-7742-abfe-e153f09f55d9.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: codex/jpx-oi-legacy-coverage-repair-20260812

# JPXオプション建玉の週次取得・分析機能を調査、修復、検証し、mainへ統合した

Rollout context: `D:\Dev\Investment`。JPX公式のオプション建玉を自動取得し、前回比・観測可能な変化・推測限界をアプリに反映する作業。実装は読み取り調査、別worktree、独立レビュー、exact-head gate、PRマージ、実DB再取得まで実施された。

## Task 1: JPX建玉データ仕様と分析方法論の調査

Outcome: success

Preference signals:

- ユーザーは「どのようなデータ取得を行い、どのようにアプリ上に反映するのかというのをあらゆる調査をした上で」実装するよう依頼したため、今後も外部データ契約・更新時刻・利用条件・既存アプリ経路を先に調査し、実装判断を明示するのが適切。

Key steps:

- JPX公式ページを確認。取引参加者別建玉は前週末日中取引終了時点を毎週第1営業日15:30頃に更新。日次のデリバティブ建玉残高表は通常20:00頃に掲載。
- JPXサイト利用条件を確認。商用目的のデータ収集・二次利用には契約または許可が必要で、公開情報は投資勧誘目的ではない。
- 週次参加者別建玉と日次銘柄別建玉は母集団・粒度が異なるため、合算・直接比較しない設計にした。
- 公開OIだけでは買い手／売り手の主導、相場方向、ディーラーのネットガンマ、支持線・抵抗線、SQ着地点を断定できない。UIでは「観測事実」と「推測できないこと」を分離する方針。

Reusable knowledge:

- OIは未決済契約の残高であり、`ΔOI` は純増減までしか示さない。
- 建玉集計キーは商品×Call/Put×SQ日×行使価格×観測日時。通常日経225、ミニ、異なる満期曜日・SQ日は混在させない。
- PCRは対象範囲を明示し、方向判定には使わない。欠損・分母ゼロは算出しない。
- 満期・SQ週のOI減少には満期消滅や限月移行が含まれるため、手仕舞いや見通し変化と解釈しない。
- 新設行使価格・満期消滅・通常のゼロ・取得失敗は別状態にする。欠損をゼロ埋めしない。

References:

- JPX参加者別建玉: `https://www.jpx.co.jp/markets/derivatives/open-interest/`
- JPX日次建玉: `https://www.jpx.co.jp/markets/derivatives/trading-volume/`
- 作業計画: `docs/worklogs/20260810-jpx-options-open-interest-analysis.md`

## Task 2: JPX公式帳票の過剰な完全性判定を修正

Outcome: success

Key steps:

- 2026-05-22公式ファイル `20260522_nk225op_oi_by_tp.xlsx` を調査。Put側が空欄の正規順位表で、parserは67件の非空候補を正しく生成していたが、各ストライクにCall/Put×net-long/net-shortの4組合せを要求するcoverage判定が失敗原因だった。
- 最初の修正では組合せ検証を削除しすぎて未知値を通すfail-openが判明。独立security/correctness reviewで検出し、追加修正した。
- 最終修正は、ストライク単位の空組合せは許容しつつ、観測全体では許可された4組合せを必須化し、未知の`option_type`/`net_direction`をcollectorとBFFの両方で拒否。失敗時はBFFの数値・差分・参加者ランキングを完全マスク。

Reusable knowledge:

- 変更箇所:
  - `tools/market_data/jpx_participant_open_interest/coverage.py`
  - `tools/api/decision_api/serving/market/_options_open_interest_quality.py`
  - `tests/tools/market_data/test_jpx_participant_open_interest.py`
  - `tests/tools/api/serving_repository/test_nikkei225_options_open_interest.py`
- 最終コードSHA: `c8ca696e9eaca9677fcd748e16ce994e3db3f436`。後続worklog凍結SHAは`064935e1732dfbad021f95d57585feb4fa5dbc33`。
- 最終focused testは`59 passed`、最終Ready Gateでは関連テスト・DB-focused test・Ruff・型生成・Desktop API境界・静的検査が全てpass。
- 公式05-22帳票の実測: 33,080 bytes、67 records、150 rank slots、candidate=record=67、invalid=skipped=0。

Failures and how to do differently:

- 4組合せ必須を無条件に各ストライクへ適用すると、公式の「参加者なし」空欄を欠損と誤判定する。
- 逆に組合せ判定を全面削除すると未知値が`ok`になり得る。空欄許容はストライク単位に限定し、全体の許可集合・未知値検証をcollector/BFF双方に残す。

References:

- 初回失敗エラー: `coverage index option combinations mismatch: 63625.0`
- PR: #171 `https://github.com/zmarl/Investment/pull/171`
- 成功runlog: `logs/runlogs/jpx-participant-open-interest-weekly-20260812-173228-474-538c79cc.json`

## Task 3: Exact-head gate、PRマージ、週次再取得とBFF確認

Outcome: success

Key steps:

- Ready Gateをbase `0936fd4a3da2b5772738329118f59b91b0b4cc18`、head `064935e1732dfbad021f95d57585feb4fa5dbc33`で実施。overall `passed`、clean before/after、skipなし。evidence SHA256は`680f562022c2c96e9f1cdad5e2888c1606b11b61646b9347e7ac36195c283b1e`。
- PR #171をSHA固定で公開・マージ。merge commitは`3957c41e280eac5c25c0a1ee23de9486b2bdb8cd`。mainとorigin/mainが一致しclean。
- `.\scripts\run_tool.ps1 -TaskId jpx-participant-open-interest-weekly -TriggerSource manual`を実行。run status success、state buildもsuccess。
- 再取得後、完全判定日は`2026-05-22`, `2026-07-31`, `2026-08-07`。派生state 120行＋cross-market 120行を構築し、raw lineage一致を確認。
- BFF結果: weekly=`ok`、2026-08-07対2026-07-31の7日比較。Call公表行合計788→2380、Put1500→3588、上位参加者変化20件を返却。対象ストライクは入れ替わっているため方向判断には使わない。
- Dailyは旧形式の2026-08-07 metadata欠落により`partial`、数値・差分をマスク。新しいmetadata完全な日次観測が2件揃えば自動回復する。
- Scheduler `\Investment\JpxParticipantOpenInterestWeekly` は月〜金16:00、hidden PowerShell wrapper、パスワードログオンで登録済み。今回対象タスクのXMLは確認済み。

Failures and how to do differently:

- 旧日次URLが404のため、欠損値を補完せず安全に`partial`表示を維持した。未来のlookback取得で回復させる。
- Scheduler全体には既存driftが71件あるが、今回のJPX週次タスクには影響せず、対象XMLだけを照合した。

References:

- 成功runlog: `logs/runlogs/jpx-participant-open-interest-weekly-20260812-173228-474-538c79cc.json`
- 最新main SHA: `3957c41e280eac5c25c0a1ee23de9486b2bdb8cd`
- Scheduler task: `JpxParticipantOpenInterestWeekly`

