---
name: project-stalled-fix-landing-2026-08-20
description: "滞留していた完成済み修正5本を着地 + worktree 32→18本 (2026-08-20, PR #189〜#194)。滞留の原因は全て退役済み機構への登録だった"
metadata: 
  node_type: memory
  type: project
  originSessionId: c288e354-4d4e-4325-9c0d-4bba4c1055cb
  modified: 2026-08-20T11:01:10.008Z
---

# 滞留していた完成済み修正の着地（2026-08-20、PR #189〜#194）

worktree 32本 → **18本**。9本回収 + 5本着地。

## 回収した9本の判定方法

**「消したら失われるもの」= worktree HEAD のツリーにあり、`origin/main` の全履歴（1693 commit）に
一度も登場しないパス。** 単純な `origin/main` との差集合では数百件出て絞れない（main 側で削除・改名された
ファイルを大量に持つため）。

```
git log origin/main --name-only --format= | sort -u > main_ever.txt   # 0.8秒、13724 パス
git -C <wt> -c core.quotepath=false ls-tree -r --name-only HEAD | sort -u | comm -23 - main_ever.txt
```

さらに**26本以上に共通して出るパスは 2026-07-16 の大統合で意図的に置換されたノイズ**（order_intelligence
の 20260713_02..05 revision 等9件）。除外すると真の固有が見える。

決定的なのは `git rev-list --count origin/main..HEAD`。**0 なら全コミットが着地済み**で、
残るのは未コミット分だけ。同一 HEAD の重複 worktree も `git worktree list` の SHA 突合で見つかる。

削除は `git worktree unlock` → `git worktree remove --force`。ブランチは残す（軽量で、内容の保険になる）。

## 着地した5本と、滞留していた本当の理由

| PR | 内容 |
|---|---|
| #189 | TDnet 決算短信: 1件の不良で朝バッチ全体が停止する問題を隔離 |
| #190 | feature_store: EPS が NUMERIC(12,6) を超えて壊れる問題を quarantine |
| #191 | R2 sizing shadow: 実運用非接触のオフライン比較レーン |
| #192 | IR/提携: `conn.execute` を迂回して `?`→`%s` 変換が効かず全 run 失敗していたクエリの修復 + tier_depth/source_kind |
| #194 | scheduler: 9タスクの引数欠落復旧 + auto-retry の通知分類 |

**5本すべてに共通していた滞留理由: 退役済み機構への登録が数百行含まれていたこと。**
登録を落として本体だけ残すと、いずれも素直に通る。ODR-0002 が
「価値があるのはレジストリが指すテストの方で、それは登録がなくても通常レーンで走る」と結論した通り。

## 着地作業で繰り返し踏んだ罠

- **worktree に `.env` が無い**とテストが collection error になる（estat_tracker/disclosure_supply_chain で9件）。
  `desktop/node_modules` が無いと TypeScript 解析が失敗し `desktop_api_client_usage` /
  `desktop_release_contract` が落ちる。着地前に両方配置する
- **ready モードには600秒の予算がある**。変更範囲が広いと非DB全体レーンが選ばれて10分超になり、
  全段階 pass でも `overall: failed`（evidence の `budget.within_budget=false`）。t3 は時間制限なし
- **各レーンは `--maxfail=1`**。gate を回す前に `run_pytest_lane.py fast --parallel`（約5分）と
  `--profile db-focused --test-path tests/db`（約20分）を通しておくと、65分の t3 を1回で済ませられる
- `publish-pr --worklog` は **claim に登録済みのパスと完全一致**が必要。ファイル名が違うと
  `worklog does not match the worktree claim`。worklog の `Status:` は `Verifying` か `Done` でないと拒否される
- rebase 衝突が docs 台帳（次アクション管理台帳 / docs_completion_registry / タスク索引台帳）で起きたら
  **両側を残す**（main も自分も行を足しているだけ）。`自動化未対応タスク表.md` は backlog_scanner の
  生成ミラーなので main 側を採り、`scan --write` で再生成する

## 固定値をやめた2箇所

どちらも「main 側の変更に追随しないと落ちる」台帳型の pin だった。ODR-0002 の方針に沿って実測導出へ変更:

- `test_notification_boundary.py` の `auto_retry_task_count == 237` → manifest から導出した集合の長さと比較
- `test_decision_case_outcome_loop_hardening.py` の head 固定 → `require_stamp_safe_baseline().current_head`
  （`migration` マーカーが無い test は conftest がリポジトリ現在 head まで進めるため、自 revision 名の
  定数と比較していると新 revision 追加で必ず落ちる。main では偶然一致していただけ）

関連: [[project-invariants-mechanism-removal-2026-08-20]] /
[[project-worktree-inventory-cleanup-2026-08-16]] / [[project-valuation-capital-landing-2026-08-17]]
