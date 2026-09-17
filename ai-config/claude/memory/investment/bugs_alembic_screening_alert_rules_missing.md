---
name: alembic ops.screening_alert_rules テーブル CREATE 漏れ (resolved)
description: 20260509_02 の前段に CREATE TABLE revision を新設して解消済 (2026-05-10)
type: project
originSessionId: 5736fe78-8871-4487-beaa-a8d2f7f39094
---
# alembic ops.screening_alert_rules テーブル CREATE 漏れ (resolved 2026-05-10)

## 解決

新 revision `db/alembic/versions/20260509_01b_screening_alert_rules.py` を `20260509_01 → 20260509_02` の間に挿入し、`CREATE TABLE IF NOT EXISTS ops.screening_alert_rules ...` を追加。`20260509_02` の `down_revision` tuple を `(20260509_01b_screening_alert_rules, 20260508_20)` に張り替え。

`alembic upgrade head` が `20260509_08` (head) まで完走、Phase 5 4 業種 metric_keys (automotive_parts / gaming_entertainment / precision_optics / leasing_consumer_finance) seed 適用完了。

## 学び

- alembic chain で CREATE が抜けたまま ALTER が走るパターンは珍しいが、複数開発者が SQL 形式 (`db/foundation_postgres/`, `db/alembic_revisions/`) と Python 形式 (`db/alembic/versions/`) を併用していると発生する
- 復旧時は `IF NOT EXISTS` を使うと既に SQL 経由で適用済みの環境でも安全に再実行可能
- chain 編集は merge revision の `down_revision` tuple を編集するより、新 revision を間に挟むほうが graph 改変が最小

## 関連ファイル

- 解決 commit: (TODO) このセッションの commit
- 新 revision: `db/alembic/versions/20260509_01b_screening_alert_rules.py`
- 編集: `db/alembic/versions/20260509_02_alert_rule_precision_metrics.py`
- worklog: `docs/worklogs/20260510-business-model-phase5-landing-multistream.md`
