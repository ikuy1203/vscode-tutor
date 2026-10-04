# VS Code Tutor（macOS 版）

[![CI](https://github.com/ikuy1203/vscode-tutor/actions/workflows/ci.yml/badge.svg)](https://github.com/ikuy1203/vscode-tutor/actions/workflows/ci.yml)

`vimtutor` のように、**手を動かしながら Visual Studio Code（以下 VS Code）のキーボードショートカットを覚える**ためのチュートリアルです。
マウスを使わずに、テキストを実際に編集しながら進めます。

> [!NOTE]
> 個人が作成した非公式のチュートリアルです。Microsoft とは関係ありません。

## 必要なもの

- macOS
- [Visual Studio Code](https://code.visualstudio.com/)
- `code` コマンド（無くても `/Applications` にある VS Code を自動で探します）
  - インストール方法: VS Code で `⌘ + ⇧ + P` →「Shell Command: Install 'code' command in PATH」
- `git`（未インストールの場合は、初めて `git` を実行したときに macOS がコマンドライン・デベロッパ・ツールのインストールを案内します）

動作確認環境: macOS 26.7 / VS Code 1.140（キー割り当ては VS Code の標準設定を前提にしています）

## インストール

```sh
git clone https://github.com/ikuy1203/vscode-tutor.git
cd vscode-tutor
```

## 使い方

clone したフォルダで実行します：

```sh
./bin/vscode-tutor
```

新しい VS Code ウィンドウで `tutor.txt` が開くので、上から順に進めてください。

- 実行するたびに、作業用コピー（`work/`）が**まっさらな状態に作り直されます**。編集内容の保存は不要です。
- 終わったら `⌘ + ⇧ + W` でウィンドウを閉じれば OK です（保存確認ダイアログが表示された場合は「保存しない」を選択してください）。
- **もう一度最初から練習したい場合**は、必ず現在の VS Code ウィンドウを閉じてから再実行してください（開いたままだと未保存の編集がそのまま残ります）。

### どこからでも起動できるようにする（任意）

clone したフォルダで、PATH の通ったディレクトリにシンボリックリンクを作成します：

```sh
# ~/.local/bin の場合（おすすめ）
mkdir -p ~/.local/bin && ln -s "$PWD/bin/vscode-tutor" ~/.local/bin/vscode-tutor

# または /usr/local/bin の場合（管理者パスワードを求められます）
sudo mkdir -p /usr/local/bin && sudo ln -s "$PWD/bin/vscode-tutor" /usr/local/bin/vscode-tutor
```

`~/.local/bin` に PATH が通っておらず `command not found: vscode-tutor` になる場合は、次のコマンドで追加してからターミナルを開き直してください（macOS 標準の zsh の場合）：

```sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

### オプション

| オプション | 説明 |
|---|---|
| `--clean` | 専用プロファイル `vscode-tutor` で開きます。拡張機能や自分で変えたキー割り当てが無効になるので、**Vim 拡張などを入れている人**はこちらを使ってください。（※VS Code の仕様上、一度 `--clean` で開くと次回以降もこの作業フォルダには専用プロファイルが引き継がれます） |
| `-h`, `--help` | ヘルプを表示します。 |

環境変数 `VSCODE_BIN` で使う CLI を変えられます（例: `VSCODE_BIN=code-insiders ./bin/vscode-tutor`）。

## レッスン内容

| # | テーマ | 主なキー |
|---|---|---|
| 1 | 高速カーソル移動 | `⌥←/→` `⌃⌥←/→` `⌘←/→` `⌘↑/↓` `⌃-` |
| 2 | 行の削除と挿入 | `⌘⇧K` `⌘Enter` `⌘⇧Enter` |
| 3 | 行の並べ替えと複製 | `⌥↑/↓` `⌥⇧↑/↓` |
| 4 | マルチカーソル（同名単語の一括編集） | `⌘D` `⌘U` `⌘K ⌘D` `⌘⇧L` |
| 5 | 縦列マルチカーソル | `⌘⌥↑/↓` |
| 6 | ファイル切り替え・コメントアウト・整形 | `⌘P` `⌘L` `⌘/` `⌥⇧F` |
| — | 総合卒業試験 | 上記の組み合わせ |

## 困ったとき

- **ショートカットが効かない / 違う動きをする**
  拡張機能（Vim、他エディタのキーマップなど）や自分で変えたキー割り当てが原因かもしれません。`--clean` を付けて起動してください。
- **「このフォルダーの作成者を信頼しますか？」と聞かれる**
  `work/` はこのリポジトリの中に作られます。信頼すると、次回からは聞かれません。
- **`⌥ + ⇧ + F` で整形されない**
  `practice.js` を開いているか確認してください（`tutor.txt` はただのテキストなので整形できません）。
- **日本語入力中にキーが効きにくい**
  英字を入力するときは「英数」モードに切り替えてください。
- **それでも解決しない / 教材の誤りを見つけた**
  [Issue](https://github.com/ikuy1203/vscode-tutor/issues/new/choose) で教えてください（VS Code のバージョンとキーボード配列を書いてもらえると助かります）。

## アンインストール

1. シンボリックリンクを作った場合は削除します：

   ```sh
   rm ~/.local/bin/vscode-tutor          # ~/.local/bin に作った場合
   sudo rm /usr/local/bin/vscode-tutor   # /usr/local/bin に作った場合
   ```

2. clone したフォルダを削除します（作業用コピーの `work/` もこの中にあります）。
3. `--clean` を使ったことがある場合は、VS Code のコマンドパレット（`⌘ + ⇧ + P`）で「Profiles: Delete Profile...」を実行し、`vscode-tutor` プロファイルを削除します。
4. （任意）コマンドパレットで「Workspaces: Manage Workspace Trust」を実行し、信頼済みフォルダーの一覧（Trusted Folders & Workspaces）から `work` フォルダを削除します。

## ディレクトリ構成

```text
.
├── bin/vscode-tutor          # 起動スクリプト（tutor/ を work/ にコピーして開く）
├── tutor/                    # 教材の元データ（ここを編集する）
│   ├── tutor.txt             # 本編
│   ├── practice.js           # レッスン 6 用の練習ファイル
│   └── .vscode/settings.json # 練習用の設定（自動保存・自動整形オフなど）
├── work/                     # 作業用コピー（自動で作られる・git の管理対象外）
├── test/smoke.sh             # 起動スクリプトのテスト（VS Code は起動しない）
├── .github/                  # CI（GitHub Actions）と Issue テンプレート
├── vscode-tutor.code-workspace  # 教材を編集するときに開くワークスペース
└── LICENSE
```

## 教材・スクリプトを編集する人へ

- 教材の編集は `tutor/` の中で行います（`work/` は起動のたびに消えます）。
- `vscode-tutor.code-workspace` を開いて編集してください。保存時の自動整形がオフになっているので、練習用テキストのレイアウトが崩れません。
- `⌘D` を使う練習では、**何も選択していない状態から始めると単語全体が一致するものだけが選ばれる**点に注意してください。問題文に書いた個数と、実際に選ばれる個数が合っているか確認しましょう。
- `bin/vscode-tutor` を変更したら `test/smoke.sh` を実行してください（VS Code は起動しません）。push と Pull Request では、GitHub Actions が ShellCheck とこのテストを実行します。

## ライセンス

[MIT License](LICENSE)

## 免責事項

- 本プロジェクトは個人が作成した非公式のチュートリアルであり、Microsoft とは一切関係ありません。
- Visual Studio Code および VS Code は、Microsoft Corporation の商標です。
