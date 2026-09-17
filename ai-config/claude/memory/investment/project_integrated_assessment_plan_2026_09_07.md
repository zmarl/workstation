---
name: project-integrated-assessment-plan-2026-09-07
description: 2026-09-07 に 5 本の評価文書を統合した「統合現状評価と改善計画」の所在と要点（ハーネス 30 日凍結・止める機構 2 つ・製品復帰・ODR-0038 草案）
metadata: 
  node_type: memory
  type: project
  originSessionId: 18e0a477-b9bf-4062-8b25-ed94690f19f2
  modified: 2026-09-07T03:08:10.998Z
---

2026-09-07、`D:\Dev\Investment_設計資料\統合現状評価と改善計画_2026-09-07.md` を作成（計画のみ、リポジトリ未変更）。5 本（現状評価／ハーネス縮減_追跡評価／ハーネス・worktree運用レビュー／開発停滞の根本原因と再起動案／現状アップデートレポート、すべて 09-07 付）を上書きする現在地の正本。

要点:
- 結論: 速度と記録は成功、着地と実運用が失敗。判断パイプライン 84 タスクが 8/11 から HOLD、決算閉ループ shadow 並走ゼロ、9 月 worklog 62 本中 Verifying 57。ハーネスは `scripts/dev+ci` 48,187 行・`tests/scripts` 71,935 行に増殖、8/23 以降のコミットの 62% がハーネス専用。
- 提案: **ODR-0038** を 1 本だけ出す（30 日凍結 9/8〜10/7、マージを止める機構は Ready gate 赤と人手境界の 2 つ、週次予算、Done の定義を「PC 反映 + Scheduler 登録」まで、HOLD 解除と shadow ON を 10 月中）。**ODR-0037 は株式数修復で採番済み**、**ODR-0030 が 2 ファイルで重複**。
- 今週の ODR 不要項目: `Read(.env)` deny（現状 0 件）、`index-strategy` 既定化（現状 unsafe-best-match）、docs 除外 tree hash、バックアップ 5 task 登録（manual_only 7/20〜）。
- `tests/scripts` 目標は階段（10/7 ≤40,000 → 11/30 ≤20,000 → 年末に 8,000 再判定）で 3 文書の不一致を解消。
- 唯一の外部期限: 11 月中旬 Q2 決算集中期（逃すと 2 月）。

**Why:** ハーネス ODR が 2 週間に 3 本出て効果測定前に次が来る周期になっていた。文書は事後にしか効かず、予算・停止機構の総量・完了定義で縛るしかないという 5 文書共通の見立てを 1 本にまとめた。

**How to apply:** 次のハーネス関連の依頼では、この文書の §5（Phase 0〜2）と §6（意思決定リスト A〜D）を起点にする。ODR を起票するなら番号は 0038。**`scripts/dev/harness_kpi.py` は 9/1（`9541cf7cf`）に `harness_status.py` への 5 行の転送用の殻になり、ODR-0018 の縮減 KPI（feat 比率・メタ比率・検査本数・tests/scripts 行数）を出さない**。実行に約 13 分かかり、出力は queue job 一覧のみ。OWNER_INTENT §3 と ODR-0018 §7 の参照は未更新。週次計測には git log / wc の 6 数字（§5.5）を使う。関連: [[feedback-rule-protects-something]]、[[feedback-ask-dont-infer-authorization]]、[[project-harness-redesign-phase0-2026-08-23]]。
