#!/bin/bash
set -euo pipefail

# 仅支持 ImmortalWrt 25.12.x (apk 包格式)
STORE_REPO="https://github.com/szwjp/luci.git"

CUSTOM_PACKAGES=""
source "shell/custom-packages.sh"

echo "第三方软件包: $CUSTOM_PACKAGES"
echo "编译固件大小为: $ROOTFS_PARTSIZE MB"
echo "Include Docker: $INCLUDE_DOCKER"

echo "Create pppoe-settings"
mkdir -p /home/build/immortalwrt/files/etc/config

cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "pppoe-settings 内容 (密码已隐藏):"
grep -v '^pppoe_password' /home/build/immortalwrt/files/etc/config/pppoe-settings

if [ -z "$CUSTOM_PACKAGES" ]; then
  echo "⚪️ 未选择 任何第三方软件包"
else
  echo "🔄 正在同步第三方软件仓库 Cloning repo..."
  git clone --depth=1 "$STORE_REPO" /tmp/store-repo

  mkdir -p /home/build/immortalwrt/extra-packages
  # szwjp/luci 仓库结构: .run 文件在仓库根目录, 子目录存放 .apk
  cp -r /tmp/store-repo/* /home/build/immortalwrt/extra-packages/
  echo "✅ 第三方包已复制至 extra-packages:"
  ls -lh /home/build/immortalwrt/extra-packages/*.run || true

  sh shell/prepare-packages.sh
  ls -lah /home/build/immortalwrt/packages/
fi

# 版本注入: 固件版本号/源地址由构建参数动态生成 (workflow 传入 BUILD_VERSION), 避免硬编码
if [ -n "${BUILD_VERSION:-}" ]; then
    sed "s|^CONFIG_VERSION_NUMBER=.*|CONFIG_VERSION_NUMBER=\"$BUILD_VERSION\"|" .config > /tmp/version-config.tmp
    cat /tmp/version-config.tmp > .config
    rm -f /tmp/version-config.tmp
    echo "固件版本已注入: $BUILD_VERSION | 源: $(grep '^CONFIG_VERSION_REPO' .config)"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始构建固件..."
PACKAGES="$CUSTOM_PACKAGES"

if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE="$ROOTFS_PARTSIZE"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
