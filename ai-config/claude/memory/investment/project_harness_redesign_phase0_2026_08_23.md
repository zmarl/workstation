---
name: project-harness-redesign-phase0-2026-08-23
description: "ハーネス再設計 Phase 0 着地 (08-23, PR #207/#208/#209)。ODR-0018 Proposed・KPI 基準値・tests/scripts 赤 0。ODR-0017 証明パック gate の非同期 runner 欠陥 2 件と新 gate の罠"
metadata: 
  node_type: memory
  type: project
  originSessionId: 3f6c93bb-2607-440c-9e37-cb6a33159fc7
  modified: 2026-08-28T23:49:39.180Z
---

オーナーの Cowork 資料（`Investment_設計資料/取込パック_20260823_ハーネス再設計/` 4 ファイル）を取り込み、Phase 0 を着地。
正本: 取込 worklog `docs/worklogs/20260823-claude-harness-intake-189b01f3a9.md`（適合表 23 項目・global 棚卸し）、
ODR-0018 `docs/decisions/20260823-harness-reduction-policy.md`（**Accepted、08-23 PR #210。オーナー逐語「はい」**）、KPI `docs/status/harness-kpi.md`。

## 状態（次セッションの再開点）

- **重い 4 つ 完全完了（08-29 早朝）**: C1 = PR #247・C6 = PR #249・C9 = PR #258・C4 = PR #263・**A 統合 5 PR = #266（A27 縮小）/#267（C11 折込・manifest に resume_mode 27 タスク）/#268（scheduler 4→1）/#269（safe 2→1）/#270（生成物同期 2→1）** すべて着地。**CHECKS 60→42・merge 検査 55→23**。監査停止の修理は PR #262。ODR-0018 決定 10 の残りは **B3（temporal_coverage の 2 防御 pytest 化）・B9（registry secret の A15 統合）・D 移設 7 本**のみ。
- **A 統合で得た selector の定石（08-29）**: 検査を消す/統合すると「検査スクリプト自体の path 分類」が毎回 classification_required で止まる → 生きた check スクリプトも harness_docs class へ都度登録（scheduler_integrity/mode_policy/build_run_manifest/parity_lib で 4 回発生）。統合先の static_check_inputs key へ削除側の入力パターンを必ず併合（scheduler_integrity は .bat/task_wrapper_unmanaged/job_runtime.py 等 6 本吸収）。GHA の pytest 列挙は framework-docs-quality.yml と extended の 2 箇所が対で、コメント一覧にも残骸が出る。
- **repair の後出し競争（08-28 深夜 実害）**: guard は「queue 内で repair_enqueued_at 最新の 1 本」しか受理しないため、複数セッションが同時に per-head repair を使うと後から enqueue した者が常に勝ち、先行の passed repair（各50分）が無効化される。3 セッションで実際に発生。**同時停止時は repair 競争をせず full_audit の全体解除を待つ（駆動を自分が引き受ける）方が全体最適**。guard の設計課題として ODR 起票候補。
- **08-28 の重大事象: 監査停止の自己閉塞（ODR-0019 の実例）**: 他セッションの `84373168c`「prioritize ready proof jobs」が queue 優先度を repair>ready>full へ意図的変更したが、旧順序を固定する `test_weekly_audit_hardening.py::test_weekly_audit_jobs_are_not_starved_by_older_ready_job[full_audit]` が未追随のまま着地（その PR の ready gate は本テストファイルを選択していなかった＝selection の盲点）。以後 **full_audit 全滅 + repair_audit も同テストを含む head で走るため 3 連敗**し停止が自己閉塞。修理 = パラメータ 1 行撤去の repair PR #262 + その head での `weekly_test_audit --enqueue-repair`（CLI 正本は `python -m scripts.dev.weekly_test_audit`。`weekly_audit_cli.py` は library で直接実行しても無言 exit 0 の罠）。**教訓: 監査を落とすテスト回帰が main に入ると修復証明も同じテストで落ち続ける。監査失敗の内訳は必ず「単体で現 main 再現」して、テスト側追随漏れなら repair PR を最優先で立てる**。
- **repair_audit の per-head 仕様（08-28 コード確認 weekly_audit_guard.py:388-427）**: repair 証明は `request.head_sha == マージする PR の tested_head` の完全一致でしか効かない（=1 本の repair は 1 PR しか通さない）。全体解除は full_audit が tested base の「最近傍 audited 祖先」で pass した時だけ（resolve_stop_state は full_audit aggregate のみ参照、repair は無視）。さらに repair は「queue 内で最新の repair」しか受理されず（:411-416）、blocked_by 3 点が「マージ時点の active stop」と一致必須——**間に別の full_audit が失敗して active stop が近い方へ移ると binding が壊れる**。手順: 停止中 PR は head で `python -m scripts.dev.weekly_test_audit --enqueue-repair --expected-head <head> --source-claim-id <claim>` → repair は priority 0 で full_audit 群を追い越す → passed 直後に finish-pr（doomed full_audit の完走前に）。マージには after-merge full_audit の自動起票が付く（runner-core/test-infra pack を含む evidence の場合）。
- **base race は分単位で起きる（08-28 実測)**: gate 3 分の間に peer が merge して `base_unchanged=false` で overall failed（コマンド全 pass でも失敗になる。失敗理由はコマンドでなく result.json の base_after_sha を見る）。fetch→merge→即 gate で最短化。
- **Phase 2 実装 大詰め（08-28 早朝時点）**: 決定 10 の実施 PR は #237〜#245 の 9 本が着地し **merge 検査 55→32 本**。着地済み: 死に検査 4（C10/C18/C20/C21）・凍結フェーズ 6（C2/C12-C16）・C7 digest 台帳・C19 件数台帳・C17+非交渉マーカー移設（A15 の NON_NEGOTIABLE_MARKERS）・C5/C8・B 降格 18 本（advisory profile + 週次タスク HarnessAdvisoryChecksWeekly、Scheduler 実登録はオーナー一括待ち）。**残り: C1（agent_session→lock 契約+peer 保護 forbidden 全セットの pytest 化が先）/ C4（serving 3 防御の pytest 化が先）/ C6（eslint 置換）/ C9（journal 挙動 pytest が先）/ C11（薄い検査を scheduler 整合へ）/ B3（2 防御 pytest 化が先）/ B9（registry secret パターンの A15 統合が先）/ D 移設（D1・D4・D5・D11・D15・D16・D17）/ A 統合（scheduler 4 本→1・safe 2→1・生成物 2→1・A27 縮小可）**
- **08-28 の運用知見**: (1) guard 修理 #242 着地後は helper merge が全復活（selection 機構を変える PR だけ detached runner から finish）。(2) **パック予算はレーン単体でなくパック全コマンドの合計**に掛かる（runner-core = static 90 秒 + env 234 秒 = 324 秒 → 420 に是正済み。test-infra も 420）。(3) 分類追加は selection yaml の**classes: セクション側**へ（同名行が static_check_inputs にもあり、先頭一致の replace は誤挿入する——2 回踏んだ）。(4) advisory 降格後も「実リポが常に合格」型のテストが残っていると他人の PR で赤くなる（file_size_budget で実発生→削除）。(5) 監査とゲートの同時実行は環境レーンを枯らす——監査は enqueue 後に単独 driver で回し、ゲートは監査の合間に
- **Phase 2 実装中（08-27）**: H2a 表 = 決定 10（PR #237 着地）。H2b 第 1 弾（死に検査 4 行、PR #238）と第 2 弾（凍結フェーズ契約 6 本、PR #239）着地済みで **merge 検査 55→49 本・CHECKS 60→51**。各着地後の full audit passed（第 1 弾分は実証済み・第 2 弾分は実行中）。**残り: B 降格 21 本（advisory profile + 週次レポートの朝チェック組込みが必要）→ 条件付き C 7 本（防御移設が先。C17 発注禁止 marker は A15 同居の merge-blocking へ）→ D 移設 18 本。A27 縮小は C12/C15 撤去済みなので着手可**。
- **08-27 の罠と修理**: (1) run_check_suite.py を触ると development_test_tiers の digest 追随 + quality-gates.md の件数 literal が drift（後者は「件数を文書に固定しない」書き換えで恒久解決済み）。(2) **Ready 証跡ロックのデッドロック**: PR #221/#227 以降 gate.main は全体を worktree の Ready 証跡ロックで包むため、gate 内で gate.main を呼ぶテスト（test_local_pr_gate_review_contracts）が外側のロックを待って必ずレーン予算超過（正確に 114 テスト後に停止する決定的再現）。テスト側に autouse のロック迂回 fixture で修理済み（PR #238）。(3) 未分類 path 停止は「削除したファイルにも分類が要る」— 削除 path の exact エントリを harness_docs クラスへ追加していく方式（selection yaml に同名行が 2 箇所ある点に注意: static_check_inputs と classes）。(4) snapshot は dirty tree で --write すると worktree_dirty が焼き込まれ、commit 後の check で落ちる — クリーンな状態で再生成。
- **Phase 1 完了（08-27 に H1c=PR #224 と H1d 却下記録=PR #225 が着地）**。H1d はオーナーが却下（強度は現状維持、代わりに「高コスト作業の前に安価な事実を先に取る」を AGENTS.md 進め方 7 と ODR-0018 決定 8/9 に記録）。**Phase 2 進行中**: H2a 棚卸し表（79 本→A 実質 20/B 21/C 20/D 18、反証 2 方向済み）は scratchpad の h2a_final_table.md に確定版、オーナーの「はい」待ち。
- **08-27 の重大教訓**: (1) 件数台帳 `expected_managed_markdown_count` は廃止でなく**除外件数 pin へ付け替え**（PR #231）——台帳の中に「除外表がこっそり広がると 1,695 文書が統治外に落ちる」唯一の防御が埋まっていた。(2) **キュー汚染デッドロック**: 別セッションが branch 限定の pack id (python-broad) を宣言した job を共有 queue に入れると、main の merge guard が snapshot 全読取失敗→「unreadable (global stop)」で全員マージ不能。監査が exact main SHA で passed している証拠を確認のうえ、ODR-0019 の代替経路（gh pr merge + PR コメントで記録）で #222/#224/#225 を着地させた。guard の per-job 許容化は task chip 起票済み。(3) 手動 merge 後の後片付けは sync-main → cleanup --apply --worktree --claim-id で helper が使える。
- （旧記録）**ODR-0018 承認済み。Phase 1 進行中**: H1a 完了（PR #211、AGENTS.md 88 行 / CLAUDE.md 13 行）、H1e 完了（PR #212、−3,168 行: `.codex/skills`・役割チェッカー 2 本・pre-tool-use hook 経路を削除、run_check_suite 60/55）。H1b 完了（PR #213、reviewer 契約 = P0/P1/P2 のみ・1 往復・high、security reviewer は条件付き、`~/.codex/agents` ミラーも更新済み）。**次は H1c（解釈エコー規則: worklog テンプレ Decision Log 3 行型・worklog-starter skill・OWNER_INTENT §5 追記・development-harness.md に ODR-0011 事例 5 行）→ H1d（推論強度 A/B: implementer を medium に 2 週間）**。各 PR は解釈エコーで「はい」を得てから。H1a の申し送り: 新規 Claude セッションで `/context` を確認（claude -p は OAuth 期限切れで未実施）。
- 指示書との差分（適合表「別の形で」）: ODR 番号 0015→**0018**（0015 worktree 処分 / 0016 金融ゲート退役の採番訂正 / 0017 証明パック gate が先行）、
  H0a+H0b 統合、KPI は固定ファイル `docs/status/harness-kpi.md`（`--since 2026-07-20` が付録 A 同一窓、既定は 8 週）、
  初回通過率は未計測（証跡は通過記録のみ）、メタ比率は狭義 36.4% / 広義 51.5% を併記、tests/scripts の赤は 135 件でなく**実測 19 件**（全件 12 分）。
