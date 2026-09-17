---
name: project-worktree-landing-batch7-2026-08-21
description: "worktree 18→13本 + EDINET世代リース/マクロ統計を着地 (2026-08-21, PR #195/#196)。長いrebaseは「branchが追加した全行が残っているか」を機械照合しないと内容が消える"
metadata: 
  node_type: memory
  type: project
  originSessionId: c288e354-4d4e-4325-9c0d-4bba4c1055cb
  modified: 2026-08-21T12:08:18.275Z
---

# worktree 整理 第7弾（2026-08-21、PR #195/#196）

18本 → **13本**。4本回収 + 2本着地。前提は PR #193（不変条件機構の削除）が済んでいること。

## 長い rebase では「追加行の生存確認」を必ずやる

**マクロ統計（44コミット）の rebase で、衝突解決が main 側を採った結果 branch の内容が3箇所消えた。**
最も危険だったのは `sizing_engine/main.py` の `decision_stat_materializations_available()` ガードで、
これが無いと **ODR-0012 が参照専用と定めた統計がポジションサイズを動かす**。オーナー決定の前提が
崩れたまま着地するところだった。

検出方法（`scratchpad/verify_rebase.py` に実装）:

```
git diff --unified=0 <old_base> <branch_head> -- <path>   # branch が追加した行
→ 各行が rebase 後の HEAD:<path> に存在するか確認
```

新規ファイルは `git diff --name-status <old_base> <branch_head> | grep ^A` の全件について
`git cat-file -e HEAD:<path>` で存在確認する。マクロ統計では 90 件中 88 件が生存し、
欠けた 2 件は意図的に消した機構ファイルだった。

**衝突を機械的に `--ours` で潰すのは、docs 台帳と削除済み機構ファイルに限る。実コードでやると内容が消える。**

## 回収した4本の判定

| worktree | 根拠 |
|---|---|
| `integrated-functional-repair` / `-69d22f8b` | 両方とも `-residual-20260713` の**祖先**であることを `merge-base --is-ancestor` で確認。blob 単位でも residual が superset。**residual を残すことが前提** |
| `api-v2-typecheck-base-20260718` | 型チェック基盤として残す価値なしと2回の独立調査が一致 |
| `order-intelligence-auto-promotion-20260720` | `ir-quant-productionization-20260721` が内容を引き継いでいる |

独立に2回 Workflow を回して 13 判定中 12 が一致。不一致は `book-knowledge` のみ（keep vs land-first）。

## 着地の2本

- **PR #195 EDINET 世代リース**: 新モジュール10 + テスト6。`tools/market_data` → `tools.db_admin` の
  越境5件（うち3つは**非公開関数**への依存）と test ファイル 1,090 行超過を baseline 登録して通した。
  共有層への切り出しは別タスクへ分離（`activation.py` が 780 行あり切り出し範囲の見極めが要る）
- **PR #196 マクロ統計**: 387ファイル / 約27,900行。**オーナー承認済み(ODR-0012)・独立レビュー3名が
  CERTIFY YES 済みで、残っていたのはゲートだけ**だった。2回の T3 失敗はいずれも削除済み機構が原因

## この回で踏んだ運用ミス

- **同じ worktree でゲートを二重起動した**。出力ファイルが空だったのを「実行されなかった」と誤判断して
  再実行した結果、2つの t3 が Desktop の依存ファイルを奪い合い `npm ci` が
  `unlink ... esbuild.exe / rollup.win32-x64-msvc.node` で失敗した。
  **バックグラウンドタスクは出力が空でも走り続けている。完了通知が来るまで再起動しない。**
  残留は `Get-CimInstance Win32_Process` で CommandLine を見て所有を確認してから停止する
- `zipfile.writestr` は既定で**現在時刻**を各エントリに埋める。生成 bytes を
  `@pytest.mark.parametrize` の引数にすると xdist worker 間で test ID が変わり、
  pytest が "Different tests were collected between gw0 and gwN" で実行ごと拒否する。
  `ZipInfo(date_time=...)` で固定する（`test_jeita.py` で実際に発生）

## 残り13本の分類

- 保持（未完成）: `tdnet-breaking-watchdog-cmd-repair`（test 10件 RED、新規3モジュール869行は価値あり）、
  `earnings-gate3-formal-evidence-v2`（完成度は高いが**新 revision を過去位置へ挿入**するため chain 再配置が要る）
- 保持（大規模）: `ir-quant-productionization`(269) / `integrated-functional-repair-residual`(137) /
  `repo-skills-refresh`(113) / `investment-decision-os-phase0`(65, ODR-0001 D6③で個別確認指定・Blocked) /
  `api-v2-20260718`(53) / `api-v2-hardening`(51) / `pr5-scheduler-recovery-canary`(50)
- 判定割れ: `book-knowledge`(32) — 主要16ファイル中15が main 未着地。ただし rebase で
  `daily_screener/repository.py` と `scoring/fundamentals.py` が衝突する（実コード）
- 保留: `dbopt` — 7月13日の13コミット。価値は pool のタイムアウト保護 + timestamptz 検査 + ADR。
  必要部分だけの移植が現実的

関連: [[project-invariants-mechanism-removal-2026-08-20]] / [[project-stalled-fix-landing-2026-08-20]]
