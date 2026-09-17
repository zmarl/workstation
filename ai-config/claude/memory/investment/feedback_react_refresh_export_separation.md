---
name: react-refresh: コンポーネントから定数/型/関数を *-utils.ts に分離
description: desktop component から非コンポーネント export を別ファイルに分離して Vite Fast Refresh 効率を保つパターン
type: feedback
originSessionId: 3f7b69d8-7eb1-4231-af78-5504e07be6d0
---
`react-refresh/only-export-components` 警告は、Vite Fast Refresh が「コンポーネントだけが export されているファイル」のみで HMR 更新を有効化するために出る。コンポーネントと一緒に型 / 定数 / 純関数が export されているとファイル全体が full reload になるため、これらを `*-utils.ts` に分離するのが既定パターン。

**Why:** 2026-05-03 セッションで desktop の lint 警告 37 件を整理した際、テンプレ系 11 ファイル + partner-display + CompanyHealthRadar + InvestmentDashboard で同じパターンが繰り返されていた。`trading-house-cluster-utils.ts` で既に同じ手法を採用していたが新規追加では未徹底だった。

**How to apply:**

1. テンプレ系コンポーネント (`templates/*.tsx`) で型 + 定数 + classify 関数を `*-utils.ts` (kebab-case) に分離する。命名は `{template-name}-utils.ts`
2. partner-display 系のように純関数が多いファイルは `*-utils.ts` を別建てし、コンポーネントは utils を import して再利用
3. test ファイルは utils ファイルから直接 import する (テンプレ `.tsx` 経由の re-export はしない)
4. `__test__` 名の export object はテストから参照されていないものは削除候補
5. re-export 形式 (`export * from "./utils"`) では only-export-components 警告は消えない。利用箇所を直接 utils import に切り替えること
6. CompanyHealthRadar のように内部で utils 関数を使うコンポーネントは、utils 側で関数を `export` し、コンポーネント側で import すること

**回避できないケース:** コンポーネント以外の export を保持したい場合 (default export 用途など) は eslint disable コメントで個別に外す。ただしテンプレ系では分離が標準。