- 取込パック 4 件目 `追加指摘_ハーネス以外の懸念と改善案` は**未取込（参照のみ）**。A1 DB バックアップが定期実行に無い／A2 `.env` の `Read` deny が無い、はオーナーへ提示価値が高い。
- ODR-0018 は **ODR-0017（Codex が 08-21 に起票、証明パック gate、Accepted）を amends**。重なる点（週次監査・ready/audit 分離）と逆向きの点（queue/attestation/未知 path 停止＝機構の追加）を本文に明記し、付録台帳に見直し日 2026-10-18 を提案済み。

## ODR-0017 の新 gate（PR #205 以降）で実際に踏んだ罠

**Why:** 旧 T3 前提の memory は全部古い。新 gate は `ready` / `audit`（t3 は alias）で、未分類 path は停止、長時間 pack は非同期。
**How to apply:**

- **未分類 path は `classification_required` で gate が止まる**: 新規 `scripts/dev/*.py` は `development_test_selection.yaml` の class（docs 生成専用なら `harness_docs.patterns`）に 1 行登録。`scripts/contract_scope.yaml` は `harness_docs` に分類済み（unknown ではない）。
- 必要 pack は `run_changed_test_plan.py --changed-path …` で**commit 前に確認**（`required_packs` / `async_packs`）。docs + harness_docs + runner_core は sync のみで Ready 30〜90 秒。
- **`db/**` を 1 行でも触ると db class → `db-fresh`（async）→ `pending_async`（exit 3）→ `proof_pack_queue.py --run-one` で detached runner 実行が必須**。`publish-pr` / `finish-pr` は `--evidence-path <v4 result.json>` 必須で、async は queue attestation 一致が要る。
- **非同期 runner の欠陥（08-23 発見）**: ①隔離環境が `UV_CACHE_DIR` を落とし、本 host（cache を D: へ移し既定 path が symlink）では runner の `uv sync --frozen` が必ず失敗 → **PR #208 で `local_pr_gate_selection._SAFE_INHERITED_ENV_KEYS` に追加して修正済み**。
  ②runner は `npm ci` をしないため、静的検査に `desktop_api_client_usage` 等の desktop 検査が選ばれる PR（`tests/scripts/test_check_desktop_api_client_inventory.py` を触るだけで選ばれる）は async pack を完走できない → **未修正**。回避は db class と desktop 入力を同じ PR に混ぜない（PR #208 → PR-2b 分割の理由）。
