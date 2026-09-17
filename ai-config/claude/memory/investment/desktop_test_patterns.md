---
name: Desktop テストの共通 mock パターン
description: Desktop コンポーネントの vitest mock で `api-client` 経由のエラー表示を検証する際に必要な isApiError / QueryErrorBanner 経由の注意点
type: feedback
originSessionId: edc05df7-37fa-4380-adc2-fca1153ee060
---
Desktop コンポーネントのテストで useQuery の error パスを検証する場合、`CompanyDataStateNotice` → `QueryErrorBanner` → `isApiError` の経路を通る。

**Why:** QueryErrorBanner は `@/lib/api-client` から `isApiError` を import しているため、`vi.mock("@/lib/api-client", () => ({ api: {...} }))` のように `api` だけ偽装すると、`isApiError` 未定義で "No export is defined" のランタイム例外になる。また、error 表示は `fallbackTitle` ではなく分類後の message（素の Error なら `error.message` そのもの）が表示される。

**How to apply:**
1. api-client をモックする際は必ず `isApiError: () => false` も返す（何らかの boolean を返せばよい）
2. error 状態のアサーションは `findByRole("alert")` と `findByText(<Error.message>)` で検証。`fallbackTitle` で assert すると失敗する
3. 該当テスト例: `desktop/src/components/company/ScoringGuidanceCredibility.test.tsx`

Zustand store の状態を設定する場合は vi.mock ではなく `useAppStore.setState({ bffReachable: true, readToken: "tok" })` で直接書き換える（既存パターン: `InstrumentInputs.test.tsx`）。
