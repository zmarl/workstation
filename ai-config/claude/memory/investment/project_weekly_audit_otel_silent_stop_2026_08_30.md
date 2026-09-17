---
name: project-weekly-audit-otel-silent-stop-2026-08-30
description: "週次監査が 3 連続で診断ゼロの global 停止になり全 PR が 12 時間マージ不能になった事故 (08-30)。真因=otel port 転送 half-open + _http_status の例外漏れ、増幅器=捕捉64MiB/保存16MiB の非対称"
metadata:
  node_type: memory
  type: project
  originSessionId: 3f6c93bb-2607-440c-9e37-cb6a33159fc7
  modified: 2026-08-29T22:56:44.022Z
---

2026-08-29〜30、週次 full_audit が 3 連続で **`phase="evidence"` / `EvidenceContractError` / stop_scope global** になり、
レーン名もログもエラーメッセージも一切残らないまま全 PR のマージが 12 時間停止した。修理は
worklog `docs/worklogs/20260830-claude-otel-probe-audit-log-repair-189b01f3a9.md`。

## 診断の入口（次に同じ形を見たらここから）

**監査が evidence 失敗で、かつ `logs/` に safe レーンのログが 1 バイトも無い**ときは、テストの赤ではなく
**lane 内の生例外**。`weekly_test_audit.py` の generic catch が `(OSError, RuntimeError, TypeError, ValueError)` を
`evidence`/EvidenceContractError へ潰すため、真の理由が消える。まず host→各コンテナの疎通を疑う。

## 因果連鎖（全段を実測で確認）

1. `wsl --shutdown` で Docker の port 転送が壊れる。**postgres だけ `docker restart` して「復旧」と判断すると otel-collector が取り残される**（`docker ps` の Up 時間差と healthy マーカー有無で見分けられる）
2. half-open な 13133 は TCP accept 後に無応答切断 → `shared/otel.py:_http_status` が **`http.client.RemoteDisconnected`** を送出。**`RemoteDisconnected` は `ConnectionResetError`(OSError) + `BadStatusLine`(HTTPException) の多重継承で `URLError` ではない**ため、`except (urlerror.URLError, TimeoutError)` を素通りしていた（fail-safe のつもりが 1 モードだけ fail-open していない）
3. `shared/otel.py:105` の health ガード経由で `ensure_initialized` から送出 → **Decision API を初期化する全テストが失敗**（traceback 約 26 KB/件）
4. safe-fast の出力が 16 MiB 超（正常時は **47,287 バイト / 10分38秒**。失敗時は約 15 分かつ 350 倍以上）
5. `AttemptLogStore.write` が生 ValueError を raise。**raise は attempt 記録前・ファイル生成前**なのでレーンもログも残らない

## 着地（08-30 完了）

- **PR #278**（修理 6 点）→ 自 head の repair_audit passed → merge → **main `9ab751f2d` の full_audit passed で全体解除**
- **PR #280**（残る 1 経路 = 失敗 nodeid 件数上限）→ merge。main `64ed8b128`
- 並走 investment-bf の PR #279（大量保有 J-Quants 化）も解除後に着地

## 恒久修理（PR: otel-probe-audit-log-repair）

- `shared/otel.py`: `except (OSError, HTTPException)` へ。`HTTPError` 節が先なので 4xx/5xx は数値のまま返る
- `scripts/dev/weekly_audit_logs.py`: 16 MiB 超過を raise でなく **head 1/4 + notice + tail 3/4 の truncate** へ。**両端を `decode("utf-8","ignore").encode()` で再デコード**（UTF-8 の途中で切ると `read_bound_log` の復号とハッシュ照合が壊れる）。`failed_nodeids` は truncate 前の全出力から作るので summary の失敗一覧は完全なまま
- 上限を 64 MiB へ上げる案は不可: `MAX_ATTEMPT_LOG_BYTES` は `read_bound_log` の読み取り上限と retention GC の判定を兼ねている

## 併発して分かった構造欠陥（オーナー提案候補）

- **gate は audit マーカーのテストを走らせない**（`tests/conftest.py:110-113` の `_AUDIT_TEST_ROOTS` により `tests/scripts/**` と `tests/tools/quality/**` は自動 audit マーカー → safe-audit-contracts レーン行き）。よって **audit レーンを壊した PR がそのまま入る**。実例 = PR #248 が 2 件（selector 期待値・typed route 未登録）
- **同名 check でも gate は下限判定・audit は厳密**: `check_decision_api_endpoint_contracts` は `--min-typed-scope 393` で通るが、audit のテストは完全性と件数一致を見る
- **登録リストの非対称**: `RUNNER_SAFETY_TEST_PATHS` は中身が集合 pin で守られている（`test_changed_test_plan_ready_modes.py:72-90`）が、`development_test_selection.yaml` の `audit.critical_contract_patterns` との**対応は誰も見ていない**。今回の再発経路はまさにこの穴で、`test_compose_bootstrap_selection.py` が後者だけに載っていた

## 修理そのものが安全側を緩めた例（最重要の設計教訓）

