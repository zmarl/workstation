---
name: project-test-suite-slim-2026-07-12
description: "テストスイート減量バッチ完了 (2026-07-12, PR #48)。pytest 84→52s、静的推定を実測で2件反証、db レーン既存 rot 発見"
metadata: 
  node_type: memory
  type: project
  originSessionId: 5e52f81c-15d6-4614-9863-83f189d25659
---

# テストスイート減量・高品質化バッチ (2026-07-12, PR #48 マージ済み)

worklog: docs/worklogs/20260712-test-suite-slim.md。作業は origin/main 起点 worktree（feat/test-suite-slim、作業後削除済み）。

## 確定数値（20コア機）
- pytest フル並列 84s→**52s** (-38%)、fast 収集 ~30s→**12.8s**、fast 並列 ~38-45s。vitest 48s 維持（Phase 5 は保守性目的）
- 2大ホットスポット修理: official_samples の pack 辞書 O(docs×packs) 再構築 40s→0.6s / decision_api OpenAPI スキーマ9回再生成→モジュール内メモ化1回 ~25s→4s
- 冗長削減: daily_screener 145→99関数・disclosure CLI 60→44・db_contracts 53→27・EQL 46→41（実行ケースと pass/fail 集合は維持、-1,600行超）

## 再利用可能な知見
1. **静的推定は実測で裏取りしてから工事**: 本バッチで2件反証 — (a) pg_connection の per-test セットアップは実測 ~0.1s（baseline 適用は 00_schemas+10_reference の2ファイルだけ）で SAVEPOINT 移行の速度 ROI ゼロ → 中止 (b) 収集 ~50s のうち import は 5.9s のみ（支配項は pytest の item 走査機構）→ 遅延 import 工事不要
2. **`python -X importtime` を pytest で使うときは `-s` 必須**（capture が import ログの stderr を飲む。無いと startup 分しか出ない）
3. fast/focus レーンは audit 自動付与ルート（tests/scripts + tests/tools/quality）を `-m` deselect でなく **`--ignore` で収集から除外**（import + item 生成費が丸ごと消える）。全レーン `--durations=25 --durations-min=0.75` 常設
4. **parametrize 統合で file-size ratchet に当たる**: 凍結行数超過は registry 表のせいで微増しがち → fixture を package conftest へ移動+節を新ファイル分割で解決（daily_screener 2497→1899行）。同ディレクトリ subdir conftest に同名 fixture がある場合は**中身が非等価**なことがあるので流用前に diff
5. **vitest 共通化の罠**: `vi.mocked(api.x)` は実型を要求し部分 fixture が tsc エラー化 → loose cast の `mockOf()` ヘルパーで bare vi.fn() の緩さを維持。api-client モックは Proxy でアクセス時 vi.fn() 自動生成（契約変更に自動追随）
6. 新ゲート: `scripts/check_desktop_test_query_client_ratchet.py`（shrink-only、baseline 171ファイル）。desktop テストは `src/test-utils/` の renderWithProviders / makeApiClientMockModule 必須。作法正本は **docs/guides/testing.md**（CLAUDE.md/AGENTS.md から参照）

## Handover（未修理の発見事項）
- ~~db レーン既存 rot~~ → **2026-07-13 PR #51 で全面修理完了**（[[project-db-lane-rot-fix-2026-07-13]]）。以下は当時の記録:
- **db レーン既存 rot**: investment_test 実 PG に向けると 231/359 failed（既定はテスト用 DSN `postgres:postgres@localhost/investment_test` が認証不可で 359 全 skip、実行するには .env DSN の DB 名を investment_test に差し替えて POSTGRES_DSN export）。主因: EDINET raw→public 移行残（[[project-test-speed-2026-07-11]] の handover と同件・Codex ゾーン）/ tdnet 'Expected qualified table name' 77件 / reference kit 未収載の契約テーブル（raw.ingest_runs, ops.*, reg.*）
- db_contracts: latest view テスト1本が created_at 同値タイで flaky / "creates_expected_relation" 系22本は ensure_ 直呼びで常に fail の stale 群
- test_ideas_router が loadscope 並列で1回だけ落ちた（順序依存 flake 疑い、単独 green）

関連: [[project-test-speed-2026-07-11]] [[feedback-parallel-session-worktree]]
