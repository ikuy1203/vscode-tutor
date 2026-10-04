#!/usr/bin/env bash
#
# bin/vscode-tutor のスモークテスト
#
# 本物の VS Code は起動せず、VSCODE_BIN に偽の CLI を渡して「渡された引数」と「work/ の中身」を検証します。
# リポジトリの work/ には触れないよう、一時ディレクトリに bin/ と tutor/ をコピーして実行します。
#
# 使い方: test/smoke.sh

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# macOS の /var は /private/var へのシンボリックリンクなので、起動スクリプト（cd -P）と同じ実パスにそろえる
tmp="$(cd -P "$(mktemp -d)" && pwd)"
trap 'rm -rf "$tmp"' EXIT

root="$tmp/repo"
mkdir "$root"
cp -R "$repo/bin" "$repo/tutor" "$root/"
launcher="$root/bin/vscode-tutor"
work="$root/work"

# 偽の code CLI: --list-extensions には FAKE_EXTENSIONS_FILE の中身を返し、それ以外は引数を1行ずつ記録する。
# exec cat にしているのは、読み手が先に閉じたときに本物の CLI と同様に SIGPIPE で失敗させるため。
fake_code="$tmp/fake-code"
cat >"$fake_code" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "--list-extensions" ]; then
  exec cat "${FAKE_EXTENSIONS_FILE:-/dev/null}"
fi
printf '%s\n' "$@" >"$FAKE_ARGS_LOG"
EOF
chmod +x "$fake_code"

export VSCODE_BIN="$fake_code"
export FAKE_ARGS_LOG="$tmp/args.log"
unset FAKE_EXTENSIONS_FILE

failures=0
out=""
status=0

pass() { printf 'ok   - %s\n' "$1"; }
fail() {
  printf 'FAIL - %s (終了コード: %s)\n' "$1" "$status" >&2
  printf '%s\n' "$out" | sed 's/^/       | /' >&2
  failures=$((failures + 1))
}

# コマンドを実行し、出力（stdout + stderr）を $out、終了コードを $status に入れる
run() {
  rm -f "$FAKE_ARGS_LOG"
  status=0
  out="$("$@" 2>&1)" || status=$?
}

contains() {
  case "$1" in
    *"$2"*) return 0 ;;
  esac
  return 1
}

# 偽の CLI に渡された引数が期待どおりか
args_are() {
  [ -f "$FAKE_ARGS_LOG" ] && [ "$(cat "$FAKE_ARGS_LOG")" = "$(printf '%s\n' "$@")" ]
}

work_is_fresh() {
  diff -r "$root/tutor" "$work" >/dev/null
}

# --- オプション -------------------------------------------------------------

run "$launcher" --help
if [ "$status" -eq 0 ] && contains "$out" "使い方: vscode-tutor" && [ ! -e "$work" ]; then
  pass "--help で使い方を表示する"
else
  fail "--help で使い方を表示する"
fi

run "$launcher" --bogus
if [ "$status" -eq 1 ] && contains "$out" "不明なオプションです: --bogus" && [ ! -e "$work" ]; then
  pass "不明なオプションはエラーになる"
else
  fail "不明なオプションはエラーになる"
fi

run env VSCODE_BIN="$tmp/no-such-code" "$launcher"
if [ "$status" -eq 1 ] && contains "$out" "VSCODE_BIN に指定されたコマンドが見つかりません" && [ ! -e "$work" ]; then
  pass "VSCODE_BIN が見つからなければ、何もせずにエラーになる"
else
  fail "VSCODE_BIN が見つからなければ、何もせずにエラーになる"
fi

# --- 作業フォルダ -----------------------------------------------------------

run "$launcher"
if [ "$status" -eq 0 ] && work_is_fresh && args_are --new-window "$work" "$work/tutor.txt"; then
  pass "教材を work/ にコピーして新しいウィンドウで開く"