- **selector は削除 path も分類する**ので、`scripts/check_*.py` を消す PR でも `development_test_selection.yaml` に path 登録が要る（check スクリプト全般は class 未登録＝Phase 2 の前提）。`test_proof_pack_selection.py` は直近 30 commit の分類結果を固定しており、分類を足すと歴史 commit の期待値が動く。
- 失敗 job の runner evidence は cleanup で消える。原因は git common dir 配下 `investment/proof_pack_queue/v1/jobs/<job>/{events.jsonl,uv-sync.log,ready-gate.log}` で見る。再現は `create-worktree --detach-at <head>` の claimed probe runner で同じ argv を `isolated_child_environment()` で実行。probe は head が未マージだと `cleanup --apply` が拒否 → マージ後に merge commit へ `checkout --detach` してから cleanup。
- **base race は今も起きる**（初回 gate 中に PR #206 が着地 → `base_mismatch`）。gate 直前に `git fetch` し、rebase 後は worklog の base/registry 件数も直して amend。
- **selector / builder / helper 自身を変える PR は main の helper で証跡を再計算できず `finish-pr` が「schema-v4 selector or required-pack proof does not match」で落ちる**（digest は plan 全体＝commands を含む）→ runbook どおり `create-worktree --detach-at <tested head> --owner codex` の claimed detached runner で `uv sync --frozen` → runner 内から `finish-pr` → `cleanup --apply`（PR #212 で実施）。
- `finish-pr` は対象 worktree の外からしか実行できない（`sync_repo.py:382`）。Claude の worktree 隔離下では **ExitWorktree(keep) → main checkout で finish-pr** が正規手順（finish-pr が worktree を削除するので WorktreeRemove は使わない）。
- fresh worktree は `.env` コピー必須、`desktop/node_modules` が無いと `test_check_desktop_api_client_*` / `test_desktop_release_contract*` 106 件が環境起因で赤。
- md を 1 本足すごとに `docs/research/registry.yaml` の `expected_managed_markdown_count` +1（08-23 時点 2308）。ODR を足したら OWNER_INTENT §7・README §3・contract_scope の 3 箇所。
- ODR 採番は並行セッションと衝突する: **起票前に `git grep ODR-00NN` を origin/main と未マージ branch の両方で確認**。
- Python heredoc で日本語パスに `\\u` を含む文字列を書くと SyntaxError → patch スクリプトはファイルに書いて raw 文字列で。

## Phase 0 の成果（PR）

- PR #207: worklog + ODR-0018 + `scripts/dev/harness_kpi.py`（155 行、読取専用）+ `docs/status/harness-kpi.md` + 索引/registry/selector 登録。review P1 1（ODR 決定 7 の「main の赤」を KPI 生成から分離）/ P2 1 修正。
- PR #208: tests/scripts 削除 17 関数（disabled_tasks 配下の manifest 台帳 14、件数固定 1、checker 未追随の重複 1、残骸定数）+ queue integration test の自 claim 照合化 + `UV_CACHE_DIR`。全件 2,395 passed。
- PR #209（PR-2b）: estat sqlite spool を governance allowlist + `non_postgres_local_spool` bucket に登録、stale `ops.py` 除去、governance test の固定リスト除去。**db-fresh async を queue worker で初完走**（148 秒、attestation あり）。main `277788fa2` で tests/scripts 失敗 0。KPI: tests/scripts 直下 36,167 → 35,526 行、worktree 9 → 7。
