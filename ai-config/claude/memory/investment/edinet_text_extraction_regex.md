---
name: EDINET テキスト抽出 regex のハマりパターン
description: 決定論的 regex で日本語テキストから会社名を抽出する際に頻出する 3 種のノイズと、それぞれの抑止手法
type: feedback
originSessionId: 804c6922-2637-4ddc-b3b8-ea062404f6b5
---
`tools/market_data/edinet_partners_text/` で EDINET 有報テキストから会社名を regex 抽出する際に、3 種類のノイズが毎回出現する。regex 初版では全部通過させてしまい、データ品質が 3% 以下まで落ちた (500 docs → 8 エッジ、うち 5 件は rename 説明文や文末"ます"を company name として捕捉)。

**Why**: 日本語公式文書は「ベンダーサービス株式会社から三井物産流通グループ株式会社に社名変更しております」のように **rename narrative や declarative tail** で構成される文が多く、普通の `[name-chars]{1,30}(株式会社|...)` 型 regex は文脈を問わず巻き込む。また「株式会社」「合同会社」は語彙として強力すぎて単体で prefix match 発火してしまう。

**How to apply**: 類似の決定論的テキスト抽出を設計するときは以下 3 点を最初から入れる。
1. **word-boundary lookbehind**: `(?<![name-char])(株式会社|...)...` で、別の名前の後半に「株式会社」がある場合 (それは suffix case) に prefix match を発火させない
2. **first-char non-hiragana 制約**: prefix 側も suffix 側も trimmed stem の先頭が hiragana だったら reject。「株式会社を」「ます株式会社」「あったFracti合同会社」のようなゴミを落とす
3. **multi-char stop tokens**: 「から」「より」「および」「または」「ならびに」「である」「です」「との」「による」「通じて」「として」を stop token regex に入れ、prefix stem では first-match 前で切り、suffix stem では last-match 後から切る

**golden fixture は regression の鍵**: 実データで発見したノイズ 5-10 件をそのまま `tests/.../fixtures/` に残し「このノイズは拒否されるべき」assertion を貼っておくと、将来の regex 調整が既存の良質抽出を壊さないことを CI で保証できる。`test_prefix_rejects_rename_narrative` のように、**具体的な failure pattern を 1 テスト 1 観点で** 固定するのが最強。

**v3 (2026-04-21 PM) で追加された第 4-5 ノイズ分類と suffix 拡張**:
4. **fiscal-period / date narrative prefix** (`当連結会計年度株式会社デンソー` / `2024年８月21日株式会社トヨタ`): 粒子や接続語を含まないので particle split / multi-stop token で切れない。suffix match の stem 先頭に `_LEADING_NOISE_RE` を当てて strip し、残り長さ < 2 で reject。
5. **㈱ / （株） / (株) 表記**: 大手の「関係会社の状況」table は `株式会社` でなく `㈱` (U+3231) を使う (Toyota で 63 回、SoftBank で 39 回)。SUFFIX_RE に `㈱|㈲|\uFF08株\uFF09|\(株\)` を追加しないと**6 銘柄中 4 銘柄が 0 件**になる。`_has_company_suffix` も同時拡張し confidence bonus を通す。

**concept-wide under_heading の発想**: concept_qname が CUSTOMER/AFFILIATE/RELATED_PARTY 系なら、ブロック全体が意味的に heading なので `under_heading=True` を強制する。table-format の単独行 (`ケンタッキー㈱` のみ、amount/ratio なし) は `base(0.40) + suffix(0.10) = 0.50` で通過させ、`RELATION_MIN_CONFIDENCE[affiliate/subsidiary]` を 0.60 → 0.50 に合わせて緩和する。False positive は regex 側 (ノイズ strip) で抑える設計。

**per-concept limit ceiling は年間フル開示数以上に設定**: `PER_CONCEPT_LIMIT_CEIL = 5_000` では `OverviewOfAffiliatedEntitiesTextBlock` の 9,463 件/年を拾いきれず、ORDER BY submit_date DESC の末尾が切れて大手 (6月決算集中) が圏外になる。最低 **20,000** まで引き上げる。

**table-format 名称 truncation は regex では救えない**: `トヨタ モーター\nエンジニアリング アンド\nマニュファクチャリング\nノース アメリカ㈱` のように社名が 4 行に跨る場合、line-based extractor は最後の `ノース アメリカ㈱` しか拾えず、`マニュファクチャリング㈱` など途中行を cut-off で出す。tier=text_inferred (参考) として UI 表示するのは許容、精度向上には table-aware parser が必要。

関連ファイル: `tools/market_data/edinet_partners_text/extractor.py` (regex), `models.py` (MIN_CONFIDENCE), `ingest.py` (PER_CONCEPT_LIMIT_CEIL)
関連テスト: `tests/tools/market_data/edinet_partners_text/test_extractor.py` (31 件、うち 6 件が v3 regression)
