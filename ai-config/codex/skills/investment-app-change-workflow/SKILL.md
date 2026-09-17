---
name: investment-app-change-workflow
description: "STUB (2026-07-18 移設済み): desktop / tools/api/decision_api / DB契約 / run_manifest をまたぐアプリ変更の workflow。正本はリポジトリの AGENTS.md と .agents/skills/ の scaffold 系スキルに移行済み。"
---

# Investment App Change Workflow (stub)

このスキルの内容は 2026-07-18 にリポジトリ側へ移設された。ここには古い手順を残さない。

作業条件に応じた参照先（一覧を一括必読にしない）:

1. `D:\Dev\Investment\AGENTS.md` — アプリ横断変更の境界契約・品質ゲートの正本
2. `D:\Dev\Investment\.agents\skills\bff-endpoint-scaffold\SKILL.md` — BFF エンドポイント追加
3. `D:\Dev\Investment\.agents\skills\ddl-migration-scaffold\SKILL.md` — DB スキーマ変更（alembic）
4. `D:\Dev\Investment\.agents\skills\desktop-component-scaffold\SKILL.md` — Desktop コンポーネント追加
5. `D:\Dev\Investment\.agents\skills\pr-ready-gate\SKILL.md` — gate→merge 手順

適用中の AGENTS.md / CLAUDE.md を優先する。非自明な実装またはログ作成依頼では worklog、該当する新規要素には scaffold、worktree/gate/統合を行う段階では pr-ready-gate を読む。調査・相談だけなら会話で回答し、保存や公開へ広げない。
