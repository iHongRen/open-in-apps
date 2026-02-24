#!/usr/bin/env bash
set -euo pipefail


# app 名称列表
APP_NAMES=(
  "open-in-android-studio.app"
  "open-in-clion.app"
  "open-in-cursor.app"
  "open-in-deveco-studio.app"
  "open-in-github-desktop.app"
  "open-in-hbuilderx.app"
  "open-in-intellij-idea.app"
  "open-in-iterm.app"
  "open-in-kiro.app"
  "open-in-macvim.app"
  "open-in-obsidian.app"
  "open-in-pycharm.app"
  "open-in-qt-creator.app"
  "open-in-rider.app"
  "open-in-sublime-text.app"
  "open-in-terminal.app"
  "open-in-textedit.app"
  "open-in-trae.app"
  "open-in-typora.app"
  "open-in-visual-studio.app"
  "open-in-vscode.app"
  "open-in-webstorm.app"
)

COUNT=0
for name in "${APP_NAMES[@]}"; do
  TARGET="/Applications/${name}"
  if [ -e "$TARGET" ]; then
    echo "即将处理: $TARGET" >&2
    if xattr -p com.apple.quarantine "$TARGET" >/dev/null 2>&1; then
      if xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null; then
        echo "  已递归移除隔离属性: $name" >&2
      else
        echo "  警告: 无法递归删除顶层属性，尝试逐文件删除或使用 sudo 重试" >&2
        find "$TARGET" -print0 | xargs -0 -I{} sh -c 'xattr -d com.apple.quarantine "$1" 2>/dev/null || true' -- {}
        echo "  尝试逐文件删除完成（可能需要 sudo）" >&2
      fi
    else
      # 即使顶层没有标记，也尝试递归清理内部
      xattr -dr com.apple.quarantine "$TARGET" 2>/dev/null || true
      echo "  无顶层隔离属性，但已尝试递归清理内部（如有）" >&2
    fi
    COUNT=$((COUNT+1))
  else
    echo "跳过（/Applications中不存在）： $name" >&2
  fi
done

echo "完成：处理了 $COUNT 个在 /Applications 中存在的应用（如需 sudo，请用 sudo 运行此脚本）" >&2

exit 0
