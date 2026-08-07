#!/bin/bash
set -euo pipefail

WORK_DIR="/builder"

CUSTOM_PACKAGES=""
source "${WORK_DIR}/shell/custom-packages.sh"

echo "软件包: $CUSTOM_PACKAGES"
echo "编译固件大小为: $ROOTFS_PARTSIZE MB"
echo "Include Docker: $INCLUDE_DOCKER"

echo "Create pppoe-settings"
mkdir -p "${WORK_DIR}/files/etc/config"

cat << EOF > "${WORK_DIR}/files/etc/config/pppoe-settings"
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "pppoe-settings 内容 (密码已隐藏):"
grep -v '^pppoe_password' "${WORK_DIR}/files/etc/config/pppoe-settings"

if [ -z "$CUSTOM_PACKAGES" ]; then
  echo "⚪️ 未选择任何第三方软件包"
else
  echo "🔄 正在同步第三方软件仓库..."
  git clone --depth=1 https://github.com/szwjp/luci.git /tmp/store-apk-repo

  mkdir -p "${WORK_DIR}/extra-packages"
  # szwjp/luci 仓库结构: .run 文件在仓库根目录, 子目录存放 .apk
  cp -r /tmp/store-apk-repo/* "${WORK_DIR}/extra-packages/"
  echo "✅ 第三方包已复制至 extra-packages:"
  ls -lh "${WORK_DIR}/extra-packages/"*.run || true

  (cd "${WORK_DIR}" && sh shell/apk-prepare-packages.sh)
  ls -lah "${WORK_DIR}/packages/"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始构建固件..."
PACKAGES="$CUSTOM_PACKAGES"

if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

if echo "$PACKAGES" | grep -Eq '(^| )luci-app-openclash( |$)'; then
    echo "✅ 已选择 luci-app-openclash，添加 openclash core"
    mkdir -p "${WORK_DIR}/files/etc/openclash/core"
    META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64-v1.tar.gz"
    wget -qO- "$META_URL" | tar xOvz > "${WORK_DIR}/files/etc/openclash/core/clash_meta"
    chmod +x "${WORK_DIR}/files/etc/openclash/core/clash_meta"
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O "${WORK_DIR}/files/etc/openclash/GeoIP.dat"
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O "${WORK_DIR}/files/etc/openclash/GeoSite.dat"
    URL=$(curl -s https://api.github.com/repos/vernesong/OpenClash/releases/latest \
      | grep "browser_download_url.*apk" \
      | head -n1 \
      | cut -d '"' -f 4)
    echo "OpenClash latest apk: $URL"
    wget "$URL" -P "${WORK_DIR}/packages/"
else
    echo "⚪️ 未选择 luci-app-openclash"
fi

if echo "$PACKAGES" | grep -Eq '(^| )luci-app-ssr-plus( |$)'; then
    echo "✅ 已选择 luci-app-ssr-plus，添加 mihomo core"
    mkdir -p "${WORK_DIR}/files/usr/bin"
    MIHOMO_VERSION=$(curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest \
      | grep '"tag_name"' \
      | head -n1 \
      | cut -d '"' -f 4)
    echo "mihomo latest version: $MIHOMO_VERSION"
    MIHOMO_URL="https://github.com/MetaCubeX/mihomo/releases/download/${MIHOMO_VERSION}/mihomo-linux-amd64-compatible-${MIHOMO_VERSION}.gz"
    wget -qO- "$MIHOMO_URL" | gzip -dc > "${WORK_DIR}/files/usr/bin/mihomo"
    chmod +x "${WORK_DIR}/files/usr/bin/mihomo"
    echo "✅ 已下载 mihomo core"
    ls -lah "${WORK_DIR}/files/usr/bin"
else
    echo "⚪️ 未选择 luci-app-ssr-plus"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="${WORK_DIR}/files" ROOTFS_PARTSIZE="$ROOTFS_PARTSIZE"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
