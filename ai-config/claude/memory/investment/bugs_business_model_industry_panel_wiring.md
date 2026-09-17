---
name: bugs_business_model_industry_panel_wiring
description: Desktop 業種別ビジネスモデルパネルを CompanySnapshot に配線する手順と availability ゲートの勘所
metadata: 
  node_type: memory
  type: reference
  originSessionId: 867257d0-6d65-48fe-89f5-4aba2f857b02
---

Desktop の業種別ビジネスモデルパネル（`components/company/*Panel.tsx`）を CompanySnapshot「ビジネスモデル」ワークスペースへ配線する構造（2026-07-05, 37枚配線時に確立）。

**配線層（1パネルにつき触る箇所）**
1. `lib/company-tabs.ts`: SnapshotTab union + workspace 詳細リスト + DETAIL_TO_WORKSPACE + 表示ゲート
2. `pages/company-snapshot/tab-registry.tsx`: ENTRY_TAB_PRELOADERS（全て BusinessModelCanvasView 経由なので同一 preloader）
3. `pages/CompanySnapshot.tsx`: `activeTab === "bm-*"` → `<BusinessModelCanvasView activeTabId=... />` ディスパッチ
4. `components/company/BusinessModelCanvasView.tsx`: FrameworkBody のタブ分岐
5. `components/company/_business-model-framework-utils.ts`: INDUSTRY_FRAMEWORK_TABS（Phase 17 Wave D の availability連動タブストリップ）

**重要な勘所**
- `BusinessModelFrameworkId`（types/company.ts）は既に全 framework id を含み、`BusinessModelTabId = BusinessModelFrameworkId | ...`。tabId=framework_id にすれば union 拡張は不要。
- **表示ゲートは2系統**: 既存 industry タブは `suggested_template`（1社1値、`BUSINESS_MODEL_TEMPLATE_GATED_TABS`）。新規は `availability.status === "available"` 連動。複数パネルが同一テンプレートを共有する業種（retail_franchise 系）や template を持たない業種があるため、availability ゲート必須。
- availability は重い frameworks エンドポイント（`api.companyBusinessModelFrameworks`）にのみ在る。サマリ `companyBusinessModel` には無い。CompanySnapshot で BusinessModelCanvasView と**同一 queryKey** `["company-business-model-frameworks", code, {peers_limit:0}]` を張れば dedupe されて追加リクエスト無し。
- 37枚は SSOT `BM_INDUSTRY_AVAILABILITY_TABS`（company-tabs.ts）+ レジストリ `_business-model-industry-panels.tsx` に集約。個別 JSX 37 コピーを避けた。
- 全パネルの props は統一 `{ code, data: CompanyBusinessModelFrameworksResponse }`、ルート testid は `${kebab-framework-id}-panel`。
- knip 本番（`knip.production.json --production`）で Unused files が配線数だけ減る＝到達性の機械検証。`_dev/BusinessModelCatalog.tsx` は production グラフ外なので knip に無関係。

関連: [[business_model_index]] [[bugs_desktop_undefined_tailwind_tokens]]
