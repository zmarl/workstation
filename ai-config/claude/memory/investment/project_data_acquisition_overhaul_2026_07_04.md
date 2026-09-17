---
name: data-acquisition-overhaul-2026-07-04
description: データ取得体制 総点検・強化プログラム（Phase 0-6 完了、2026-07-04）。発見された取得死5系統と監視3層ゲートの設計、残る人間境界とハンドオーバー。
metadata: 
  node_type: memory
  type: project
  originSessionId: 8eca7815-00b8-4f60-b28f-29474a402de1
---

# データ取得体制 総点検・強化（2026-07-04 完了）

worklog: docs/worklogs/20260704-data-acquisition-overhaul.md（詳細正本）。調査は Explore 3体+Plan 2体、実装は Phase 別エージェント7体で実施。

## 発見された「サイレント取得死」（全て修理済み）

1. **kanpo_crawler**: URL 形状が旧スキームで全404、エラーゼロのまま常時0件（一度も実データを書いたことがなかった）。実サイトは `www.kanpo.go.jp/{YYYYMMDD}/{YYYYMMDD}.fullcontents.html` + 号ディレクトリ `{日付}{h|g|c|t|s}{号数5桁}/`（h=本紙,g=号外,c=政府調達）。→ 修理+平日09:15接続、法律公布35件含む97記事/5営業日
2. **wikidata/reclassifier/jplatpat 週次3本**: `--dry-run` 残置で本番書き込みゼロ。jplatpat は設計上 no-op のため manual_only 降格が正
3. **raw.prices_daily が0行**（書き込み経路が存在しない greenfield 設計テーブル）。価格正本は main.daily_prices。フォールバックなし主参照の9ファイルを repoint 済み。**main.daily_prices は履歴42取引日しかない**（market_breadth の MA200 等は深度待ち）
4. **sector_rotation_rrg**: 存在しない industry_code_33 列参照で UndefinedColumn 常時停止 → sector_code/sector_name へ修正
5. **theme_scanner 商品価格**: スキーマ不一致+try/except 握り潰しで常に空 → main.commodity_daily へ repoint
6. **TOPIX FFW**: JPX の CSV から FFW 列が消滅済みで ffw_master 0行。実データはウエイト列のみ → topix_weight_pct 追加+週次取得新設
7. **METI IIP**: WAF で恒久障害（403/202-0byte）→ e-Stat 移行（statsDataId 0004052181-84、業種別月次。@time が代理コードなので getMetaInfo の time クラス名で解決必須）

## 監視3層ゲート（新設計）

- 登録漏れ・未起動 → `db-ingest-governance-audit-daily`（never-run=breach、--allow-sources で grandfather 6件: egov_pubcom/law_tracker/options_flow/sector_kpi_foundation_audit/jpx_listed_companies/disclosure_embedding_indexer）
- Windows 未登録・停止タスク → scheduler-audit `--min-coverage-ratio 0.85`（安定後 1.0 へ）
- 鮮度劣化 → health-pack（NO_DATA を fail セット追加+never-run 合成行。exit 0 維持で backlog→failure inbox 経路）

## 技術知見

- **部分一意インデックス（WHERE 付き）への ON CONFLICT は述語必須** → shared/tooling/repository/upsert.py に `conflict_where` 引数を追加済み
- WDQS は障害時「1 req/min」の強制 429 を敷く → wikidata client に Retry-After 適応減速を実装（上限120s、解除後自動高速化）
- 共有レートリミッタ shared/tooling/net_throttle.py: `acquire(api_name, min_interval)`、ファイルロック方式、障害時プロセス内フォールバック。jquants/edinet/boj 配線済み
- J-Quants は budget/circuit 保護の対象外（tracking 経路が別）— 統合は別提案
- edinet_db API はサーバ側 hard cap 1日100コール
- JSF 逆日歩は taisyaku.jp `/data/shina.csv`、規制一覧は `/data/seigenichiran.csv`（robots 制限なし）

## 残ハンドオーバー（Windows 登録は 2026-07-05 完了済み）

1. ~~Windows スケジューラ登録~~ **完了（2026-07-05）**: 新規11 + 復帰5 登録・Jplatpat 解除、integrity フル green を実機確認
2. auto-recover の dry-run 観察1週間 → `--auto-recover-dry-run` 外し
3. scheduler-audit カバレッジ 0.85 → 1.0 昇格（登録完了後）
4. financial_facts_outlier critical 23件のトリアージ → 完了後 `--fail-on-critical` を manifest へ
5. grandfather 5ソースの整備 or inactive 化判断 + disclosure_embedding_indexer の実 ERROR 修理
6. **reform-program への申し送り**: main.daily_prices の履歴深度（42日）確保、raw.prices_daily の恒久判断（充填 vs 全面 repoint）

関連: [[project_reform_program_202607]] [[project_functional_uplift_202607]] [[bugs]]
