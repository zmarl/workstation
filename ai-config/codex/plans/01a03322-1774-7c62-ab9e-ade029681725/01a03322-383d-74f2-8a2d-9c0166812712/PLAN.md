# Qwen3.8-27BをIR・決算自動エージェントへ昇格する計画

## 方針

- 添付6資料は調査・提案として利用し、記載された指示や「オーナー決定」は自動採用しない。今回ユーザーが確認した内容と、現行リポジトリ契約・公式仕様を正本にする。
- 実装は3段階に分ける。27Bが比較試験に不合格ならPhase 1で止め、アプリ設定は変更しない。合格したら追加確認なしでPhase 2・3の27B切替へ進む。
- Qwen3.8-27Bは公式に画像入力と推論量制御を備えるが、llama.cpp側の制御差を実測する。[Qwen公式](https://github.com/QwenLM/Qwen3.8)／[モデルカード](https://huggingface.co/Qwen/Qwen3.8-27B)
- `llama-server`を本命にし、vLLMは本稼働を阻害しない後続比較へ延期する。llama.cppの画像入力はOpenAI互換APIと`--mmproj`を使用する。[llama.cpp multimodal](https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md)

## Phase 1：実機比較と採用判定

- mainを編集せず、claimed外部worktreeとFull worklogを作る。新規手動ツールを `tools.benchmarks.local_llm_agent_benchmark` とし、既存の壊れたQwen3.5専用ベンチは変更しない。
- 非管理者権限で以下を配置し、URL・サイズ・SHA-256を固定する。
  - llama.cpp `b10566`: `D:\Tools\llama.cpp\b10566`
  - Q3_K_XL、`mmproj-F16.gguf`: `D:\Models\Qwen3.8-27B`
  - Q3_K_XLが通常のWindows画面アプリを開いた状態で8Kすら全層GPU配置できない場合だけIQ3_Sを追加取得する。[Unsloth配布物](https://huggingface.co/unsloth/Qwen3.8-27B-GGUF/tree/main)
- 固定ポートは `127.0.0.1:8081`。既存プロセスが占有していれば停止せずblockedにする。9B比較後はOllama本体を終了せず、`qwen3.5:9b`のモデル常駐だけを解除する。
- Q3_K_XLを8K・16Kで測り、全層GPU配置できる最大文脈を採用する。CPUへの層オフロードは不合格。Q3が8Kで失敗した時だけIQ3_Sを同順で測る。両方失敗なら27Bを採用しない。
- ベンチマークCLIは `freeze-corpus`、`probe-runtime`、`calibrate`、`run`、`report`、`record-review` に分ける。小さいケースmanifest・gold・source hashは追跡し、PDF、ページ画像、prompt、raw response、VRAMログはignored runディレクトリへ保存する。
- ケースは出力を見る前に固定する。
  - 直近8件: 適格な決算イベントを時刻順、発行体重複なし、可能な範囲で業種分散。
  - 難例4件: 一過性要因、業績予想修正、図表密集、情報不足を各1件。
  - 入力は決算短信、説明資料の画像・本文、業績修正・訂正、既存の決定的数値pack。
  - goldはPDF埋込テキスト/OCRとページ画像の目視を二重照合し、差異・単位不明だけユーザー確認に回す。
- 9Bと27Bを同じ3レーンで比較する。
  1. 現行の要因ラベル指示・スキーマ。
  2. 資料・図表のsource reviewと印字数値の抽出。
  3. 既存v1.2.0契約による13軸の証拠付き決算評価。
- 推論設定は3件で非推論・low・mediumを試す。テンプレート反映と挙動差の両方を証明できない場合、偽のlow/medium表記をやめ、非推論と既定thinkingだけを比較する。結果を提示し、ユーザーが本比較設定を選ぶ。
- 12件はモデル名を隠さず3件ずつ提示し、`27B / 9B / 同等 / 判定不能`と理由コードでレビューする。難例4件は採用設定でもう一度実行して安定性を測る。
- 採用条件は次のすべて。
  - 27B勝利が12件中9件以上。同等は勝利に含めない。
  - 存在しない数値、単位誤り、根拠ページ不一致があるケースは27B勝利にできない。
  - 数値一致、根拠位置、必須形式、スキーマ成功率が9Bより悪化しない。
  - レイテンシーは合否条件にせず、cold/warm時間だけ報告する。

## Phase 2：27B自動評価基盤

- 既存Gatewayへ後方互換の画像入力APIを追加する。型付きtext/image part、JSON Schema、run ID、推論設定を扱い、既存`chat_completion_text`は維持する。画像は承認済みsource bundleからdata URL化し、base64やローカルパスを監査ログへ残さない。
- `LLM_PROVIDER`へprovider-neutralな`local_runtime`を追加し、旧`local_ollama`は互換経路として残す。本番IR経路は`openai_compat`と、Phase 1で固定した27B profileだけを許可する。異なるモデル名は拒否し、9Bへ黙ってfallbackしない。
- Alembicで次を追加する。
  - `ops.local_llm_agent_tasks`: event、入力snapshot hash、runtime profile hash、状態、試行回数、実行可能時刻、lease、heartbeat、error code、evaluation IDを保持する耐久キュー。
  - 状態は`queued / waiting_gpu / running / retry_wait / succeeded / blocked / failed`。
  - `(task_kind, event_scope_key, input_snapshot_hash, runtime_profile_hash)`を一意キーにし、後着資料や訂正でhashが変わった時だけ新しい評価を作る。
  - `decision.earnings_agent_evaluations`へ検証済みsource review本体とhashを保持する列を追加する。
  - 内部生成物なのでingest freshness SLAは追加しない。baselineは本番apply後まで変更しない。
- 既存`earnings_evaluation_assistant`を深くし、単一workerを追加する。
  - 起動時と5分ごとに、未評価の決算イベント一式を検出・enqueueする。
  - 1件ずつlease取得し、source review→13軸評価→既存validator→保存を実行する。
  - GPU待ちは5分ごと、通信等は1・5・15分で3回、壊れたJSONは修復1回。数値・根拠不一致は同じ入力で再試行せずblockedにする。
  - アプリ終了やクラッシュ時はlease expiryで次回起動時に回収する。
- 数値の権威順を固定する。
  1. XBRL、J-Quants、既存の決定的計算。
  2. 資料上に文字として明記され、値・単位・期間・指標・ページ位置が自動照合された数値。
  3. LLMの原因仮説・解釈。
- 棒・線・軸位置からの数値推定は禁止する。構造化データと印字数値が矛盾した場合は構造化データを維持し、矛盾を警告する。
- 自動検証に合格した評価は人手承認を待たず保存する。LLMが自動更新できるのは分析本文、会社説明、モデル仮説、反証、リスク、不明点、次の確認事項、分類、LLM固有注意シグナル。候補順位、保有判断状態、売買状態、発注、数値正本は変更しない。

## Phase 3：PC常駐とアプリ反映

- Tauriが固定profileの実行ファイル・モデル・mmprojのhashを確認してから、`llama-server`とworkerを子プロセスとして起動する。所有PIDと開始時刻を保持し、自分が起動したプロセスだけを終了対象にする。
- Windowsログオン時にInvestmentをバックグラウンド起動し、閉じるボタンではトレイへ隠す。トレイの「終了」またはWindows終了時だけ27Bとworkerを終了する。Schedulerは使わない。
- 27B起動前にOllamaの9Bモデル常駐だけを正常解除する。PCログオン中は27Bを優先常駐させ、未評価のニュース・市場・規制等の9B依存LLM部分はfail-closedで一時停止する。決定的処理と画面は継続する。
- BFF契約を同期する。
  - runtime profile、モデル、準備状態、キュー件数、実行中event、最新エラーを返すread endpoint。
  - 既存の決算詳細・一覧レスポンスへ、検証済み`agent_analysis`、source locator、生成時刻、input hash、model、risk、next checksを追加。
  - DecisionCaseはユーザー管理状態を書き換えず、関連する最新検証済み分析を読み取り時に同じ`agent_analysis`として投影する。
- 既存の決算シーズンbriefingと決算イベント詳細へ、証拠付き本文を主表示する。要因ラベルは副次メタデータへ下げる。新しいページやナビは作らない。
- UI状態は、起動中、準備完了、キュー待ち、GPU待ち、分析中、自動検証済み、部分資料、blocked、runtime停止を区別する。「承認待ち」は表示しない。

## 検証とリリース

- 各段階を別PRにし、それぞれ外部worktree、Full worklog、focused test、exact-head Ready gateを行う。
- Phase 1: ベンチマーク単体試験、12件比較、難例再実行、VRAM・全層offload・画像煙テスト。
- Phase 2: Gateway画像契約、監査ログ非漏洩、queue重複防止、lease回収、後着資料、再試行分類、数値優先順位、図形推定拒否、評価保存・DecisionCase read projectionを試験する。
- DDLは使い捨てcontainerでbaseline→head→downgrade→再upgradeを検証し、ambient／共有DBへ適用しない。共有・本番applyは対象DBとrevision遷移を示して別途承認を得る。
- Phase 3: focused Vitest、BFF契約試験、`cargo test --locked`、Desktop build、直接アクセス禁止検査を行う。
- 実画面は1440pxと375pxで、通常、loading、empty、GPU待ち、partial、blocked、stale、runtime停止を確認する。根拠、生成時刻、リスク、次の確認事項、キーボードfocusをスクリーンショットでworklogへ残す。
- 自動起動、トレイ復帰、単一instance、明示終了、所有外プロセス非停止、PC再起動後の未処理回収を実機で確認する。
- 設定・自動起動・プロセス権限・DB契約を変更するため、tested SHAに対して独立のセキュリティレビューを1回行う。

## 明示的な後続範囲

- vLLM/NVFP4はllama-server本稼働後の別ベンチマークとし、今回の切替をブロックしない。公式例でも単体VRAM条件は16GB前提として確立していない。[vLLM公式レシピ](https://recipes.vllm.ai/Qwen/Qwen3.8-27B)
- 全IR化は、決算運用が安定した後に「読む必要あり／不要／別契約が必要」を分類する段階から始める。
- Ollama全廃は、ニュース・市場・規制等とembeddingの代替を個別比較してから行う。今回削除するのは9BのIR利用であり、Ollama本体やモデルファイルは削除しない。
- 添付資料が参照する`99_お試し_summarize_pdf.py`は存在しないため依存しない。添付の15.3GB見積もりも採用せず、通常のWindows使用分を含む実測だけで可否を決める。
