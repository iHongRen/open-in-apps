#!/usr/bin/env bash

# clean_app_extras.sh
# 在 .app 包内部查找并删除 `Assets.car` 和 `ApplicationStub.icns`
# 用法:
#   1. 显示将要删除的文件（dry-run，默认）:
#        ./clean_app_extras.sh /path/to/MyApp.app
#   2. 对多个 .app 执行:
#        ./clean_app_extras.sh /path/to/A.app /path/to/B.app
#   3. 在当前目录递归查找所有 .app 并显示将被删除的文件:
#        ./clean_app_extras.sh
#   4. 直接执行删除（非交互）:
#        ./clean_app_extras.sh --yes /path/to/MyApp.app

set -euo pipefail

ARGS=()

usage() {
  echo "用法: $0 [<path1.app> <path2.app> ...]"
  echo "如果未传入路径，脚本将在当前目录及子目录中查找所有 .app。"
  echo "该脚本会直接删除匹配的文件（不可恢复），请谨慎执行。"
}

# 解析参数（仅支持 -h/--help 显示帮助，其它参数当作路径）
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -* )
      echo "未知选项: $1" >&2
      usage
      exit 1
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

find_app_paths() {
  if [ ${#ARGS[@]} -gt 0 ]; then
    for p in "${ARGS[@]}"; do
      # 支持传入 .app 或目录
      if [ -d "$p" ] && [[ "$p" == *.app ]]; then
        printf '%s\n' "$(cd "$(dirname "$p")" && pwd)/$(basename "$p")"
      elif [ -e "$p" ]; then
        # 如果传入的是目录但非 .app，则在该目录下查找 .app
        if [ -d "$p" ]; then
          find "$p" -type d -name "*.app"
        else
          echo "警告: 路径存在但不是目录或 .app，跳过: $p" >&2
        fi
      else
        echo "警告: 路径不存在，跳过: $p" >&2
      fi
    done
  else
    # 未传入路径，递归当前目录查找 .app
    find . -type d -name "*.app"
  fi
}

delete_matches_in_app() {
  local app_path="$1"
  # 在 .app 内查找匹配文件（递归），只匹配文件名
  # 使用 -print0 以安全处理空格
  while IFS= read -r -d '' file; do
    rm -f -- "$file" && echo "已删除: $file"
  done < <(find "$app_path" -type f \( -iname "Assets.car" -o -iname "ApplicationStub.icns" \) -print0)
}

main() {
  apps=()
  while IFS= read -r line; do
    apps+=("$line")
  done < <(find_app_paths)

  if [ ${#apps[@]} -eq 0 ]; then
    echo "未找到任何 .app（请传入路径或在当前目录包含 .app）" >&2
    exit 0
  fi

  for app in "${apps[@]}"; do
    echo "处理: $app"
    delete_matches_in_app "$app"
  done

  echo "完成：已在上述路径中删除匹配文件。"
}

main
