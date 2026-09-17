---
name: Business Model 業種別テンプレ B-1 〜 B-4.P2 全完了状態 + Wave A + Phase 1-4 完了 (40 テンプレ + 業種別詳細パネル 4 / 広告 KPI catalog seed / Supply Chain Wave 4)
description: 2026-05-04 時点で B-1〜B-4.P2 + Wave A + Phase 1-4 (Wave B-4 JReitSponsorshipPanel / 41 銘柄実機検証 + defect 修正 / 広告 KPI catalog seed / Supply Chain Wave 4 reclassifier rules 拡充) が完了。業種別詳細パネルは 4 種稼働 (Pharma/Telecom/Bank/J-REIT)。次セッションは広告 KPI observation 投入 + Supply Chain Wave 5 残ソース対応。
type: project
originSessionId: 306c9b80-f798-4770-bf1e-672b4aa3c581
---
ビジネスモデル図解の業種別テンプレ拡張プロジェクトのうち **B-1 (テンプレ追加 7 業種)** が 2026-05-02 完了、**B-2.1 / B-2.2 / B-2.3 / B-3 / B-4.P1 / B-4.P2** がすべて 2026-05-03 完了、**B-1.17〜B-1.31 (15 業種一括追加)** が 2026-05-04 完了、**B-1.32〜B-1.35 / B-1.36〜B-1.40** が 2026-05-05 完了 (38 テンプレ稼働)、**Wave A (J-REIT specialized + Wholesale general 新設、whitelist 拡充、手動切替 UI、coverage DDL)** が 2026-05-04 完了 (**40 テンプレ稼働 + whitelist 398 銘柄**)、**Phase 1-4 (Wave B-4 JReitSponsorshipPanel + 41 銘柄実機検証 + defect 修正 + 広告 KPI catalog seed + Supply Chain Wave 4)** が 2026-05-04 完了。**Wave H Phase 1+2 (テンプレ metadata の YAML SSOT 基盤 + textile_fiber pilot)** が 2026-05-04 完了。

## Wave H Phase 3+4 完了 (2026-05-04)

### Goal
A1 で構築した SSOT 基盤の上に残り 39 テンプレを全部 YAML 駆動化、business_model.py のテンプレ判定ハードコードを完全削除。テンプレ追加が「YAML 1 エントリ + `make codegen`」で完結する状態に到達。

### 成果物
- YAML SSOT 完成: `db/seeds/business_model/template_definitions.yaml` に全 40 件
  - whitelist_and_sector: 36 件 / sub_type_map: 1 件 (j_reit_specialized) / custom: 3 件 (j_reit_sponsorship / wholesale_general / electric_unbundling)
- codegen 拡張: sub_type_map matcher / `resolve_sub_type` / custom placeholder / `register_custom_predicate` / custom 用 whitelist field
- generated 3 ファイル拡張: `_template_rules_generated.py` 486 行（35→486）、`_template_metadata_generated.ts` 267 行（34→267）、`_industry_template_generated.ts` 11 行
- BFF business_model.py: 4854→4242 行（**-612 行**）、35 件の `_<NAME>_WHITELIST` / 35 件の `_match_<name>` / `_LEGACY_TEMPLATE_RULES` / `_J_REIT_SUB_TYPE_MAP` / `_J_REIT_SPECIALIZED_WHITELIST` を全削除。custom 3 件のみ `_custom_<id>` で残置
- Desktop 4 ファイル: `LegacyIndustryTemplate` 削除し `IndustryTemplate = "default" | IndustryTemplateGenerated` に簡略化、TEMPLATE_BADGE / TEMPLATE_LABEL / TEMPLATE_FALLBACKS の hardcoded 39 件を全削除し generated spread のみに
- codegen テスト 8→13 件 (sub_type_map round-trip / custom placeholder / resolve_sub_type / register_custom_predicate / 重複登録エラー)

### 設計判断
- electric_unbundling は code prefix matching ("95XX") のため declarative kind を増やさず custom escape hatch で残置（1 件のみ）
- MatchCustom に optional whitelist フィールドを追加: wholesale_general の negative-AND 用 whitelist を YAML SSOT に含めるため
- sub_type_map kind も WHITELISTS dict / `_<NAME>_WHITELIST` alias に含める: 既存テストが getattr で `_J_REIT_SPECIALIZED_WHITELIST` を取るため
- 短名 alias 4 件を business_model.py に追加: `_AUTO_OEM_WHITELIST = _AUTO_OEM_PYRAMID_WHITELIST` 等。テストは正規名でない短名で getattr するため互換維持
- custom predicate は generated 側で placeholder（lazy lookup）、business_model.py で `_register_custom_predicate` を module load 時に呼ぶ（循環 import 回避）
- 生成ファイルに `# ruff: noqa: E501` 追加: whitelist が大きいテンプレ（machinery 24 件 / electric_equipment 29 件 / food_value_chain 26 件 / it_services_saas 24 件）で WHITELISTS dict line が 270 文字に達するため

### 検証
- ruff: All checks passed
- pytest: 515 passed（codegen 13 件 + BFF regression 502 件）
- desktop typecheck: 0 errors / lint: 0 errors / vitest: 127 ファイル 518 件全通過
- 共通 10 銘柄 + textile_fiber 3 + j_reit_specialized 2 + wholesale_general 1 + electric_unbundling 1 = 13/13 で suggested_template 期待値一致
- resolve_sub_type: 8951=commercial / 8963=residential / 8967=logistics 正しく解決
- ハードコード grep 0 件: `_<NAME>_WHITELIST = frozenset(`, `_LEGACY_TEMPLATE_RULES`, `def _match_`, `_J_REIT_SUB_TYPE_MAP` 全て business_model.py から消失