else
  fail "教材を work/ にコピーして新しいウィンドウで開く"
fi

echo "dirty" >>"$work/tutor.txt"
touch "$work/leftover.txt"
run "$launcher"
if [ "$status" -eq 0 ] && work_is_fresh && contains "$out" "注意: 前回の VS Code Tutor ウィンドウ"; then
  pass "再実行すると work/ がまっさらに戻り、注意が表示される"
else
  fail "再実行すると work/ がまっさらに戻り、注意が表示される"
fi

run "$launcher" --clean
if [ "$status" -eq 0 ] && args_are --profile vscode-tutor --new-window "$work" "$work/tutor.txt"; then
  pass "--clean で専用プロファイルを指定する"
else
  fail "--clean で専用プロファイルを指定する"
fi

# --- Vim 拡張機能の検出 -----------------------------------------------------

extensions="$tmp/extensions.txt"
export FAKE_EXTENSIONS_FILE="$extensions"

printf '%s\n' ms-python.python esbenp.prettier-vscode >"$extensions"
run "$launcher"
if [ "$status" -eq 0 ] && ! contains "$out" "ヒント:"; then
  pass "キーバインド拡張が無ければヒントを出さない"
else
  fail "キーバインド拡張が無ければヒントを出さない"
fi

for ext in vscodevim.vim asvetliakov.vscode-neovim; do
  printf '%s\n' ms-python.python "$ext" >"$extensions"
  run "$launcher"
  if [ "$status" -eq 0 ] && contains "$out" "ヒント: Vim"; then
    pass "$ext を検出してヒントを出す"
  else
    fail "$ext を検出してヒントを出す"
  fi
done

# 一覧の先頭で一致し、残りの出力がパイプに収まらない場合でも検出できること（pipefail と SIGPIPE の回帰テスト）
{
  echo vscodevim.vim
  seq 1 20000 | sed 's/^/publisher.extension-/'
} >"$extensions"
run "$launcher"
if [ "$status" -eq 0 ] && contains "$out" "ヒント: Vim"; then
  pass "拡張機能が大量にあっても検出できる"
else
  fail "拡張機能が大量にあっても検出できる"
fi

echo vscodevim.vim >"$extensions"
run "$launcher" --clean
if [ "$status" -eq 0 ] && ! contains "$out" "ヒント:"; then
  pass "--clean のときはヒントを出さない"
else
  fail "--clean のときはヒントを出さない"
fi

unset FAKE_EXTENSIONS_FILE

# --- 起動のされ方 -----------------------------------------------------------

# PATH 上のディレクトリから相対パスのシンボリックリンクを2段たどって起動されるケース
mkdir "$tmp/links"
ln -s ../repo/bin/vscode-tutor "$tmp/links/vscode-tutor-rel"
ln -s vscode-tutor-rel "$tmp/links/vscode-tutor"
rm -rf "$work"
run "$tmp/links/vscode-tutor"
if [ "$status" -eq 0 ] && work_is_fresh && args_are --new-window "$work" "$work/tutor.txt"; then
  pass "シンボリックリンク経由でも本体の場所を解決する"
else
  fail "シンボリックリンク経由でも本体の場所を解決する"
fi

broken="$tmp/broken"
mkdir -p "$broken/bin" "$broken/work"
cp "$launcher" "$broken/bin/"
touch "$broken/work/keep.txt"
run "$broken/bin/vscode-tutor"
if [ "$status" -eq 1 ] && contains "$out" "教材が見つかりません" && [ -f "$broken/work/keep.txt" ]; then
  pass "教材が無ければ、work/ を消さずにエラーになる"
else
  fail "教材が無ければ、work/ を消さずにエラーになる"
fi

# ---------------------------------------------------------------------------

if [ "$failures" -gt 0 ]; then
  echo "$failures 件のテストが失敗しました。" >&2
  exit 1
fi
echo "すべてのテストに成功しました。"