**「上限を raise でなく切り詰めで満たす」修理は、その配列の下流の意味を確認しないと false-stop を false-pass に置き換える。**
PR #280 の初版は `failed_nodeids` を `[:1000]` で切ったが、この配列は `failure_stop_scope`
（`weekly_audit_policy.py:150-187`）の唯一の入力で、判定は `path_from_nodeid` しか見ない。
`failed_nodeids()` は `sorted()` を返し、**critical_contract_patterns は全て `tests/scripts/**`**（辞書順で
`tests/analytics` 等より後ろ）なので、大量失敗時に**本来 global の停止が domain に縮小**し、
無関係ドメインの PR が「監査が壊れているのに」マージ可能になる。
修理は `bounded_failed_nodeids()`（distinct path を先に 1 件ずつ残してから残枠を埋める）。
**保存されるのは distinct 失敗 path 数が上限以下のときだけ**——この前提を docstring と worklog に明記すること。

## 運用教訓

- **WSL 再起動後は全コンテナの port 転送を個別に確認する**（postgres が通っても otel/llm-gateway が壊れていることがある。`pg_isready` や healthy マーカーだけでは足りない）
- worktree で audit レーンを測るときは **`npm ci` 必須**。無いと desktop 系で 105 件規模の偽陽性が出て「自分の PR が壊した」と誤認する
- 複数セッションが同時に停止に直面したら **repair の後出し競争をしない**（guard は queue 内で最新の repair 1 本しか受理しない）。誰か 1 人が driver を持ち、他は enqueue しない
- **未マージ branch の commit を main の挙動と取り違えない**。反証が「その修理は既に入っている」と言うときは `git merge-base --is-ancestor <sha> HEAD` と `git branch -r --contains <sha>` で ancestry を確認する（今回それで反証 1 件が撤回された）
- **並走セッションとの相互レビューは実際に効いた**。単独では見落としていた 4 件（failure_reason マスキング／db_fresh の赤／nodeid 件数上限／切り詰めによる false-pass）が全て相手の指摘由来。逆に相手の誤った反証 2 件は当方の ancestry 確認で訂正された

---

## 再発 2026-08-31: 同じ外形・別の真因（監査は 1 件も走っていなかった）

08-31 早朝、また `phase="evidence"` / `EvidenceContractError` / 全 PR マージ不能。しかし今回は otel も
postgres も健全で、**テストは 1 件も実行されていなかった**。

### 見分け方（aggregate の 3 フィールドで即断できる）

`duration_seconds: 0.0` かつ `plan.collected_count: 0` かつ `attempts[0].test_started: true` の 3 つが揃ったら、
**レーンの失敗ではなく runner worktree の作成失敗**。`test_started=True` を書く箇所は
`weekly_audit_worker.py:409` の外側 `except (OSError, RuntimeError, ValueError)` **1 箇所だけ**なので、
この組み合わせは worker 本体の生例外を意味する（`weekly_test_audit.py` 側は全て `test_started=False`）。

### 真の診断入口: `jobs/<queue_job_id>/events.jsonl`

summary.json と aggregate は `EvidenceContractError` しか残さないが、**queue の event 列には真の型が残る**。

```bash
cat .git/investment/proof_pack_queue/v1/jobs/<queue_job_id>/events.jsonl | cut -c1-420
```

今回の列: `queued` → `worker-claim` → `runner-create-start` → **2 秒後に `failure-recovery`** →
`error_type: "QueueContractError"` / `cleanup_status: "creation_uncertain"` / `runner_not_found`。
`full-audit-1.log` も `uv-sync-1.log` も**生成されていない**（成功 job には両方ある）ので、
job ディレクトリのファイル一覧を見るだけでも「起動前に死んだ」と分かる。

### 真因: 定期処理が main を dirty にすると全監査が死ぬ

`_create_detached_runner`（`proof_pack_queue.py:735`）は `sync_repo.py create-worktree` を subprocess で呼ぶ。
これは `require_creation_source` を通り、**runtime lock（`.claude/scheduled_tasks.lock`）以外の変更が
main checkout に 1 つでもあると `main has non-runtime changes` で拒否**する。

08-31 の犯人は `config/jpx_protected_codes_review_history.yaml`。月次の
`jpx-protected-codes-auto-review-monthly` が 04:00 JST に tracked file へ 80 行 append し、そのまま放置される。
**scheduler が tracked file に書く経路は、そのまま「全セッションの worktree 作成停止 → 全監査失敗 → 全 PR マージ不能」に化ける。**
過去の直接 commit が 4 回あり（`chore(config): record JPX protected-codes review run <日付>`）、
main へ直接確定させるのが確立した処理。恒久対策（ignore 化 or 自動 commit）は未実施。

`_create_detached_runner` は `QueueContractError(f"detached runner claim failed: {_helper_failure_detail(...)}")` と
**メッセージには理由を入れている**のに、event へは `error_type` しか載らない。類型 B（握り潰すなら何を握り潰したかを書く）の再演。

### guard のフィールドを間違えない（30 分溶かした罠）

`evaluate_merge_guard` が使う `selection_digest` は gate evidence の
**`selection.selection_map_sha256`** であり、トップレベルの `selection_digest` ではない。両者は別の値
（実測 `d07c0874…` vs `738d7f45…`）。トップレベルの方と `weekly_test_audit.selection_digest()` を比べると
「repair audit は構造上ぜったい guard を満たせない」という誤った結論に着く。

### 併せて見つけた残骸

`investment-local-pr-gate-<run_id>` コンテナが 32 時間 Up のまま残存（中断された gate の残骸）。
Ready gate 自体はこの残骸があっても通ったので今回の停止原因ではないが、
`docker ps` に混ざって現行 run の判別を妨げる。
