#!/bin/sh
# 收集第三方 apk 到 packages/ 目录
# szwjp/luci 仓库自 2026-08 起采用"一个软件一个目录"模式, 不再发布 .run 安装器
set -eu

BASE_DIR="extra-packages"
TARGET_DIR="packages"

# 清理旧的目录
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

# 收集 extra-packages/*/ 下的 .apk 文件（只查一级子目录）
find "$BASE_DIR" -mindepth 2 -maxdepth 2 -type f -name "*.apk" \
  -exec echo "👉 Found:" {} \; \
  -exec cp -v {} "$TARGET_DIR"/ \;

echo "✅ 所有 .apk 文件已整理至 $TARGET_DIR/"
