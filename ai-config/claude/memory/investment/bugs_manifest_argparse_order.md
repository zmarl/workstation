---
name: bugs-manifest-argparse-order
description: スケジューラ37タスクが「--json をサブコマンド後ろに置く」manifest 引数順バグで2026-02から毎回失敗していた (2026-07-03 修正)
metadata: 
  node_type: memory
  type: project
  originSessionId: 9f7b3013-0350-4c83-96ab-dfd07bcd2c35
---

# manifest 引数順バグ — 37 タスクが argparse「unrecognized arguments」で全滅していた

- **問題**: `scripts/run_manifest.yaml` の args が `analyze --json` のようにサブコマンド後ろにグローバルフラグを置いていたが、ツール側 CLI は `--json` をトップレベル parser に定義 → argparse が「unrecognized arguments」で即死。exit_monitor_am/pm・position_recorder・thesis_monitor・decision_runner・sizing_engine・behavioral・counterfactual・correlation・hidden_edge・stress_test・feedback loop・revision_predictor 等 **37 タスク**が最古 2026-02 から毎回 0.2〜0.9 秒で失敗し続けていた（= 学習ループ・出口監視・ポジション記録がほぼ全停止）。
- **原因**: CLI 共通化リフォームでグローバルフラグがトップレベルへ移動したのに manifest が追随しなかった。通知カバレッジが薄く（notification tracking 未導入群）誰も気づかず。
- **解決** (2026-07-03): 36 タスクの args を `--json <subcommand> ...` 順に修正（strategy_conflict_resolver は manifest 退役済み）。検証は `uv run python -m <module> <args> --help` の exit 0（副作用なしのパース検証）。revision_predictor 3 タスクは --json がツールに存在せず除去。secrets_audit だけは --json がサブコマンド側定義で `audit --json` が正。db_capacity_audit はサブコマンド消滅で `audit` を除去。
- **教訓**:
  - ツールの argparse 構造を変えたら manifest args の同一 PR 追随が必須
  - 「DONE duration_sec=0.2」の連続はパース即死のシグネチャ。runlog の duration も監視対象にすべき
  - `--help` を末尾に付けた実行はパース検証として副作用ゼロで使える
- 関連: [[project-decision-round3-2026-07]] [[bugs-feature-store-rollback]]
