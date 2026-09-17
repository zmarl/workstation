---
name: bugs_vitest_mocked_api_type_strictness
description: vi.mocked(api.method) enforces real response types and breaks loose test fixtures; use mockOf() loose cast
metadata: 
  node_type: memory
  type: project
  originSessionId: 5e52f81c-15d6-4614-9863-83f189d25659
---

Desktop の vitest 共通 test-utils 化 (2026-07-12, feat/test-suite-slim) で判明した罠。

**問題**: `vi.mock("@/lib/api-client", () => makeApiClientMockModule())` でモジュールを差し替えても、`import { api } from "@/lib/api-client"` の **型** は実 api のまま（vi.mock は runtime のみ差し替え、compile-time 型は変えない）。そのため `vi.mocked(api.companyWatchlistMonitor).mockResolvedValue(fixture)` は fixture に **完全な response 契約** を要求し、部分的な fixture が `tsc` で 15/31 ファイル型エラー。移行前の bare `vi.fn()` は `Mock<(...args:any)=>any>` で loose だったため通っていた。

**解決**: `src/test-utils/api-client-mock.ts` に `mockOf(method: unknown): Mock` を追加（`method as Mock` で loose cast）。`const fooMock = mockOf(api.foo)` とすれば runtime は proxy の cached vi.fn、型は loose Mock で移行前の挙動を維持。全 30 ファイルを `vi.mocked(api.` → `mockOf(api.` に統一。

**共通 test-utils の設計** (`src/test-utils/`):
- `render.tsx`: `renderWithProviders(ui, {queryClient?})` = retry:false + mutations retry:false の QueryClientProvider ラッパ。`createTestQueryClient` / `createQueryWrapper`（renderHook 用）も export。react-refresh 警告回避のためコンポーネント export は置かない
- `api-client-mock.ts`: `makeApiClientMockModule(overrides?)` が `@/lib/api-client` の完全な差し替えモジュールを返す。`api` は Proxy で任意メソッドアクセス時に cached vi.fn を生成（列挙不要・API 契約変更に自動追随）。helper (isApiError/ApiError=MockApiError/request 等) は既定 stub、overrides で差し替え可

**移行レシピの要点**:
- `vi.mock(...)` factory から imported helper (`makeApiClientMockModule`) を参照可能（vitest 4.1、hoisting OK）。ただし `import { api }` は **`vi.mock(...)` の直後** に置く（前に置くと `Cannot access '__vi_import__' before initialization`）
- 元 factory に `isApiError: () => false` 等があれば `makeApiClientMockModule({ isApiError: () => false })` で保持
- `// @vitest-environment jsdom` docblock は先頭維持
- router/store/child component の非 api-client `vi.mock` は触らない

関連: [[feedback_react_refresh_export_separation]] [[bugs_vitest_reactquery_rejection]] [[project_test_speed_2026_07_11]]
