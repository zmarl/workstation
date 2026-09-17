---
name: reference_utf16_sql_files_unreadable
description: 一部の既存 DDL/YAML ファイルは UTF-16 BOM で Read/Edit ツールが空判定する — 新規ファイルで回避
metadata: 
  node_type: memory
  type: reference
  originSessionId: 7f9a7805-4c22-4abb-902a-78f9f25b1e23
---

`db/greenfield_postgres/60_ops_quality.sql` 等の一部既存 SQL や governance YAML は UTF-16 BOM 付きで保存されており、Read ツールが「empty (0 lines)」と誤判定し、Edit もできない（バイト数は数千あるのに中身が取れない）。

**回避策**: 既存 UTF-16 ファイルへ追記しようとせず、reg が `40_reg_notification_log.sql` のように専用ファイルを持つのと同じく **新規 SQL ファイル**を連番で作る。番号付き DDL は番号順に流れるため、FK 依存がなければ新規ファイルで問題なし。greenfield と foundation の両方に作成。

ただし全 YAML/SQL が UTF-16 ではない: `db/runtime_schema_governance_allowlist.yml` / `db/runtime_schema_closeout_registry.yml` / `scripts/run_manifest.yaml` / `scripts/register_schedules.ps1` は UTF-8 で Read/Edit 可能だった。読めるか個別に Read で確認してから判断する。

**How to apply:** Read が既知の非空ファイルを「empty」と返したら UTF-16 を疑い、追記でなく新規ファイル方式に切り替える。関連: [[bugs_posttooluse_hook_stdout_corruption]]
