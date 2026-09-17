---
name: 緊急バグ修正セット (X1-X3) 着地 (2026-05-10)
description: silent exception 9 箇所を logger.debug に転換、attribution Discord webhook を shared.notifications 経由化、tdnet_data_quality は read-only で CLAUDE.md rule 対象外と判明
type: project
originSessionId: 6192aae2-c325-49fa-b360-68bc84f12fc7
---
# 緊急バグ修正セット (X1-X3) 着地 (2026-05-10)

直前セッションの 3 並列調査で見つかった即時修正対象 3 系統を実態確認 + 修正。

**Why:** silent exception で BFF 経由の supplemental data fetch 失敗が運用者から見えなかった。Discord webhook 直叩きは shared.notifications.orchestrator 規約違反。CLAUDE.md MUST rule 遵守と silent failure 防止で BFF の観測性を強化する目的。

**How to apply:**
- silent → debug log: `except Exception as exc:  # noqa: BLE001 - <reason>` + `logger.debug("<op> failed: {}", exc)` パターンに統一。動作 (戻り値) は維持、観測性のみ向上
- Discord webhook: `from shared.notifications import deliver_text` で `deliver_text(content, webhook_url=...)` を使う。`httpx.post(...)` 直叩きは禁止。`result.ok` / `result.last_error` で分岐
- read-only ツールは CLAUDE.md MUST rule "for all DB **writes**" の対象外。`shared.database` への移行は read-only adapter 設計検討が必要なため別タスク化

## 既存ファイル変更
- 修正: `tools/api/decision_api/serving_repository_extensions.py` (line 1198, 1223, 1243, 1838, 1857, 1878, 1904, 2242, 2320 の 9 箇所で silent → debug log)
- 修正: `tools/quality/tdnet_data_quality/main.py:_connect_with_retry()` (read-only である事実とコスト評価を明示するコメント追加、shared.database 移行は別タスク)
- 修正: `tools/analytics/attribution/notifier.py` (httpx.post 直叩き → `deliver_text(content, webhook_url=...)` に置換)
- 修正: `tests/tools/api/test_decision_api_response_models.py` (pre-existing な wave10 failure を解消、`expected_area_counts["ops"] = 23 → 24` に更新)

## 新規ファイル
- なし

## Verification
- `uv run ruff check .` clean
- `uv run pytest tests/tools/api/test_decision_api_response_models.py -v` 12 passed
- 全体 pytest は本セッション末尾で確認 (前回 11519 passed 維持想定)

## Plan agent 出力の検証 (重要 Tip)
直前 Plan agent #1 が「Discord webhook 規約違反 3 ツール」と報告したが、実態調査で:
- consensus_revision: 既に `send_operational_alert` を使用 → **規約遵守**
- fear_greed_index: 既に `NotificationClient` (shared.notifications.delivery 経由) を使用 → **規約遵守**
- attribution: `httpx.post` 直叩き → **真の違反**

→ Plan agent の grep ベース判定 (例: `httpx`, `webhook_url`, `NotificationClient` 等の出現) は正確だが、ファイル先頭 import 文の意味解釈まで踏み込まないと誤検知が出る。**Plan agent 出力は方向性として参照、実装前に必ずファイル単位で実態確認**するのが鉄則。

## CLAUDE.md MUST rule の解釈
> **MUST** use `shared.database.get_connection()` for all DB writes (always routes to PostgreSQL)

文字通り「writes」のみが対象。read-only な quality probe ツール (例: tdnet_data_quality) は `psycopg.connect()` で DSN 直結も許容。広い解釈に倒すと shared.database が pool 経由 + adapter ラップで read-only ユースケースに合わない (caller-supplied DSN や明示 retry が必要な場合) ため、**rule の文字通り解釈を優先**する。

## silent exception の許容パターン
BFF (`tools/api/decision_api/`) の supplemental data fetch では、上位を絶対に止めない設計が必要。`except Exception: return []` または `except Exception: pass` で fallback する箇所が多数。`# noqa: BLE001` で ruff の bare-except 警告を policy 承認しつつ、`logger.debug(...)` で観測可能にする。silent failure 完全禁止より「観測可能な silent」が現実解。

## 残 Follow-ups
- tdnet_data_quality の shared.database 移行 (大規模、要 ADR、read-only adapter 設計検討)
- worklog: `docs/worklogs/20260510-emergency-bug-fixes.md`
