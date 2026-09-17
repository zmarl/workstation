---
name: clickhouse-retirement-landing-2026-08-28
description: "実行順1完了 (PR #260)。ready_async 着地経路の罠5件と対処 — copy回帰修理・python pack空問題・base race・finish-pr guard trap・worker lock 運用"
metadata: 
  node_type: memory
  type: project
  originSessionId: 4536797c-cfe8-41ab-8cb0-896ec79630fc
  modified: 2026-08-29T10:41:49.636Z
---

2026-08-28、総点検実行順 1 番（ClickHouse 退役 + .wslconfig）を PR #260 で完遂。gate 停止 4 回をすべて gate 側欠陥として修理しながら着地した記録。[[architecture-review-2026-08-28]]

## 完了内容

- ClickHouse を compose / bootstrap CoreServices / Desktop launcher fast-ready / preflight から除去。apply_clickhouse_schema.ps1 + db/baseline/clickhouse/ 削除。SETUP・runbook 2 本・deployment-topology 追随。
- コンテナ investment-clickhouse 停止+除去済み。**volume `infra_clickhouse_data`（14.65GB）は保持** → タスク 2「Docker ゴミ掃除」の承認付き削除リストに含める。
- `C:\Users\kazum\.wslconfig` 新規作成（memory=20GB / swap=8GB）。**反映は wsl --shutdown 待ち（DB 停止を伴うためオーナーのタイミング判断）**。

## ready_async 着地経路の罠（今後の db/** PR すべてに関わる）

1. **evidence copy 回帰は #260 で修理済み**: gate が run ディレクトリへ logs/ を書くのに copy 許可リスト（start.json/result.json）が未追随で、runner gate 全 pack passed 後に必ず QueueContractError で failed になっていた（08-28 時点の main 全体）。同一修正が未マージ branch codex/qwen38-earnings-daily-agent (c433e7bb9) にもあり、マージ時は同一内容で衝突しない。
2. **.py 非随伴の db diff は python pack が証明不能だった** → builder 修理済み（python-db-static-fast を db-txn でなく python pack へ割当）。**残存エッジ**: migration diff で db_serial_targets が空、または db_static も python targets も空のケースは依然 pack 空になり得る。
3. **base race**: async queue 待機中に origin/main が動くと runner preflight が base_mismatch で job failed（当日 3 回被弾。ピークで 1〜1.5h 毎にマージが着地）。対策 = gate ready 完了直後に `proof_pack_queue --run-one` を即時実行して露出を約 8 分に圧縮。**gate は pending_async で exit 3 を返すため `gate && worker` の連結は不可**（`;` か通知駆動で）。
4. **finish-pr / after-merge は実行元 checkout のコードで selector proof を再評価する**: selector（development_test_selection.yaml / builder）を変更する PR は旧 main コードでの再評価と必ず不一致になり finish-pr が落ちる。確立済み代替: `gh pr merge <PR> --merge --match-head-commit <head>` → merge 親が (tested_base, tested_head) と一致することを確認 → **main checkout を `git pull --ff-only` で先に更新** → 同じ SHA で `after-merge` → `cleanup --apply`。（#242 に続き #260 でも実証。ff-pull を挟まないと after-merge も同じ理由で落ちる）
5. **queue worker lock 運用**: host 同時 1 本の worker.lock は peer セッションと取り合いになる。保持状態は `open('worker.lock','rb').read(1)` が PermissionError なら保持中という probe で非破壊確認できる。優先度は repair_audit > ready_async > full_audit（同種内は queued_at 順）。--run-one は最優先 job を 1 件処理するだけなので、自分の job まで数回回す必要がある。他人の job を処理するのは設計どおりで干渉ではない。

## その他の実測

- 広域 fast レーン（run_pytest_lane fast --parallel）は実測 671 秒 = python pack 予算 300 秒の 2 倍超。broad_fast 戦略はこの予算では ready で完走できない（shared_core の broad_fast も同リスク）。
- ops_infra 分類を selection registry に追加済み（infra/** + bootstrap/launcher/preflight/apply の ps1。focused_python / python pack）。
- Bash ツールの background 実行はタイムアウト 600000ms 指定でも実際には長時間走行が完了する（45 分の repair_audit が完走した実績）。

## 追記（08-29、後続 PR #271 で判明）

- `.wslconfig` 20GB 上限は 08-29 に反映済み（wsl --shutdown → Docker engine 自動復旧、コンテナは restart=unless-stopped で自動起動、MemTotal 20GB 実測）。
- **週次監査の per-PR repair guard は「queue 内で repair_enqueued_at が最新の 1 本」しか受理しない**（weekly_audit_guard.py）。並行セッションが repair を enqueue し合うと互いの 50 分監査を無効化する。全体停止時の正解は **repair を追加せず、修理済み main の full_audit 完走による全体解除を 1 セッションが driver となって回す**（08-29 未明に investment-22 主導で解除実証）。
- **rebase で head が変わった open PR は publish-pr が「pull request head does not match tested head」で拒否**し、helper に更新手段がない。force push を使わない再着地手順: `gh pr close <PR> --delete-branch`（local が worktree の場合 branch 削除は失敗するので `git push origin --delete <branch>` を追加）→ publish-pr で新規 PR 作成（#261→#271 で実証）。
- risk_event_tracker の fallback-tail テスト失敗は anomaly_bridge（本番 DB 読み・fail-open）の隔離漏れで、**gate のサニタイズ環境では合格し実 .env で落ちる環境依存**だった。同構造（unit テストから本番 DB 到達可）のテストは今後も出得る。
