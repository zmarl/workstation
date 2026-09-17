---
name: feedback-review-placement-markdown-canonical
description: 現状レビューの正本は docs/audits の Markdown、読み物 HTML は正本にしない（2026-09-16 オーナー決定）
metadata: 
  node_type: memory
  type: feedback
  originSessionId: fe6b2ba9-42cd-4471-968a-5bedb3e50d16
  modified: 2026-09-16T00:52:12.431Z
---

オーナー決定（2026-09-16）:

1. リポジトリの文書ルートは `docs/` 一本。投資フレームワークは投資方法論専用の別棚として残す。
2. 現状調査・現状評価・総点検・監査の**本文は `docs/audits/YYYYMMDD-<slug>.md`** に置く。リポジトリ外・`data/runtime/plans`・セッション作業フォルダ・エージェントの記憶に本文を残さない。
3. **読み物 HTML は正本にしない。** 正本は Markdown 1 本とし、読むときは Desktop Control Tower の Markdown 画面（`desktop/src/pages/markdown/`、ファイルツリー付き）で開く。
4. 凍結対象パス（`docs/runbooks` 等）への移動は 2026-10-07 以降。

**Why:** 手で維持する実体が 2 つ（Markdown と HTML）あると必ずずれる。実例として `docs/investment-knowledge-base.html` は元データから約 5 か月ドリフトし、検査は warning 止まりで誰も気付いていなかった。さらに外部保存は消える／書き換わるため、ODR-0038 が版管理外のファイルを根拠に引用する事態を招いた。

**How to apply:** レビューを書くときは最初から `docs/audits/` に Markdown で書く。書式は既存 6 本と同じ「目的・調査方法・調査時点・注意」の箇条書きで、YAML front matter は付けない（`audit_record` プロファイルがパスで分類する）。図は mermaid、表は GFM テーブルにする（`MarkdownBody` は remark-gfm と MermaidDiagram を持つが rehype-raw は無いので生 SVG は描画されない）。外部依頼の原本は外に置いたまま `docs/research/registry.yaml` へ `external://` 形式で登録する（絶対パスは blocking 検査が禁止）。詳細は [[project-docs-consolidation-2026-09-16]]。
