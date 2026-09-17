---
name: bugs-vitest-reactquery-rejection
description: "Desktop vitest error-path tests flake with \"Error: boom\" when a useQuery rejects on mount — mock useQuery instead of the api-client"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b291d279-8fab-47c4-88ee-1f1c9886c5b3
---

Desktop (`desktop/`, vitest 4 + react-query v5 + React 19) の error 経路テストで、`api` をモックして `mockRejectedValue(new Error("boom"))` させ `useQuery` を実際に走らせると、テストが `Error: boom` で落ちる。コンポーネント自体は正しく error UI を描画している（`document.body.textContent` で確認済み）。vitest が react-query の on-mount rejection を「テスト失敗」として誤検知しているだけ。

**Why:** react-query はエラー時 `refetchOnMount` で必ず再フェッチするため、テスト内では常にライブな rejection が発生する。vitest v4 はこれを拾う。`process.on('unhandledRejection')` / `window` handler / `test.dangerouslyIgnoreUnhandledErrors` / QueryCache `onError` / `fetchQuery().catch()` いずれでも抑制できない。挙動はタイミング依存で、同じ Panel パターンでも通るファイルと落ちるファイルがある（ComplianceGatePanel も単独 error テストは落ちる。既存スイートは複数テストの warmup で偶然通っているだけ）。

**How to apply:** error/loading/empty 経路は `useQuery` 自体をモックして状態を同期返却する。ライブ rejection を発生させないので 100% 決定的。
```ts
const useQueryMock = vi.fn();
vi.mock("@tanstack/react-query", () => ({ useQuery: (o: unknown) => useQueryMock(o) }));
vi.mock("@/lib/api-client", () => ({ api: { xxx: vi.fn() } }));
// import はモックの後（vi.mock は hoist される）
useQueryMock.mockReturnValue({ data: undefined, isLoading: false, error: new Error("boom") });
```
`QueryClientProvider` は不要。data/empty/error/loading を各 state で同期テストできる。参照実装: `desktop/src/components/risk-command/RiskModeStrip.test.tsx` 他 [[business_model_index]] 系の panel テスト。
