---
name: project-test-speed-2026-07-11
description: "テスト高速化バッチ完了 (2026-07-11, PR"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2626d986-0a5c-46dc-a9b9-8e95f028586c
---

# テスト高速化 + 第2弾バッチ (2026-07-11〜12, PR #41〜#44/#46 全マージ済み)

**第2弾の着地 (2026-07-12)**: PR #43 thesis_tags 3経路+wizard（PFRM-TT-01 完結）+ VFU refresh 配線（DDL は staged 待機）/ PR #44 zero-output triage（計測欠落9修理・**ownership_collector が退役 raw.edinet_* を読み続け 0 件だった実バグ修理 → 8,770 positions 検出**・正規化層凍結 2026-02-22 を台帳記録）/ PR #46 CI 減量。**GitHub Actions 無料枠を使い切り課金しない方針が確定** → CI 不走時は「ローカルフル検証を PR コメントに証跡として残してマージ」が代替手順。ゾンビ workflow tdnet-notifier（クラウドからローカル DB 不達で全 run 失敗×平日6回）を削除、e2e の push 二重走を main 限定化、全 PR workflow に concurrency cancel-in-progress。
**残 handover**: staged DDL 適用（Codex チェーン着地後）/ EDINET 正規化層凍結の修理（Codex ゾーン）/ 24 消費者の raw.edinet_*→public.* 移行
**Windows タスク登録の方針 (2026-07-12 ユーザー決定)**: 登録すべきタスクは増え続けるので**後日ユーザーがまとめて一括登録**する。各セッションは register_schedules.ps1 へのエントリ追記まで行い（`register_schedules.ps1` 1 回の実行で全部拾える状態を維持）、登録実行の催促や個別の handover 起票はしない。一括時は skill `$scheduler-registration`

## 確定した数値（20コア機）
- pytest 収集単体 165s→43s / フル 5:20→逐次 4:11→**並列 1:48**（`-n auto --dist loadscope`）
- vitest 76s→~60s（happy-dom + threads、isolate 維持）

## 再利用可能な知見
1. **Windows の pytest 収集は per-item `Path.resolve()` が支配的**（13,989 item で 2 分）。`pytest_collection_modifyitems` では正規化文字列 prefix 比較を使う。収集フックにファイルシステム操作を置かない
2. **「xdist は逆効果」(2026-04 実測) の真因は per-worker 固定費**（収集+autouse fixture）。固定費を削れば並列が 2.3 倍勝つ。CI は db テストが共有 PG で衝突するため据え置き（per-worker DB 分離が前提）
3. **autouse fixture の sys.modules 全走査は O(テスト×モジュール)**。len(sys.modules) 変化時のみ再走査するキャッシュで除去（tests/conftest.py `_RSC_PATCH_TARGETS`）
4. **隠れ DB 依存テストの実証検出法**: `POSTGRES_DSN=到達不能 PGCONNECT_TIMEOUT=1` でフル並列を走らせ、落ちた分（40件）に `db`+`requires_db` を機械付与。CI（pg service）では走り続け、ローカルは skip。マーカー挿入はデコレータスタックの上に、`import pytest` は `from __future__` の後に
5. **vitest isolate:false は不採用と決定**: wall ~25s まで縮むが zustand store / fake timers / beforeAll の stubGlobal がファイル間リークし失敗が実行順依存化（実行ごとに失敗集合が変わる）。公式 zustand リセット+RTL cleanup+unstub でも残り 28。全ファイルのグローバル規律監査が前提。決定論優先で isolate:true + happy-dom + threads
6. **happy-dom 非互換の型**: style 属性 read-back 不可（CSS max() は style オブジェクトでも空）→ data 属性で契約明示 / window.confirm 未実装 → vi.stubGlobal / submit ボタン click が form submit を発火しない → fireEvent.submit / canvas 無し → cytoscape 系は per-file jsdom docblock
7. **テスト運用ルールを CLAUDE.md に固定**: 反復=触った領域のみ / focus --lf / コミット前 fast --parallel / PR 前フル並列（約2分）

## DDL 直列化の教訓（同日）
本番 alembic stamp が main 未マージの並行 revision（Codex チェーン 20260711_01..12）まで先行 → 他セッションは revision を作れない。**DDL 素材は `db/alembic/staged/` に置いて着地後に revision 化**する運用を新設（VFU-PERF-01 で初適用）。適用前に `SELECT version_num FROM alembic_version` で stamp と repo head の一致を確認すること
