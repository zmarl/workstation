---
name: project-repo-consolidation-2026-07-16
description: リポジトリ大統合 (07-16/17) — 未コミット1100件着地・main乖離208解消・alembicフォーク一本化・worktree/stash整理の完了記録と手法
metadata: 
  node_type: memory
  type: project
  originSessionId: 199aa3a7-0af5-4d8c-8509-a38e471834c6
---

# リポジトリ大統合 2026-07-16/17 (PR #58, #59)

[[project-functional-completeness-audit-2026-07-15]] の P0「main乖離208 + alembicフォーク」を解消。

## 何をしたか
- メイン worktree の未コミット約1,100ファイル（07-09〜07-16 バッチ群 + Codex 並行成果）を領域別コミット → origin/main (208コミット) をマージ → 競合98ファイル解消 → 全検証green → PR #58/#59 で main 着地。メイン worktree は main に切替済み。
- worktree 17→9、ブランチ 28→10、stash 8→0。institutional-os の未コミット WIP は `wip/institutional-os-20260716` として GitHub 退避済み（ローカルの残骸フォルダ D:/Dev/Investment-institutional-os は削除未承認で残置、中身は退避済みで安全に手動削除可）。

## alembic フォーク解消の要点（再利用可能）
- 分岐: 20260713_01 から main側(order_intelligence 02..05) と ローカル側(law_updates..20260715_01) の二股。
- **本番DBの実適用状態が正**: 本番は ローカル側チェーンのみ適用済みだったため、「mainヘッドにローカルを付け替え」ではなく **未適用の main側チェーンをローカルヘッドの後ろに付け替え**（canonical の down_revision を 20260715_01 へ）。逆にすると alembic が未適用リビジョンを適用済みと誤認して永久スキップする。
- 付け替え後 `alembic upgrade head` で7本適用、current==head、baseline再生成、tests/db の固定アンカーassertも追随更新。

## マージ後の縫い目パターン（今回130+16件の正体）
- 「ours のテストが新パスに置かれ、実装は theirs のまま」→ テストが正なら ours 実装を新パスへ丸ごと復元（LatestEarnings/Dashboard）。
- main の shared.database 退役 (shared.db.pool へ) を ours 新規モジュールが知らない → import 一括書換。
- 生成物 (run_manifest.yaml / wrappers / size-budget / typed-scope数) は**ソースを直して正規ジェネレータで再生成**。run_manifest.yaml は scripts/manifest/*.yaml が正本（直接編集は build_run_manifest.py --write で巻き戻る）。
- shared/catalogs の evidence path はページ再配置に追随必要。

## 並行 Codex セッション対処（実績手法）
- 同一ツリーで codex.exe が稼働中はコミット/マージ禁止。**「8分間書き込みゼロ」をfindで監視**して静止後に増分を意味単位でコミット（今回3回発生、いずれも安全に取り込み）。worklog が書かれたら完了サイン。

## 残存（意図的に保持、全て main 未反映の独自内容あり）
- feat/book-knowledge-integration (34c, worktree book-knowledge) — 書籍知識統合、未着地
- feat/db-ops-optimization (13c, dbopt) / codex/db-baseline-safety-01 (12c) / -followup (3c) / chore/repository-current-state-organization (10c, worktree local-pr-quality-gate) / integrated-functional-repair 3本 (1/3/21c)
- これらの着地判断は別セッション課題。
