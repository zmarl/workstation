---
name: project-invariants-mechanism-removal-2026-08-20
description: "金融データ不変条件の機構を物理削除 (2026-08-20, PR #193)。ODR-0002が半分しか実行されておらずゲート実行68→44分。機構に巻き込まれていた保護4種の救出方法"
metadata: 
  node_type: memory
  type: project
  originSessionId: c288e354-4d4e-4325-9c0d-4bba4c1055cb
  modified: 2026-08-20T11:00:35.151Z
---

# 金融データ不変条件の機構を物理削除（2026-08-20、PR #193）

**ODR-0002（08-17）は半分しか実行されていなかった。** 退役として行ったのは
`run_check_suite.py` の検査一覧からの除外だけで、機構本体22ファイルと test 11ファイルは残した。
test は通常レーンで走るため**強制は一度も止まっていなかった**。

## 実害の実測（1セッション中に3回）

1. PR #191 が `sizing_engine/main.py` を12行変更 → `financial_data_invariants_runtime_contracts.py` の
   SHA-256 固定とずれ、**無改変 main で test 8件が赤**。`26450f07f` で打ち直して復旧（PR #192）
2. 直後に `routine_runner/main.py` でも同じ drift
3. `shared/db_contracts/` を触った PR が「機構へ新規登録せよ」と要求されて停止

**削除後: gate の t3-python が 68分 → 44分**（機構 test 群は1回26分）。

## 救出が必要だったもの（機構に巻き込まれていた無関係な保護）

| 対象 | 実体 | 対処 |
|---|---|---|
| Desk の読み取り専用境界 | 9 test のうち6件は「Desk の全ソースが書込可能な driver/pool を import せず動的 import で隠しもしない」の検証（22の回避経路） | 機構非依存で `test_cli.py` 内に再実装。176 passed |
| reg-llm タガーの hold | 2タスクが manual_only に留まる／`register_schedules.ps1` が再登録より先に登録解除する | ハッシュ照合2行だけ削除、他は維持 |
| ハーネス契約 test 8ファイル | **全T3レーンが `--ignore=tests/scripts` を持つため、機構のレーンが `--profile t3` 唯一の実行経路**。うち4ファイルは他に登録ゼロ | 新レーン `t3-runner-contracts`（plugin なし） |
| 並列ワーカー数固定 / レーン毎 bytecode cache | どちらも唯一の coverage が削除対象ファイル内 | `test_local_pytest_process_isolation.py` へ移設 |

## 削除の手順（依存順を守らないと82件が collection error）

1. **消費者 test の書き換えが先**。`disclosure_event_desk/test_cli.py`(81 tests) と
   `reg_llm_tagger/test_runtime_hold_contract.py` は module-level import。先に機構を消すと全滅
2. `run_local_pytest.py` の配線除去（782→541行、deselect 448件が通常レーンへ戻る）
3. 機構本体22 + test 11 の削除
4. 登録元: `check_framework_ci_gate_parity.py` / `development_test_selection.yaml` /
   `development_test_tiers.yaml` / `development_test_tier_runtime_identity.py` / `check_development_test_tiers.py`
5. 追随 test: tier 系2ファイル、`test_run_local_pytest.py`

**罠: 削除前に `git cat-file -e origin/main:<path>` で main 存在を確認する。**
`financial_data_invariants_runtime_test_contracts.py` を「新規ファイル」と誤認して丸ごと消しかけ、
`git diff --stat origin/main HEAD` の800行削除で気づいた。main に在るものは `checkout origin/main --` で戻す。

## 残ったもの

- `docs/contracts/financial-data-invariants.md`（ODR-0002 が設計契約として保存）と ODR 本体
- `tests/scripts/` の**既存赤135件**。元からゲート対象外（旧レーンは16ファイル allowlist、新レーンは8）。別課題
- `JPX-OI-INT-01` / `REG-LLM-INT-01` は**完了条件が未定**になった。旧条件が削除済みスクリプトを指していたため、
  振る舞いベースへ書き換えてから着手する

関連: [[project-worktree-inventory-cleanup-2026-08-16]] /
[[project-valuation-capital-landing-2026-08-17]] / [[project-stalled-fix-landing-2026-08-20]]
