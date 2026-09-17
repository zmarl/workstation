# workstation

新しい Ubuntu 26.04 PC を、今の Windows PC と同じように使える状態まで AI に整えてもらうためのキットです（2026-09-17 作成）。

- **オーナーが当日に読むもの**: [docs/day1-owner-sheet.md](docs/day1-owner-sheet.md)
- **AI が従う規則と順番**: [AGENTS.md](AGENTS.md)
- **何を入れて、何を入れないか**: [inventory/windows-apps-2026-09.md](inventory/windows-apps-2026-09.md)
- **技術的な選択の理由**: [docs/decisions.md](docs/decisions.md)
- **判断待ち・当日の記録**: [NOTES.md](NOTES.md)

範囲は OS・道具・日常アプリ・AI の設定までです。投資アプリのデータ（DB の復元、旧ドライブ、`.env`）は移行計画 第 4 版 §4.4 の 6 番以降で別に扱います。

## 旧 PC での予行演習

```bash
bash tests/rehearse.sh <出力先フォルダ>
```

shellcheck と、ubuntu:26.04 コンテナでの通し実行を行います。管理者用の台本はリポジトリ登録とダウンロードまでを実際に行い、導入は apt の解決確認（simulate）にとどめます。ユーザー用の台本は実際に導入します。GPU・デスクトップ・ログイン・snap が要る確認は当日に行います。