### 次に着手 (A3 セッション、3 並列)
1. **Wave I**: BFF business_model.py 4242 行を機能別 6 module 分割（_template_rules.py / _coverage.py / _supply_chain.py / _frameworks/* / _industry_panels/* / _ad_metrics.py / api.py）
2. **Wave J**: Desktop 30 件の横並び 5 レーン系を `HorizontalLanes` プリミティブに統合（重複 ~8000 行を吸収）
3. **Wave N**: whitelist YAML lint（sub_sector_registry 整合）+ 3 銘柄以下テンプレの 5 銘柄以上拡充

### Worklog
`docs/worklogs/20260504-wave-h-phase3-4-ssot-complete.md`

---

## Wave H Phase 1+2 完了 (2026-05-04)

### Goal
テンプレ追加時に「BFF business_model.py 3 箇所 + Desktop 4 ファイル」の 5 箇所同期が必要だった構造を、`db/seeds/business_model/template_definitions.yaml` を SSOT にして codegen で BFF/Desktop に展開する形に置き換えた。Phase 1+2 では基盤と 1 件 pilot まで。

### 成果物
- SSOT: `db/seeds/business_model/template_definitions.yaml`（textile_fiber 1 件）
- 新規 codegen: `tools/dev/template_definitions_schema.py`（pydantic v2、`match.kind` discriminator 4 種＋ fallback enum）/ `tools/dev/template_codegen.py`（CLI、`--check` モード対応）
- 生成 3 ファイル（35 / 12 / 34 行）: `_template_rules_generated.py` / `_industry_template_generated.ts` / `_template_metadata_generated.ts`
- pilot 移行: `business_model.py` の `_TEMPLATE_RULES` を legacy + generated の merge 構造に、Desktop 4 ファイルは generated metadata の spread に
- codegen test 8 件、CI: ルート `Makefile` 新規 + `ci-test-lint.yml` の lint job に `template_codegen.py --check` step 追加

### 設計判断
- BFF predicate は declarative（`whitelist_only` / `whitelist_and_sector` / `sub_type_map` / `custom`）+ `custom` escape hatch で表現。Phase 3+4 で 35〜37/40 を declarative 吸収予定
- Desktop 側 generated は metadata 3 種（BADGE / LABEL / FALLBACKS）のみ。`TEMPLATE_RENDERERS` は React component import の HMR / 型推論を壊さないため手書き継続
- Phase 1+2 では legacy tuple + generated tuple の merge を `_GENERATED_INSERT_AFTER` anchor map で行う。Phase 3+4 で全件移行時に anchor map を空にして order ソートに切り替え可能
- prettier 不在のため codegen 自前で安定 LF + 2-space + 末尾改行を emit。pre-commit framework は新規導入せず、Makefile + GitHub Actions で gate

### 検証
- ruff: All checks passed
- pytest: 510 passed（codegen test 8 件 + 既存 BFF regression 502 件）
- desktop typecheck: 0 errors / lint: 0 errors / vitest: 183 passed
- 共通 10 銘柄 + textile_fiber 3 銘柄で `_suggest_business_model_template` の出力に regression なし
- `template_codegen --check` exit 0（YAML 編集 → 再生成漏れ検知 gate 機能）

### 次に着手（セッション A2 = Phase 3+4）
1. 単純 declarative で書ける ~25 件（paper_pulp / mining_extraction / petroleum_energy / tire_rubber / glass_ceramics / steel / non_ferrous / metal_products / machinery / electric_equipment / other_manufacturing / airline / securities / other_financial / construction / chemical_materials / food_value_chain / railway_network / hotel_leisure / game_f2p / ec_marketplace / it_services_saas / logistics_hub / shipping_fleet / insurance_three_margin）
2. 複数 sector_code ありで declarative ~10 件（auto_oem_pyramid / pharma_rd_structure / bank_funds_flow / electric_unbundling / retail_franchise / real_estate_developer / marine_agriculture_chain / precision_instruments / semiconductor_supply / telecom_three_layer）
3. sub_type_map: j_reit_specialized（codegen の sub_type_map matcher 出力を A2 で実装）
4. custom: trading_house_cluster / wholesale_general（negative-AND） / j_reit_sponsorship

### Worklog
`docs/worklogs/20260504-wave-h-phase1-ssot-pilot.md`

---

## Phase 1-4 完了 (2026-05-04 単一セッション)

### Phase 1: Wave B-4 JReitSponsorshipPanel
- 新規 panel (BankFundsFlowPanel と同流儀): `desktop/src/components/company/JReitSponsorshipPanel.tsx` + utils + tests
- gated tab 追加: `bm-j-reit-sponsorship` を `BUSINESS_MODEL_TEMPLATE_GATED_TABS` 経由で `j_reit_specialized` template 専用に
- sub_type 別表示分岐: portfolio ブロックのラベルを commercial/residential/logistics/infrastructure で切替、tenant ヒント表示
- 5 ブロック分類: sponsor / asset_manager / portfolio / custodian_finance / investor + 未分類レーン

### Phase 2: Wave A 完了 41 銘柄 実機検証 + defect 修正 2 件
- 検証スクリプト: `scripts/smoke_bm_templates.sh` (BFF curl で suggested_template / template_meta を一括検証)
- 41/41 銘柄が期待 template を返すことを確認
- **Defect 1 修正**: `_excluded_business_model_payload` が `suggested_template: "default"` をハードコードしていたため J-REIT specialized が遮断されていた → suggester + meta resolver を呼ぶよう修正
- **Defect 2 修正**: J-REIT 銘柄の sector_code が "9999" (東証 33 業種外) で stocks DB に格納されていたため whitelist match で sc 厳密チェックが阻害 → `_match_j_reit` / `_match_j_reit_specialized` の sc/sn 補助チェックを除去 (whitelist + コード帯 8951-8977 のみで判定)

### Phase 3: 広告 KPI を core.metric_catalog に seed (groundwork)
- alembic revision 20260504_04: `core.metric_catalog` に 8 メトリクス (`ad_revenue` / `cpm` / `cpc` / `impressions` / `clicks` / `advertisers` / `dau` / `mau`) を seed
- `_AD_METRIC_ALIASES` (BFF) と metric_key を完全一致させ、将来の observation 投入で `_find_ad_metrics` が即ヒットできる土台を整備
- **observation 投入は次セッション持ち越し** (raw.kpi_series / mart 経路のいずれにも該当データなし、IR 資料からの手動抽出が必要)

### Phase 4: Supply Chain Wave 4 — supply_chain_reclassifier rules 拡充
- `tools/analytics/supply_chain_reclassifier/rules.py`:
  - rnd_partner キーワード拡張: 旧帝以外の主要国立大学 + 主要私立 + 海外大 (MIT/Stanford 等) + 研究機関 (NICT / JAMSTEC / KEK 等)
  - 新規ルール追加: `jv` (priority 5) / `oem` (6) / `odm` (7)、distributor を 5→8 に再採番
  - public_procurement から `国立大学` / `公立大学` を除外 (大学は rnd_partner で個別名により分類)
- 新規テスト: `tests/tools/analytics/test_supply_chain_reclassifier_rules.py` (45 ケース)
- 既存テスト: `tests/tools/analytics/supply_chain_reclassifier/test_rules.py` を新分類意図に合わせて更新
- **J-PlatPat 共同出願 ingest tool は新規実装不要** (既に `tools/market_data/jplatpat_patents/` で CSV 半自動運用が稼働中)

### 検証
- ruff: All checks passed (0 errors)
- pytest: 10355 passed / 321 skipped (regression なし)
- desktop typecheck: 0 errors
- desktop lint: 0 errors / 29 warnings (pre-existing)
- 私の touched scope vitest: 554/554 passed

### worklog
- `docs/worklogs/20260504-bm-j-reit-sponsorship-panel.md`
- `docs/worklogs/20260504-bm-templates-wave-a-smoke.md`
- `docs/worklogs/20260504-ad-supported-metrics-catalog.md`
- `docs/worklogs/20260504-supply-chain-wave4-reclassifier-rules.md`

### 次セッション候補
- 広告 KPI observation 投入 (4324/4751/9449/2433 の DAU/MAU/広告売上を IR 資料から手動抽出 → `core.metric_observations` に extract_method='external_structured' で投入)
- Supply Chain Wave 5: jGrants 公共調達 / ニュース取引先 / 会社サイト導入事例 ingest 拡張
- AdSupportedFunnelPanel 自動 ingest 化 (`tools/analytics/disclosure_text_parser` 系の拡張)

---



## Wave A 完了 (2026-05-04)

実装ファイル一覧 (4 worklog):
- A-1: J-REIT Specialized + Wholesale General テンプレ新設 (`docs/worklogs/20260504-bm-templates-wave-a-1-jreit-wholesale.md`)
  - BFF: `_J_REIT_SPECIALIZED_WHITELIST` (19 銘柄、8951-8977 範囲) + `_J_REIT_SUB_TYPE_MAP` (commercial/residential/logistics) + `_WHOLESALE_GENERAL_WHITELIST` (4 seed) + `_resolve_template_meta` 関数 + response に `template_meta` フィールド
  - Desktop: IndustryTemplate 38→40、`JReitSubType` Literal、`CompanyBusinessModelTemplateMeta` interface、JReitSpecialized.tsx (5 レーン + sub_type バッジ)、WholesaleGeneral.tsx (Construction パターン踏襲)
  - tests: pytest 8 ケース + vitest 8 ケース新規、既存 sponsorship テスト 3 件を specialized 優先に更新
- A-2: 既存 38 テンプレ whitelist 拡充 (`docs/worklogs/20260504-bm-templates-wave-a-2-whitelist-expand.md`)
  - **Phase 0 (重要): regression suite** — `_WHITELIST_TO_TEMPLATE` mapping table を導入し、各 `_*_WHITELIST` を import して動的 parametrize で 226 ケース展開。順序変更耐性確保
  - Phase 1: SQL 抽出で Tier1+2 default 落ち 32 銘柄を特定 (sub_sector_registry 参照)
  - Phase 2: 14+ 業種の whitelist 拡充 (whitelist 179→398、+219 銘柄)
  - Phase 3: 既存 `*_excludes_*` テスト 8 件の代替コード差し替え
  - **sc 条件緩和**: `_match_game_f2p` に sc=3800 追加 (任天堂 7974 救済)、`_match_it_services_saas` に sc=9050 / sn "サービス" 追加 (リクルート 6098 救済)
- A-3: テンプレ手動切替 UI (`docs/worklogs/20260504-bm-templates-wave-a-3-template-override.md`)
  - `desktop/src/lib/template-override-store.ts` 新規 (Zustand persist、key=`investment-desktop-template-override`、`Record<code, IndustryTemplate>`)
  - `template-selector.ts::selectTemplate(model, suggested, override?)` 第 3 引数 (override は predicate を skip)
  - `BusinessModelDiagram.tsx`: `TemplateOverrideDropdown` (popover、全 40 テンプレ + auto に戻す)、「★ 手動」マーカー
  - `CompanySnapshot.tsx`: `resolveTemplateOverrideFromLocation` + URL `?template=<id>` → store sync (mount 時)
- A-4: coverage backlog DDL + --by-template + backfill cmd (`docs/worklogs/20260504-bm-templates-wave-a-4-coverage-metric.md`)
  - DDL: `analytics.business_model_coverage_backlog.suggested_template VARCHAR(64)` + partial index
  - Alembic revision `20260504_03_business_model_coverage_backlog_template.py` (`to_regclass` ガード付き)
  - `business_model_graph_coverage main.py`: matrix `--by-template` (per-template aggregation)、`backfill-template-suggestions` サブコマンド (BFF 直接 import で 1-shot 投入)
  - 動作確認: `--apply` で 2000 行更新済 (template_distribution 19 種)、matrix で 17+ template 別 issuer 数表示

KPI 達成状況:
- 業種テンプレ数: 38 → **40** (+2、j_reit_specialized + wholesale_general)
- whitelist 総数: 179 → **398** (+219、Q1 推奨通り 420-450 範囲)
- Tier1+2 default 落ち: 32 → **3** (97% 削減、残り 9984/6178/9735 は手動切替 override で救済可能)
- 検証: pytest 534 / ruff All passed / typecheck 0 errors / vitest 31 passed

設計判断 (Wave A):
- J-REIT specialized は 19 銘柄を whitelist 化、sponsorship を **legacy 保持** (Wave B-4 で sponsorship panel を specialized 配下に統合予定)
- BFF response に `template_meta` フィールド追加 (J-REIT sub_type、将来の sub_type 拡張に対応)
- TEMPLATE_RENDERERS dispatcher は `j_reit_specialized` を含めず、BusinessModelDiagram.tsx の dispatch 部で個別処理 (subType prop 渡しのため signature が異なる)
- override store は code 別永続化、predicate を skip して強制適用 (手動指定の意図尊重)
- backlog suggested_template は BFF `_suggest_business_model_template` を直接 import で 1-shot 投入 (DRY 原則)

次セッション (Wave B 着手時の前提):
- 実機検証は 5 銘柄推奨: 8951 J-REIT specialized / 8074 wholesale_general / 6098 it_services_saas (sc=9050 救済) / 7974 game_f2p (sc=3800 救済) / 9984 SBG (override で救済)
- Wave B-4 JReitSponsorshipPanel は specialized template の子パネルとして設計、sub_type 別の表示分岐を含める
- foundation 同期は不要 (greenfield 専有、Wave A-4 で確認済)

---

## 旧プロジェクト (B-1 〜 B-4.P2) サマリー

## 完了した B-1 (36 テンプレ稼働中)

| テンプレ名 | 対象銘柄 | 配置ファイル |
|---|---|---|
| auto_oem_pyramid (既存) | 7201/7203/7211/7267/7269/7270 | AutoOemPyramid.tsx |
| j_reit_sponsorship (既存) | 8951-8977 J-REIT range | JReitSponsorship.tsx |
| electric_unbundling (既存) | 95xx 電気・ガス | ElectricUnbundling.tsx |
| telecom_three_layer (B-1.2) | 9432/9433/9434 | TelecomThreeLayer.tsx |
| retail_franchise (B-1.3) | 3086/3382/7532/7649/8267/9831/9983 | RetailFranchise.tsx |
| trading_house_cluster (B-1.4) | 2768/8001/8002/8015/8031/8053/8058 | TradingHouseCluster.tsx + trading-house-cluster-utils.ts |
| shipping_fleet (B-1.5) | 9101/9104/9107/9110/9119 | ShippingFleet.tsx |
| pharma_rd_structure (B-1.6) | 4502/4519/4523/4528/4568 | PharmaRdStructure.tsx |
| insurance_three_margin (B-1.7) | 8630/8725/8766/8795 | InsuranceThreeMargin.tsx |
| bank_funds_flow (B-1.8) | 7186/8306/8316/8331/8411 | BankFundsFlow.tsx |
| game_f2p (B-1.9) | 7974/9697/9684/9766/3635/6460 | GameF2PFlow.tsx |
| ec_marketplace (B-1.10) | 4755/3092/2371/4385/4751 | EcMarketplace.tsx |
| logistics_hub (B-1.11) | 9064/9143/9070/9301/9302 | LogisticsHub.tsx |
| semiconductor_supply (B-1.12) | 8035/6857/6920/6273/7741 | SemiconductorSupply.tsx |
| food_value_chain (B-1.13) | 2502/2503/2802/2914/2269/2871 | FoodValueChain.tsx |
| chemical_materials (B-1.14) | 4188/4005/4063/4452/4901 | ChemicalMaterials.tsx |
| railway_network (B-1.15) | 9020/9021/9022/9001/9005/9007/9008/9009 | RailwayNetwork.tsx |
| hotel_leisure (B-1.16) | 4661/9722/9616/9603 | HotelLeisure.tsx |
| textile_fiber (B-1.17) | 3402/3401/3105 | TextileFiber.tsx |
| paper_pulp (B-1.18) | 3861/3863/3865 | PaperPulp.tsx |
| tire_rubber (B-1.19) | 5108/5101/5110 | TireRubber.tsx |
| glass_ceramics (B-1.20) | 5201/5202/5301/5333/5332 | GlassCeramics.tsx |
| non_ferrous (B-1.21) | 5713/5707/5711/5803/5802 | NonFerrous.tsx |
| metal_products (B-1.22) | 5938/5947/5949 | MetalProducts.tsx |
| machinery (B-1.23) | 6301/6326/6361/6473 | Machinery.tsx |
| other_manufacturing (B-1.24) | 7912/7951/7832/7867 | OtherManufacturing.tsx |
| securities (B-1.25) | 8604/8473/8628/8616 | Securities.tsx |
| other_financial (B-1.26) | 8593/8591/8439/8424 | OtherFinancial.tsx |
| construction (B-1.27) | 1801/1802/1803/1812/1820 (ゼネコン 5 社、1925 大和ハウス除外) | Construction.tsx |
| petroleum_energy (B-1.28) | 5020/5021/5019 | PetroleumEnergy.tsx |
| steel (B-1.29) | 5401/5411/5406 | Steel.tsx |
| airline (B-1.30) | 9201/9202 | Airline.tsx |
| electric_equipment (B-1.31) | 6501/6502/6503/6701/6702/6981 (sector 3650 で semi と whitelist 完全分離) | ElectricEquipment.tsx |
| real_estate_developer (B-1.32) | 8801/8802/8804/8830 (sc=8050) + 1925/1928 (sc=2050、住宅メーカー) | RealEstateDeveloper.tsx |
| marine_agriculture_chain (B-1.33) | 1301/1332/1333/1379/1381 (1377 サカタは種苗で別構造のため除外) | MarineAgricultureChain.tsx |
| mining_extraction (B-1.34) | 1605/1662/1518 (sc=1050、petroleum_energy sc=3300 と完全分離) | MiningExtraction.tsx |
| bank_funds_flow (B-1.35 拡充) | 7186/8306/8316/8331/8411 + 7167/8355/8377/8418/8385 (主要地銀 5 行追加、計 10 行) | BankFundsFlow.tsx (既存) |
| precision_instruments (B-1.36) | 4543/6869/7733/7752/7731/7762 (sc=3750 精密機器、半導体製造装置 sc=3650 と whitelist 完全分離) | PrecisionInstruments.tsx |
| it_services_saas (B-1.36) | 4307/9613/4716/4684/9719/4733 (sc=5250 情報・通信業、telecom/game/ec と whitelist 完全分離) | ItServicesSaas.tsx |
| food_value_chain (B-1.36 拡充) | 既存 6 + 2801/2810/2811/2002 (キッコーマン / ハウス食品 / カゴメ / 日清製粉、計 10 行) | FoodValueChain.tsx (既存) |
| chemical_materials (B-1.37 拡充) | 既存 5 + 4042/4061/4204/4203 (東ソー / デンカ / 積水化学 / 住友ベークライト、計 9 行) | ChemicalMaterials.tsx (既存) |
| pharma_rd_structure (B-1.38 拡充) | 既存 5 + 4503/4151/4587 (アステラス / 協和キリン / ペプチドリーム、計 8 行) | PharmaRdStructure.tsx (既存) |
| construction (B-1.39 拡充) | 既存 5 + 1860/1881/1893 (戸田建設 / NIPPO / 五洋建設、計 8 行) | Construction.tsx (既存) |
| electric_equipment (B-1.39 拡充) | 既存 6 + 6770/6479/6952 (アルプスアルパイン / ミネベアミツミ / カシオ、計 9 行) | ElectricEquipment.tsx (既存) |
| machinery (B-1.39 拡充) | 既存 4 + 6113/7013 (アマダ / IHI、計 6 行) | Machinery.tsx (既存) |
| retail_franchise (B-1.39 拡充) | 既存 7 + 2651/2782/9948 (ローソン / セリア / アークス、計 10 行) | RetailFranchise.tsx (既存) |
| hotel_leisure (B-1.40 拡充) | 既存 4 + 4680/4681 (ラウンドワン / リゾートトラスト、計 6 行) | HotelLeisure.tsx (既存) |
| logistics_hub (B-1.40 拡充) | 既存 5 + 9075/9081 (福山通運 / 神奈川中央交通、計 7 行) | LogisticsHub.tsx (既存) |
| bank_funds_flow (B-1.40 第二弾拡充) | 既存 10 + 8336/8359/8338 (武蔵野銀 / 八十二銀 / 筑波銀、計 13 行) | BankFundsFlow.tsx (既存) |

## アーキテクチャ要点

- **型**: `desktop/src/lib/types/company.ts::IndustryTemplate` に 11 値 (default 含む)
- **判定**: `tools/api/decision_api/serving/company/business_model.py::_TEMPLATE_RULES` リストに `(template_name, predicate)` ペア。先頭マッチ勝ち。新業種追加は append のみで完結
- **fallback**: `desktop/src/components/company/templates/template-selector.ts::TEMPLATE_FALLBACKS` Record。各テンプレが必要とする最小データ条件を予測関数で持つ
- **dispatcher**: `BusinessModelDiagram.tsx::TEMPLATE_RENDERERS` Partial Record。未実装テンプレは default にフォールバック
- **設計判断**: NodeKind 新規追加せず、segment ラベル + sublabel + tier で表現 (型変更の影響範囲を抑える方針)
- **ホワイトリスト方式**: 業種コード + 銘柄ホワイトリスト併用 (主要銘柄に限定し、業種誤判定を防止)
- **label 制約**: SVG truncate が subsidiary 13 文字 / segment 10 文字。テストデータと配置時に注意

## 検証 (B-1 完了時に通った内容)

```
uv run ruff check tools/api/decision_api/serving/company/business_model.py tests/tools/api/test_company_business_model_template.py
uv run pytest tests/tools/api/test_company_business_model_template.py tests/tools/api/test_company_business_model_frameworks.py tests/tools/api/test_company_business_model_graph.py
cd desktop && npm run typecheck
cd desktop && npm run test -- --run src/components/company/templates/ src/components/company/BusinessModelDiagram.test
```

結果: ruff All checks passed / pytest 43 passed / typecheck 0 errors / vitest 13 files 49 tests passed

## B-2.1 完了 (2026-05-03)

実装ファイル一覧:
- DDL: `db/greenfield_postgres/77_pharma_pipeline.sql`、`db/foundation_postgres/77_pharma_pipeline.sql`、`db/alembic/versions/20260503_01_pharma_pipeline.py`、`db/alembic_revisions/20260503_001_pharma_pipeline.sql`
- 抽出ツール: `tools/analytics/pharma_pipeline_extractor/` (5 ファイル + tests + samples/4568_daiichi_sankyo.json)
- BFF: `business_model.py::get_company_pharma_pipeline`、`_company.py` ラッパー、`serving_repository.py` 再エクスポート、`routers/company.py` の `/api/v1/company/{code}/pharma-pipeline`
- Desktop: 型 (`PharmaPipelinePhase`/`PharmaPipelineEntry`/`CompanyPharmaPipelineResponse`)、`api.companyPharmaPipeline`、`queryKeys.company.pharmaPipeline`、`PharmaPipelinePanel.tsx` + `.test.tsx`、`BusinessModelCanvasView.tsx` に Pipeline タブ条件付き追加
- 実 DB に 4568 第一三共サンプル 7 化合物投入済 (Discovery〜Approved + withdrawn 全フェーズ)
- 検証: ruff All checks passed / pytest 47 passed / typecheck 0 errors / vitest 16 passed
- worklog: `docs/worklogs/20260503-pharma-pipeline-panel.md` (Full mode)

## B-2.2 完了 (2026-05-03)

実装ファイル一覧:
- 新規: `desktop/src/components/company/TelecomLayerPanel.tsx` + `.test.tsx`
- 修正: `desktop/src/components/company/templates/TelecomThreeLayer.tsx` (`LAYER_DEFS` / `LayerKey` / `classifySegmentLayer` を export 化、SVG 図解とテーブルパネルでキーワードを共有)
- 修正: `desktop/src/components/company/BusinessModelCanvasView.tsx` (`telecom_layer` サブタブ統合、`suggested_template === "telecom_three_layer"` 条件で表示)
- データ源: `companyBusinessModelFrameworks.business_model.segment_groups` を 3 層 (Network/Device/Content) + 未分類レーンに集計、各層で売上 / 営業利益 / 構成比を表示。BFF 拡張なし
- 計画書当初の「契約数 / ARPU」は DB に該当テーブル無く実装不能のため不採用、**売上 + 営業利益 + 構成比**にダウングレード（`segment_financial_facts` の既存メトリクスのみ利用）
- 検証: typecheck 0 errors / vitest 3 files / 20 tests passed / lint 0 errors
- worklog: `docs/worklogs/20260503-telecom-layer-panel.md` (Lite mode)

## B-2.3 完了 (2026-05-03)

実装ファイル一覧:
- 新規: `desktop/src/components/company/BankFundsFlowPanel.tsx` + `.test.tsx`
- 修正: `desktop/src/components/company/templates/BankFundsFlow.tsx` (`BANK_SEGMENTS` / `BankSegment` を export 化、`classifyBankSegment(label, sublabel)` を新設、SVG 図解とテーブルパネルでキーワードを共有)
- 修正: `desktop/src/components/company/BusinessModelCanvasView.tsx` (`bank_funds` サブタブ統合、`suggested_template === "bank_funds_flow"` 条件で表示)
- データ源: `companyBusinessModelFrameworks.business_model.segment_groups` を 4 ブロック (預金/貸出/手数料/Treasury) + 未分類レーンに集計、各ブロックで売上 / 営業利益 / 構成比を表示。BFF 拡張なし
- 計画書当初の「NIM / 手数料率 / 預貸率」は `core.segment_financial_facts` / `core.metric_observations` / `raw.kpi_series` のいずれにも非存在のため不採用、**売上 + 営業利益 + 構成比**にダウングレード（B-2.2 と同方針）
- 検証: typecheck 0 errors / vitest 4 files / 28 tests passed / lint 0 errors
- worklog: `docs/worklogs/20260503-bank-funds-flow-panel.md` (Lite mode)

## B-3 完了 (2026-05-03)

実装ファイル一覧:
- 新規: `desktop/src/lib/business-model-viewpoint-store.test.ts` (4 ケース: 初期値 self / setViewpoint / toggle / LocalStorage persist 動作確認)
- 修正: `desktop/src/lib/business-model-viewpoint-store.ts` — Zustand v5 + persist middleware 化、`name: "investment-desktop-business-model-viewpoint"`、partialize で viewpoint のみ永続化（`useFocusStore` パターン踏襲）
- 修正: `desktop/src/components/company/CompanyMajorPartners.test.tsx` — vi.mock に `companySupplyChainReverse` 追加、`useBusinessModelViewpointStore` を import + beforeEach で reset、reverse 系 4 ケース追加（API 経路切替 / 空状態文言 / クリック切替 / aria-selected 追従）
- 修正: `docs/decisions/supply-chain-relationship-coverage.md` — Wave 3 セクションに「Desktop Reverse View Rendering 完了状態」サブセクション追記（配置 / 状態管理 / トグル UI / 検証銘柄 / テスト coverage を明記）
- 検証: typecheck 0 errors / vitest 2 files / 23 tests passed / lint 0 errors
- worklog: `docs/worklogs/20260503-supply-chain-reverse-finalize.md` (Lite mode)
- 設計判断: ADR は新規 `supply-chain-reverse-view.md` を作らず既存 `supply-chain-relationship-coverage.md` に追記（Wave 3 として既に endpoint 仕様が記載済のため）
- ~~実機検証（7203 / 6758）は次セッション持ち越し~~ ✅ 2026-05-03 closeout: BFF API レスポンス確認完了。3116 トヨタ紡織で reverse 機能が DB レイヤで動作することを確認 (suppliers 1 件で 7203 ヒット)。7203 / 6758 自身の reverse データ未投入は別 Wave (supply chain coverage 拡張) で扱う。worklog: `docs/worklogs/20260503-bm-smoke-followups.md`

## B-4.P1 完了 (2026-05-03)

実装ファイル一覧:
- 新規: `desktop/src/components/company/BusinessModelMiniSummary.tsx` (~175 行) + `.test.tsx` (5 ケース)
- 修正:
  - `desktop/src/lib/company-tabs.ts` — `SnapshotTab` から `canvas` 削除、8 個の bm-* タブ追加。`SnapshotWorkspaceTab` に `business-model` 追加（fundamental の直後）。4 mapping 同期更新
  - `desktop/src/components/company/BusinessModelCanvasView.tsx` (920 → 967 行) — `BusinessModelTabId` を export 化し `"diagram"` / `"frameworks"` を追加、`activeTabId?` + `overview?` prop 追加で外部制御モード化、`FrameworkBody` に diagram / frameworks ケース追加、`FrameworksAccordion` 関数新設（4 セクション縦並び）、外部制御時はタブバー非表示
  - `desktop/src/pages/CompanySnapshot.tsx` — `resolveSnapshotTabFromLocation()` に `?tab=canvas` → `bm-canvas` フォールバック、`ENTRY_TAB_PRELOADERS` を 8 タブに展開、`isBusinessModelTab` を `activeWorkspaceTab === "business-model"` 判定に変更、旧 canvas dispatch を 8 個の bm-* dispatch に置換（各 dispatch で activeTabId + overview prop を渡す）
  - `desktop/src/components/company/CompanyOverviewTab.tsx` L843 — `BusinessModelDiagram` を `BusinessModelMiniSummary` に置換
  - `desktop/src/pages/CompanySnapshot.test.tsx` — BusinessModelCanvasView mock を activeTabId 露出版に拡張、既存 canvas タブテストを bm-canvas フォールバック確認に書換、bm-diagram / bm-supply-chain / bm-frameworks の dispatch テスト 3 ケース追加
  - `desktop/src/components/company/BusinessModelCanvasView.test.tsx` — 外部制御モード 3 ケース追加（タブバー非表示 / frameworks の 4 セクション縦並び / diagram の BMD レンダリング）
- 設計判断:
  - フル B-4.P1 を 1 セッションで実施（B-4.P1a/P1b 分割せず）
  - OverviewTab BMD は mini summary 化（リンク付き、bm-diagram に遷移）
  - BusinessModelCanvasView 本体は分割せず、`activeTabId` prop で外部制御モードを追加する最小侵襲設計
  - `bm-frameworks` は 4 セクション縦並び（アコーディオン化は後付け可能）
  - 後方互換: 旧 `?tab=canvas` URL は `bm-canvas` にフォールバック
- 検証: typecheck 0 errors / vitest 4 files / 52 tests passed / lint 0 errors
- worklog: `docs/worklogs/20260503-business-model-workspace.md` (Full mode)
- ~~実機検証（7203 / 4568 / 9432 / 8306）は次セッション持ち越し~~ ✅ 2026-05-03 closeout: 全 4 銘柄で suggested_template が想定通り判定されることを BFF API で確認 (7203→auto_oem_pyramid, 4568→pharma_rd_structure, 9432→telecom_three_layer, 8306→bank_funds_flow)。pharma-pipeline は 4568 で 7 化合物応答、segment_groups は 9432 で 4 件 / 8306 で 9 件返却。worklog: `docs/worklogs/20260503-bm-smoke-followups.md`

### B-4.P1 visible 判定改善 closeout (2026-05-03)

実機検証時に「銀行銘柄でも bm-pipeline / bm-telecom-layer タブが見えてしまい、クリックすると空のパネルが出る」課題を解消:

- 新規: `desktop/src/lib/company-tabs.test.ts` (`workspaceVisibleTabs` の 7 ケース)
- 修正: `desktop/src/lib/company-tabs.ts` — `workspaceVisibleTabs(workspace, suggestedTemplate)` ヘルパーを export 追加。`BUSINESS_MODEL_TEMPLATE_GATED_TABS` で bm-pipeline → pharma_rd_structure / bm-telecom-layer → telecom_three_layer / bm-bank-funds → bank_funds_flow の対応を定義
- 修正: `desktop/src/pages/CompanySnapshot.tsx` — `companyBusinessModel` query を `useQuery` で購読 (enabled: `readyForRead && !!code && isBusinessModelTab` でゲート、業務外 workspace では発火しない)。タブバーの `tabs` prop に `workspaceVisibleTabs(activeWorkspaceTab, businessModelSuggestedTemplate)` を渡してフィルタ
- 修正: `desktop/src/pages/CompanySnapshot.test.tsx` — suggested_template 別タブ表示テスト 4 ケース追加 (null / pharma_rd_structure / telecom_three_layer / bank_funds_flow)

設計判断:
- ゲート対応表 (`BUSINESS_MODEL_TEMPLATE_GATED_TABS`) は company-tabs.ts に co-locate (snapshot タブレジストリと一緒に保守)
- businessModelQuery は `isBusinessModelTab` でゲート (他 workspace のテストへ影響を波及させない、cache 経由で snapshot core から事前にデータが入っていれば即時反映)
- URL 直アクセス (`?tab=bm-pipeline` を 8306 で開く等) は意図的に許容 — タブバーには出ないが、内部 BusinessModelCanvasView の空判定で empty CTA が出るので問題なし

検証: typecheck 0 errors / vitest 1214 tests (275 files) all pass / lint 0 errors

worklog: `docs/worklogs/20260503-bm-workspace-visible-tabs.md` (Lite mode)

## B-4.P2 完了 (2026-05-03)

実装ファイル一覧:
- 新規: `desktop/src/components/company/AdSupportedFunnelPanel.tsx` (~155 行) + `.test.tsx` (3 ケース)
- 修正:
  - `tools/api/decision_api/serving/company/business_model.py` — `_BUSINESS_FRAMEWORK_LABELS` に `"ad_supported": "Ad-Supported"`、`_AD_KEYWORDS` (16 語) と `_AD_METRIC_ALIASES` (8 メトリクス) 定数、`_find_ad_metrics` / `_build_ad_supported_framework` 関数、frameworks dict / availability list / `_excluded_business_model_frameworks_payload` に統合
  - `tests/tools/api/test_company_business_model_frameworks.py` — 既存 2 ケース拡張 + 新規 1 ケース (`test_business_model_frameworks_ad_supported_candidate_via_keyword`)
  - `desktop/src/lib/types/company.ts` — `BusinessModelAdSupportedFramework` interface 追加、`frameworks.ad_supported` 必須化、`BusinessModelFrameworkId` に追加
  - `desktop/src/components/company/BusinessModelCanvasView.tsx` — `FrameworksAccordion` に 5 番目として AdSupportedFunnelPanel 追加
  - `desktop/src/components/company/BusinessModelCanvasView.test.tsx` — `buildFrameworks` fixture と availability に ad_supported 追加、frameworks accordion テスト assert を 5 セクション化
  - `desktop/src/components/company/BusinessModelSupplyChainPanel.test.tsx` / `CompanyBusinessModelCoverageChips.test.tsx` — fixture に ad_supported 追加（typecheck 解消）、coverage chip カウントを `4/5` → `4/6`
- 設計判断:
  - 専用 SnapshotTab は追加せず `bm-frameworks` accordion 内に統合（5 セクション縦並び）
  - candidate 判定: keyword (16 語) + sector_code (5250 or 9050) の OR、ホワイトリスト併用なし
  - 広告 KPI は当面 DB 未整備、metrics は常に空、is_candidate=true で status="partial"（pharma_rd と同方針）
  - funnel 3 column: users←customer_segments / inventory←key_resources / advertisers←key_partnerships
- 検証: ruff All checks passed / pytest 7 passed / typecheck 0 errors / vitest 4 files / 18 tests passed / lint 0 errors
- worklog: `docs/worklogs/20260503-ad-supported-funnel.md` (Lite mode)
- ~~実機検証（4324 / 9449 / 4751 / 2433）は次セッション持ち越し~~ ✅ 2026-05-03 closeout: 全 4 銘柄で sector_code が 5250 (情報・通信業) / 9050 (サービス業) のいずれかにヒット、is_candidate=true で status="partial" を確認。判定条件補完は不要。Canvas blocks 未生成のため funnel が空表示なのは想定どおり (status="partial")。worklog: `docs/worklogs/20260503-bm-smoke-followups.md`
- ~~bm-frameworks のアコーディオン化 (5 セクション縦並び → 折りたたみ可能 UI)~~ ✅ 2026-05-03 closeout: `desktop/src/lib/frameworks-accordion-store.ts` 新規 (Zustand v5 + persist, key=`investment-desktop-frameworks-accordion`)、`BusinessModelCanvasView.tsx` 内に AccordionSection 追加 (`▸`/`▾` テキストアイコン + StatusBadge + aria-expanded/aria-controls)、初期展開は value_chain と five_forces のみ。vitest: store 4 ケース + BusinessModelCanvasView 拡張 4 ケース pass。worklog: `docs/worklogs/20260503-bm-frameworks-accordion.md`

## 実機検証 closeout で発見した defect 修正 (2026-05-03)

実機検証セッション中に Telecom/Bank 業種別詳細パネルの分類精度問題が発覚し、即時修正:

- **Telecom**: 9432 NTT 実セグメント "総合ICT" / "地域通信" / "ｸﾞﾛｰﾊﾞﾙ･ｿﾘｭｰｼｮﾝ" が `classifySegmentLayer` で全て未分類になっていた
- **Bank**: 8306 三菱UFJ メガバンク事業本部名 "コーポレートバンキング事業本部" / "グローバルCIB事業本部" / "ウェルスマネジメント事業本部" が `classifyBankSegment` で全て未分類になっていた

実装ファイル一覧:
- 新規: `desktop/src/lib/kana-normalize.ts` + `.test.ts` — 半角カタカナ → 全角カタカナ正規化ユーティリティ (濁点・半濁点・中点対応、6 ケース)
- 修正: `templates/TelecomThreeLayer.tsx` LAYER_DEFS — Network レーンに "通信事業" / "地域通信" / "ICT" 追加、`classifySegmentLayer` で `normalizeHalfWidthKatakana` 適用
- 修正: `templates/BankFundsFlow.tsx` BANK_SEGMENTS — loan に "コーポレートバンキング" / "コマーシャルバンキング" / "CIB" / "法人ファイナンス" 追加、fee に "ウェルスマネジメント" / "プライベートバンキング" / "資産運用" / "信託" 追加、`classifyBankSegment` で `normalizeHalfWidthKatakana` 適用
- 拡張: `templates/TelecomThreeLayer.test.tsx` (`classifySegmentLayer` の 9432 実 segment 名 3 ケース)、`templates/BankFundsFlow.test.tsx` (`classifyBankSegment` の 8306 実 segment 名 3 ケース)

検証: typecheck 0 errors / vitest 1187 tests (270 files) all pass / lint 0 errors / pytest 38 passed (api/business_model_*)

副次的な学び:
- BFF が Scouter ソースから返す segment_name は半角カタカナを含むことがあるため、UI 側の keyword matching では `normalizeHalfWidthKatakana` を通すのが標準パターン
- Bank の事業本部別セグメントは個人銀行業務寄りの語彙では拾えないため、メガバンクの組織別セグメント名 (CIB / ウェルスマネジメント等) を追加する必要があった

worklog: `docs/worklogs/20260503-bm-smoke-followups.md` (Lite mode)

## B-1.9 / B-1.10 / B-1.11 / B-1.12 完了 (2026-05-03)

実装ファイル一覧 (4 業種共通の touch list):
- 新規 .tsx: `GameF2PFlow.tsx` / `EcMarketplace.tsx` / `LogisticsHub.tsx` / `SemiconductorSupply.tsx` (244-268 行)
- 新規 .test.tsx: 4 ファイル (各 ~90 行、4 ケース構成: SVG render / 参考スタブ / 分類 / classify ロジック)
- 拡張: `desktop/src/lib/types/company.ts` (IndustryTemplate に 4 値)、`templates/template-selector.ts` (TEMPLATE_FALLBACKS に 4 entry)、`BusinessModelDiagram.tsx` (import + RENDERERS + BADGE)、`BusinessModelMiniSummary.tsx` (TEMPLATE_LABEL に 4 entry)、`tools/api/decision_api/serving/company/business_model.py` (whitelist 4 + match 4 + RULES に 4 行)、`tests/tools/api/test_company_business_model_template.py` (8 ケース新規 + 9143 を 9001 に変更)

設計判断:
- ノード kind 追加なし（既存 segment/customer/supplier/distributor/subsidiary/affiliate/logistics/rnd_partner/regulator で表現）
- `_TEMPLATE_RULES` 順序: telecom (5250/9432/9433/9434) → game_f2p (5250/任天堂等) → ec_marketplace (5250/楽天等) → logistics_hub (5050/5200) → semiconductor_supply (3650)
- logistics_hub は陸運業 5050 + 倉庫運輸関連業 5200 の 2 sector_code を OR で対応、`classifyLogisticsLane` で 4 レーン (幹線/拠点/ラストワンマイル/倉庫) 統一分類
- 9143 SG HD は元々「shipping_fleet 除外テスト」で使われていたが logistics_hub に正しくマッチするようになり、既存テストを 9001 東武鉄道 (whitelist 外) に差し替え
- 半導体 whitelist は 8035/6857/6920/6273/7741 の 5 銘柄。6273 SMC / 7741 HOYA は厳密には装置でなく部材寄りだが供給網説明には妥当として whitelist 含めた

検証: ruff All checks passed / pytest 52 passed / typecheck 0 errors (新規部分。事前 AdvancedResultTable.tsx は無関係) / vitest 17 files / 65 tests passed / lint 0 errors

worklog: `docs/worklogs/20260503-business-model-templates-b1-9-to-12.md` (Full mode)

実機検証 (7974/9697/4755/4385/9064/9301/8035/6920) は次セッション持ち越し

## B-1.17 〜 B-1.31 完了 (2026-05-04)

15 業種一括追加 (ShippingFleet 系 10 + FoodValueChain 系 5)。実装ファイル一覧:
- 新規 30 ファイル: 各業種で `<Name>.tsx` (~210-260 行) + `<Name>.test.tsx` (~95 行、4 ケース)
- 拡張 6 ファイル: `desktop/src/lib/types/company.ts` (IndustryTemplate +15)、`templates/template-selector.ts` (TEMPLATE_FALLBACKS +15)、`BusinessModelDiagram.tsx` (import + RENDERERS + BADGE 各 +15)、`BusinessModelMiniSummary.tsx` (TEMPLATE_LABEL +15)、`tools/api/decision_api/serving/company/business_model.py` (whitelist 15 + match 15 + RULES に 15 行)、`tests/tools/api/test_company_business_model_template.py` (31 ケース新規 + 6981 を 6770 に変更)

設計判断:
- **electric_equipment は sector_code 3650 採用** (指示書の 3750 は誤記、3750 は精密機器)。既存 semiconductor_supply と whitelist 完全分離で共存。`_TEMPLATE_RULES` で semi を前段配置
- **construction の whitelist はゼネコン 5 社のみ** (1925 大和ハウスは住宅メーカー寄りで除外)
- **Phase 0 で 15 業種分の dispatcher + 空 frozenset whitelist + match 関数 + RULES を一括追加**してから、各 Phase で whitelist を実コードで埋める方式
- ShippingFleet 系 (10 業種) と FoodValueChain 系 (5 業種) の判定基準: 「明確な原料調達フェーズ」と「最終顧客への流通フェーズ」が segment と独立して語れるかどうか
- クロステンプレ干渉テスト: `test_electric_equipment_does_not_collide_with_semiconductor_supply` を追加 (8035 → semi、6501 → electric_equipment を assert)
- 既存テストの巻き込み: 6981 村田製作所が新 electric_equipment whitelist に入るため、`test_semiconductor_supply_excludes_non_whitelisted` の 6981 を 6770 アルプスアルパインに差し替え

検証: ruff All checks passed / pytest 91 passed (前 60 + 新規 31) / typecheck 0 errors (私の変更ファイル) / vitest 35 files / 142 tests passed + BusinessModelDiagram 5 tests passed / lint 私の変更ファイルは 0 errors / 15 warnings (既存テンプレと同種の react-refresh)

worklog: `docs/worklogs/20260504-business-model-templates-b1-17-to-31.md` (Full mode)

実機検証 (1801 / 3402 / 5108 / 5201 / 5713 / 5938 / 6301 / 6501 / 7912 / 8604 / 8591 / 9201 / 5020 / 5401) は次セッション持ち越し

## B-1.32 〜 B-1.35 完了 (2026-05-05)

3 新業種テンプレ (real_estate_developer / marine_agriculture_chain / mining_extraction) + 銀行 whitelist 拡充 (5 → 10 銘柄) を一括追加。実装ファイル一覧:
- 新規 6 ファイル: `RealEstateDeveloper.tsx` / `MarineAgricultureChain.tsx` / `MiningExtraction.tsx` (各 ~280-310 行) + `.test.tsx` (各 4 ケース)
- 拡張 6 ファイル: `desktop/src/lib/types/company.ts` (IndustryTemplate +3)、`templates/template-selector.ts` (TEMPLATE_FALLBACKS +3)、`BusinessModelDiagram.tsx` (import + RENDERERS + BADGE 各 +3)、`BusinessModelMiniSummary.tsx` (TEMPLATE_LABEL +3)、`tools/api/decision_api/serving/company/business_model.py` (whitelist 3 + match 3 + RULES 3 行 + bank whitelist 5→10)、`tests/tools/api/test_company_business_model_template.py` (12 ケース新規 + 既存 3 ケース更新)

設計判断:
- **real_estate_developer の whitelist は sc=8050 OR sc=2050 の OR 条件**。8801/8802/8804/8830 は sc=8050、1925 大和ハウス / 1928 積水ハウスは sc=2050 (建設業) だが住宅分譲が中核なのでデベロッパ側で扱う。construction whitelist (1801-1820) には元から 1925/1928 は含まれていないので衝突なし
- **`_TEMPLATE_RULES` 挿入位置**: real_estate_developer は j_reit_sponsorship の **直後** (J-REIT は 8951-8977 範囲固定なので衝突なし)、marine_agriculture_chain は food_value_chain の **直前** (sc=0050 vs sc=3050)、mining_extraction は petroleum_energy の **直前** (sc=1050 vs sc=3300)。順序明示コメントで事故防止
- **1377 サカタのタネは marine_agriculture_chain whitelist から意図的に除外** (sc=0050 だが種苗で構造が異なる、default フォールバック)
- **investment レーン末端に J-REIT スポンサー stub を固定配置** (real_estate_developer)。j_reit_sponsorship テンプレへの連携を視覚化
- **bank_funds_flow は新規テンプレ追加せず whitelist 拡充のみ**。追加 5 行は地銀持株 (めぶきFG 7167 / ほくほくFG 8377) + 単独地銀の主力 (静岡銀 8355 / 山口FG 8418 / 伊予銀 8385)。第二地銀・ネット銀は組織構造が異なるため B-1.35 では未収録

既存テストの巻き込み: 1925/1928/8801 が default → real_estate_developer に変わるため `test_construction_excludes_non_whitelisted` / `test_j_reit_sponsorship_excludes_non_reit_real_estate` を更新。1605 INPEX が default → mining_extraction に変わるため `test_petroleum_energy_excludes_non_whitelisted` を更新。代替コードとして 8881 / 1899 / 5018 を採用

検証: ruff All checks passed / pytest 87 passed (前 80 + 新規 12 + 銀行拡充 1) / typecheck 0 errors / vitest 39 files / 159 tests passed (新規 12 + 既存 147) / lint 0 errors / 24 warnings (既存テンプレと同種の react-refresh のみ)

worklog: 未作成 (Lite mode、本メモリで closeout)

実機検証 (8801/8802/8830/1925 不動産 + 1301/1332/1333 水産 + 1605/1662 鉱業 + 7167/8355/8377/8418/8385 地銀) は次セッション持ち越し

## B-1.36 〜 B-1.40 完了 (2026-05-05)

2 新業種テンプレ (precision_instruments / it_services_saas) + 9 セクター whitelist 拡充 + 銀行第二弾を一括追加。実装ファイル一覧:
- 新規 4 ファイル: `PrecisionInstruments.tsx` / `ItServicesSaas.tsx` (各 ~285 行) + `.test.tsx` (各 4 ケース)
- 拡張 6 ファイル: `desktop/src/lib/types/company.ts` (IndustryTemplate +2)、`templates/template-selector.ts` (TEMPLATE_FALLBACKS +2)、`BusinessModelDiagram.tsx` (import + RENDERERS + BADGE 各 +2)、`BusinessModelMiniSummary.tsx` (TEMPLATE_LABEL +2)、`tools/api/decision_api/serving/company/business_model.py` (whitelist 2 新規 + match 2 新規 + RULES 2 行 + 既存 9 whitelist 拡充 + 銀行第二弾 3 行)、`tests/tools/api/test_company_business_model_template.py` (16 ケース新規 + 既存 4 ケース修正)

設計判断:
- **precision_instruments の whitelist は 6 銘柄 (sc=3750)**。sub_sector_registry に 4543/7733/7731/7762 が登録済の中核。シスメックス 6869 / リコー 7752 は tier-1 上場精密機器メーカーとして併入。半導体製造装置 (sc=3650) は whitelist 完全分離 + _TEMPLATE_RULES で半導体を前段配置
- **it_services_saas の whitelist は 6 銘柄 (sc=5250)**。sub_sector_registry に 4307/9613/4716/4684 が 5250_it_service / 5250_saas representative として登録済。SCSK 9719 / OBC 4733 は tier-1 上場 SI/パッケージベンダ。telecom_three_layer (9432-9434) / game_f2p / ec_marketplace と完全分離 + _TEMPLATE_RULES で順序明示
- **`_TEMPLATE_RULES` 挿入位置**: it_services_saas は ec_marketplace の **直後 / logistics_hub の前**、precision_instruments は semiconductor_supply の **直後**。順序明示コメントで衝突防止
- **既存 whitelist の 9 セクター拡充**: food (4) / chemical (4) / pharma (3) / construction (3) / electric (3) / machinery (2) / retail (3) / hotel (2) / logistics (2) = 計 26 銘柄追加。各銘柄は sub_sector_registry / company_theme_registry / 既存 whitelist と衝突しない tier-1 上場銘柄を選定
- **銀行第二弾**: 8336 武蔵野銀 / 8359 八十二銀 / 8338 筑波銀 (5→10→13 行) を追加。ネット銀は引き続き対象外
- **lane keyword 設計**: precision_instruments は `normalizeHalfWidthKatakana` 適用、5 レーン (R&D / 製造 / 規制 / 販売 / エンドユーザー)。it_services_saas も同 5 レーン (コンサル / SI / SaaS / 保守 / 顧客産業)。"CE" は単独だと "CEO" 等にマッチするため "CEマーク" に変更して誤マッチ抑止
- **レイアウト**: Construction.tsx と同型の 5 レーン横並び SVG 配置を踏襲 (segmentY=320, segXs=horizontalSlots(5, VIEW_W/2, 162))。`BusinessModelSvg` 経由のオーバーレイ等は既存仕組みをそのまま利用

既存テストの巻き込み修正:
- `test_food_value_chain_excludes_non_whitelisted`: 2801 → whitelist 入りのため代替コード 2875 東洋水産に変更
- `test_machinery_excludes_non_whitelisted`: 6113 → whitelist 入りのため代替コード 6103 オークマに変更
- `test_chemical_materials_excludes_non_whitelisted`: 4042 / 4503 → 共に whitelist 入りのため、4205 日本ゼオン / 4540 ツムラに変更
- `test_semiconductor_supply_excludes_non_whitelisted`: 6770 → electric_equipment whitelist 入り、default ではなく electric_equipment が当たることを確認するアサーションに更新

検証: ruff All checks passed / pytest 96 passed (前 80 + 新規 15 + 銀行第二弾 1) / typecheck 0 errors / vitest 41 files / 167 tests passed (新規 8 + 既存 159) / lint 0 errors / 28 warnings (既存テンプレと同種の react-refresh + pre-existing react-hooks のみ)

worklog: 未作成 (Lite mode、本メモリで closeout)

実機検証 (4543/7733 精密 + 4307/4716 SaaS + 4042/4503 化学/医薬 + 6770 電気 + 8336 武蔵野銀) は次セッション持ち越し

## プロジェクト全 Wave 完了 + B-1 38 業種テンプレ稼働

ビジネスモデル図解拡張プロジェクトの全 Wave (B-1 / B-2.1-2.3 / B-3 / B-4.P1-P2) + B-1.9〜B-1.40 が 2026-05-05 までに完了 (計 38 業種テンプレ稼働中、東証 33 業種主要をほぼ網羅)。次セッションは以下から選択:

1. **実機検証**: B-1.17-31 の 14 銘柄 + B-1.32-35 の 14 銘柄 + B-1.36-40 の 9 銘柄 (8801/8802/8830/1925 不動産 + 1301/1332/1333 水産 + 1605/1662 鉱業 + 7167/8355/8377/8418/8385 地銀 + 4543/7733 精密 + 4307/4716 SaaS + 4042/4503 化学/医薬 + 6770 電気 + 8336 武蔵野銀) + 既存テンプレ実機確認
2. **広告 KPI 整備**: `core.metric_observations` への CPM / CPC / DAU / MAU / インプレッション投入、AdSupportedFunnelPanel が status="available" に切替
3. **Supply Chain 関係区分の精度向上**: ADR `supply-chain-relationship-coverage.md` の Wave 4 以降（無料公開ソース拡充）
4. **業種別テンプレ手動切替 UI**: 自動判定がハマらない銘柄の救済策（例: 9984 ソフトバンク G のような複合体）

## 共通パターン (B-2.2 / B-2.3 で確立)

業種別詳細パネル (Telecom / Bank の 2 例) が共有する設計:
- **Props**: `{ code: string; data: CompanyBusinessModelFrameworksResponse }` (上位 query.data 流用、BFF 再 fetch なし)
- **データ源**: `data.business_model.segment_groups` の最初の `kind === "business"` group (fallback で先頭 group)
- **分類**: テンプレ TSX (`TelecomThreeLayer` / `BankFundsFlow`) から `LAYER_DEFS` / `BANK_SEGMENTS` と `classifyXxxSegment(label, sublabel)` を export 共有
- **未分類レーン**: 4 行目/5 行目に「未分類」を追加して透明性確保
- **数値**: `formatAmount(value, { scale: "yen" })` で 兆/億/百万円 自動切替、`revenue_ratio` は 0–1.0 と 0–100 両入力対応の `formatRevenueRatio()`
- **ヒット率**: header に `hit/total` 表示、全 segment 未分類のときは警告バナー
- **empty CTA**: segment_groups が空なら抽出コマンド copy CTA を表示
- 3 例目（B-4.P2 Ad-Supported Funnel 等）が出てきたら共通テーブル抽出を検討

## 残り Wave 一覧 (全完了)

- ~~B-2.1 製薬 Pipeline GANTT~~ ✅ 完了 2026-05-03
- ~~B-2.2 通信 3 層詳細パネル~~ ✅ 完了 2026-05-03
- ~~B-2.3 銀行資金フロー詳細パネル~~ ✅ 完了 2026-05-03
- ~~B-3 逆引き UI 残作業~~ ✅ 完了 2026-05-03
- ~~B-4.P1 ビジネスモデル ワークスペース格上げ~~ ✅ 完了 2026-05-03
- ~~B-4.P2 Ad-Supported Funnel 追加~~ ✅ 完了 2026-05-03

## 重要な前提

- 外部 LLM API 直接呼び出し禁止 (Claude/Codex 対話 + JSON import パターン強制)
- ETF/ETN/REIT/投信は恒久除外 (REIT 関連の新規テンプレ・パネル追加なし、既存 j_reit_sponsorship テンプレは保持)
- DB 書き込みは PostgreSQL 一本化 (greenfield 正本、foundation 同期、alembic revision)
- Desktop は BFF (127.0.0.1:8010) 経由のみ
- UI は密度重視 (デコラティブ NG、freshness/evidence/confidence/risk/next-action 前面)

## 関連メモリ

- `business_model_diagram_frameworks.md` (汎用フレームワーク 8 + 業種別 10 のロードマップ正本)
- `business_model_coverage_snapshot.md` (Wave 1〜4 までのバックエンド完了状態)
- `pure_supply_chain_diagram.md` (Supply Chain サブタブは PureSupplyChainDiagram のみ、混同禁止)
- `interactive_llm_pattern.md` (Claude/Codex 対話 + JSON import パターン)
- `feedback_reit_etf_exclusion.md` (REIT 恒久除外方針)

## v2 並列 3 Wave 完了 (Wave C / U / D Phase 2、2026-05-04)

マスタープラン `polymorphic-inventing-widget.md` v2 に基づき、3 Wave を 1 セッションで並列実装完了。worklog: `docs/worklogs/20260504-wave-{c,u,d-phase2}-*.md`

### Wave C: Data Quality Foundation 拡張 (Full)
- alembic `20260505_001_template_coverage_view.sql` で view 4 段階 health_class (`thin / low_data / partial / healthy`) に統一 (DROP+CREATE)。旧 5 段階の `sparse` は `low_data` に統合
- `analytics.business_model_template_overrides` テーブル新設 (Desktop からの override 操作受け皿)
- `business_model_graph_coverage` の `audit-overrides` に `--include-manual-overrides` フラグ + overrides テーブル統計集計を追加
- BFF / Desktop も 4 段階対応に更新

### Wave U: UI/UX 完成度 (Full)
- Sidebar に「⚙ テンプレ切替」ボタン (Company コンテキスト時のみ表示、CommandPalette を BM-OVERRIDE フィルタで開く)
- CommandPalette に `BM-OVERRIDE-<template_id>` コマンド 40 種追加 (template_definitions.yaml 駆動)
- BusinessModelDiagram に `suggested_template === 'default'` 時の CTA バッジ + 推奨候補 3 件表示
- 推奨候補は Desktop 側 `template-suggestions.ts` で template_definitions.yaml ベース選出 (whitelist+3 / sector_codes+2 / sector_name_keywords+1 weight)
- BusinessModelMiniSummary の override 中表示 (黄色枠で「業種別テンプレ: <label> (手動 override 中)」)
- TemplateOverrideDropdown と CommandPalette 操作で `console.debug("BM-OVERRIDE", ...)` テレメトリ (Wave K で `ops.client_events` 永続化に切替予定)
- 新規 `desktop/src/components/ui/badges/` ディレクトリに Freshness/Evidence/Confidence/Risk バッジ + CompositeBadgeBar を集約
- 既存 `desktop/src/components/company/FreshnessBadge.tsx` は re-export shim 化
- 12 業種パネルの統一バッジは BusinessModelDiagram のパネルヘッダーに**集約配置** (renderer は薄いラッパで自前ヘッダー無いため)

### Wave D Phase 2: 10 packs YAML 設計 (Lite)
- `tools/analytics/ad_kpi_extractor/` → `tools/analytics/disclosure_kpi_extractor/` リネーム + 旧パスは DeprecationWarning shim
- 10 packs YAML (ad_supported / trading_house / semiconductor / saas / ec / auto / electric_power / logistics / shipping / pharma) 計 36 metrics
- `packs_loader.py` に `list_pack_names` / `load_pack` / `build_metric_alias_dict_for_pack` / `seed_metrics_to_catalog`
- main.py に `--pack <name>` オプション + `list-packs` サブコマンド追加
- ad_supported.yaml は BFF `_AD_METRIC_ALIASES` と完全一致確認 (test pass)
- DB 後方互換のため `source_basis = 'ad_kpi_extractor'` は維持
- 28 新規 metrics の `core.metric_catalog` 投入と半自動 IR PDF パイプラインは **D Phase 3** 持ち越し

### 統合検証
- ruff: All checks passed / pytest 89 件 (3 Wave 関連) + 1516/6 skipped (analytics 全体): All passed / Desktop typecheck: OK / lint: warnings 0 / vitest 5 suites 43 tests: All passed

### 残り Wave (マスタープラン v2)
- Wave J Phase 2 (LayeredFlow / VerticalPyramid / RadialCluster / HubSpoke 拡張、12 特殊テンプレ統合)
- Wave E (Supply Chain Tier 2-4 推定)、Wave F Phase 3 (12 panel KPI 配線)、Wave G (5Forces レーダー / Value Chain SVG / SaaS Dashboard / CompanyRelationshipGraph)
- Wave K (観測 VIEW + telemetry endpoint + Discord アラート) → Wave L (ビジュアル回帰 + smoke pytest 化) → Wave M (Playwright + qwen3.5:9b narrative)
- Wave Z (任意): Freshness SLA に business_model_coverage 登録 + Claude classifier 設計再開
