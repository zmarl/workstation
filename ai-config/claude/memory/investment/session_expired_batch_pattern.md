---
name: session-based scraper の session_expired を batch signal として扱うパターン
description: cookie/API-key 切れによる silent 失敗を防ぐため、fetch 結果に session_expired 分類を追加し、連続検知で early-break、上位に degraded 伝搬する設計。
type: feedback
originSessionId: eccc8df5-b239-4e2a-9fc5-fe9ac66f3627
---
session-based scraper（cookie 再利用型や短期 API key 型）で認証切れが発生すると、個々の fetch は `None` / `no_data` を返し、呼び出し側からは「データがなかっただけ」に見えて silent に正常終了してしまう。これを防ぐ設計パターン。

**Why:** 2026-04-18 の nikkei_quick 再安定化で、session 期限切れが毎日 no_data 扱いで scheduler 上は success 終了し、運用が気づけない状態になっていた事実を踏まえて確立。同じ問題は kabutan / 将来の QUICK/Bloomberg/Refinitiv でも再発しうる。

**How to apply:** session auth を持つ scraper を作る / 触るときは、以下の 3 点セットを実装する:

1. **fetch に classified status を持たせる**: `FetchStatus` enum に `SUCCESS / NO_DATA / SESSION_EXPIRED / HTTP_ERROR` を用意し、HTML に `有料会員のみ` 文字列や `/login` redirect を検出したら `SESSION_EXPIRED` を返す。既存の `fetch()` は `fetch_classified()` の薄いラッパーにして後方互換。
2. **fetch_batch で連続 N 件 break**: `consecutive_session_expired` カウンタで連続検知し、閾値（nikkei_quick は 3）を超えたら残り全件スキップ。`batch_stats` に `session_expired=True`, `session_expired_count`, `session_expired_codes`, `session_expired_break` を必ず入れる。
3. **オーケストレータ層で degraded 伝搬**: `_run_sources` 等の batch 呼び出し側で `batch_stats.session_expired` を見て、source_result.status を `session_expired` に、ingest_run.status を `partial` に設定し、note に件数と break フラグを記録。success_count には含めない → 全 source が session_expired なら overall_status=`failed`、一部なら `partial_success`。

**参考位置:** `tools/market_data/consensus_collector/sources/nikkei_quick.py` の `NikkeiFetchStatus` / `fetch_classified` / `fetch_batch` と `main.py::_run_sources` の session_expired 分岐が参照実装。

**auth 予兆警告もセットで:** `BrowserCookieAuthManager.get_session_status()` は `session_warn_hours` を受けて expires_at 残時間がその値以下なら `status=expiring_soon` を返せる。auth-status CLI 経由で scheduler 前に予兆を拾える。
