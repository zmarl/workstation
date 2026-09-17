---
name: project-financial-backlog-session-2026-07-19
description: "財務バックログ 優先1+2 完遂セッション (07-18夜〜19未明, PR #60/#77/#82/#83)。ゲート全緑化・派生指標パネル着地。並行セッション協調とラチェット追随の運用知見"
metadata:
  node_type: memory
  type: project
  originSessionId: 02350eec-274a-44f9-8f49-edef7245291e
---

# 財務バックログ 優先1+2 完遂 (2026-07-18 夜〜07-19 未明)

成果: **main = check_suite 51/51 + pytest pr 0 fail + db レーン 0 fail (370 passed/3 xfailed)**、変化タブに営業利益増減分解パネル稼働(BFF 再起動済・実 200)。PR #60(HV着地)/#77(ゲート残差)/#82(db レーン)/#83(派生指標パネル)。並行セッションの PR #75/#76 と分担(salvage/main復帰/screening・identity修正はあちら)。

## 再利用可能な知見

- **PR/ブランチ状態はメモリでなく gh/git で必ず実測**(PR #60「マージ済」記録が誤りで、バグコードが main に残っていた)
- **並行セッション競合時の型**: 自分の重複コミットは rebase で自然に drop させ、残差だけの PR にする。gate は base_unchanged を fail-closed で検出するので、マージ直前に fetch で base 不動を確認してから `gh pr merge`
- **shrink-only 行数ラチェット下でのエンドポイント追加**: endpoint_registry.py / response_models.py は凍結。新規追加は自エントリの compact 化+隣接エントリの等価 compact 化で net≤0 に(数行の成長も不可)
- **エンドポイント追加の追随セット**: EndpointSpec+契約名 tuple+`tests/tools/api/test_decision_api_response_models.py` の area counts(company N)と総数 168 系 assert+snapshot 再生成+typegen。**snapshot はソース編集の「最後」に再生成**(sha を記録するため、後から1行でも触ると gate で drift)
- **docs_research_registry の expected_managed_markdown_count は md 追加の度に要追随**(worklog 追加も+1)。rebase で他 PR の md が入る度に再計上
- **decision-surface カタログの対象は tab-registry.tsx に lazy 登録された「タブ面」のみ**(scanner は `import("@/components/company/X")` を正規表現抽出)。ダッシュボード内の子パネルは対象外
- **desktop テストは `renderWithProviders`(test-utils)必須**: inline `new QueryClient` は check_desktop_test_query_client_ratchet が fail-closed で拒否
- **run_local_pytest の --test-path はファイル/ディレクトリのみ**(`::node-id` は OSError→「disposable PostgreSQL unavailable」に誤翻訳される)
- **使い捨て DB コンテナの時計は host より数十ms 進む**(実測+34ms)。テストで `NOW()` 書き込み→直後に host 時計基準で評価する fail-closed ゲートは確率的に「未来完了」ブロッカーが出る → fixture の時刻は数秒過去に固定
- **local-pr-gate コンテナ残骸**(kill された run の investment-local-pr-gate-*)は次の run を "unavailable" にする → `docker rm -f` で掃除
- 優先3(EPS偽中立)・優先4(正規化層再開)は未着手([[project-next-session-followups-2026-07-18]] 参照)
