thread_id: 01a08907-2152-7f43-9a3c-195184dd660a
updated_at: 2026-09-12T07:18:34+00:00
rollout_path: \\?\C:\Users\kazum\.codex\sessions\2026\09\10\rollout-2026-09-10T10-55-41-01a08907-2152-7f43-9a3c-195184dd660a.jsonl
cwd: \\?\D:\Dev\Investment
git_branch: main

# NAS導入後のDBバックアップ先を確認し、Cドライブ保存を廃止

Rollout context: 作業対象は `D:\Dev\Investment`。ユーザーはNASのフォルダ指定バックアップを使う前提で、DBの実体と保護対象を確認した後、Cドライブをバックアップ先とする設計の全面廃止を依頼した。

## Task 1: NASに指定するDBの場所と保護対象を調査

Outcome: partial

Preference signals:
- 最初に `db_backups` を案内されたユーザーは「このファイルってなんで存在してんの？そのデータベースのファイルの位置を教えて」と訂正し、「フォルダを指定したらそれを勝手にバックアップで取ってくれるNAS」と説明した。NAS側が指定フォルダを自動バックアップする前提で答え、DB本体とバックアップ出力先を混同しないこと。
- 続けて「データベース以外に何が入ってんの？データベース以外にもバックアップ取った方がいいもんってある？」と質問。DB単体だけでなく、重要な原資料・設定・投資フレームワーク等を区別し、Docker仮想ディスク全体の内容やバックアップ適否を調べて説明する必要がある。

Key steps:
- 実DBはDockerの `infra_postgres_data` ボリュームで、物理的には `D:\DockerDesktop\wsl\disk\docker_data.vhdx` 内。これはPostgreSQL専用ファイルではなく、Docker環境のほかのデータも含む。
- `D:\Dev\Investment\data\db_backups` はDB全体ではなく一部データ退避用であり、案内先として誤りだったと訂正した。
- Docker使用量の確認ではPostgreSQL volumeが約979GB、イメージが約31GB。原資料や設計・投資文書はDocker仮想ディスクの外にあると整理した。

Failures and how to do differently:
- ユーザーが求めたのはNASに渡すバックアップ出力先でなく、NASが取得する対象フォルダ/DB実体の場所だった。目的を取り違えた場合はすぐ訂正し、DBの物理配置と整合性のあるバックアップ方式を区別する。
- 稼働中のVHDXを通常のファイルバックアップ対象にすれば復旧できるとは限らない。DBバックアップは整合性を担保する方式で別途NASへ保存する必要がある。

Reusable knowledge:
- PostgreSQLの実体はDocker named volume `infra_postgres_data` にあり、Docker DesktopのDドライブ上のVHDX内に格納される。VHDXはDocker全体を含み、DB単体のバックアップファイルではない。
- NAS側フォルダバックアップと、PostgreSQLの整合性を保ったバックアップ取得は別の仕組みとして扱う。

References:
- `docs/runbooks/d-drive-storage-operations.md`: Dドライブ配置と `data/db_backups` の従来説明。
- `docs/runbooks/postgres-recovery.md`: PostgreSQLのNASバックアップ/復旧runbook。

## Task 2: CドライブをDBバックアップ先とする設計を廃止

Outcome: success

Preference signals:
- ユーザーは明示的に「NAS導入したのでCドライブでバックアップするという設計は完全廃止してほしい」と依頼した -> DBバックアップの保存先にCドライブを使わず、NASへの保存を必須にする。NAS未設定・到達不能時にローカルへフォールバックしない。
- ユーザーはNASによるフォルダ指定の自動バックアップを説明済み -> NAS共有パスへの保存を基本とし、ローカル作業領域やDockerの保存場所を恒久バックアップ先として案内しない。

Key steps:
- EDINET復旧ツールは既に保存先の明示を要求していたが、C/D等のローカル絶対パスを受け入れ、古いCドライブ向けplanも使えることを確認。
- 保存先検証を共通化し、WindowsでNASの非デバイスUNCパスのみ許可。ローカルドライブ、相対パス、デバイスパスは、新規inventory/planと古いplanの実行時の両方で拒否する。
- runbookとEDINETツールREADMEを更新し、Cドライブ保存を廃止、DドライブのWAL spool・隔離復元先は作業領域であること、既存退避ファイルは削除しないことを記載。
- 関連pytest 47件成功、ruffと `git diff --check` 成功。最終SHA `cb9e6e934d031a48e1dc5e8058d10e7b9b3a8231` でReady gate passed、独立レビューで必須修正なし。PR #441をmergeし、通常実行コピーへ反映した。

Failures and how to do differently:
- 既定値を除くだけでは不十分。明示指定や既に作成されたplanからローカル保存が復活できないよう、plan検証・実行直前にも保存先を拒否する。
- 最初のPR公開はworklogが `In Progress` で失敗し、`Verifying` に更新後に成功した。publish前にworklogの状態要件を確認する。
- pytest 47件終了後に共有tempの `pytest-current` へのPermissionErrorが出たが、pytest自体はexit 0。所有外の共有tempに触れず、テスト結果と終了後の警告を分けて扱う。

Reusable knowledge:
- EDINET部分バックアップの保存先制約は `tools/db_admin/edinet_recovery/runtime.py::_validate_storage_roots`。plan作成と `validate_plan` が同じ制約を通るため、旧ローカルplanもバックアップ作成前に拒否できる。
- 全体PostgreSQL復旧runbookのWindows側NAS検証は非デバイスUNCを要求する。部分復旧にも同等の検証を適用した。
- 方針変更を実装・文書化しても、今回NASへの実接続・転送・復元、認証設定、Scheduler登録はしていない。保護済みとは報告しない。

References:
- `tools/db_admin/edinet_recovery/runtime.py`、`inventory.py`、`README.md`
- `docs/runbooks/d-drive-storage-operations.md`、`docs/runbooks/postgres-recovery.md`
- `tests/tools/db_admin/edinet_recovery/test_core.py`: 旧planのローカル宛先拒否テスト。
- PR #441、merge commit `7f74f67b06c8f75401f946dad96db44cd84aba0e`。
