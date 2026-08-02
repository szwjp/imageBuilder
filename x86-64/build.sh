#!/bin/bash
set -euo pipefail

# IMM_VERSION: 23 / 24 / 25 (由 workflow 通过环境变量传入)
: "${IMM_VERSION:?请设置 IMM_VERSION 环境变量 (23/24/25)}"

case "$IMM_VERSION" in
  23) PKG_FORMAT="ipk"; STORE_REPO="https://github.com/wukongdaily/store.git" ;;
  24) PKG_FORMAT="ipk"; STORE_REPO="https://github.com/wukongdaily/store.git" ;;
  25) PKG_FORMAT="apk"; STORE_REPO="https://github.com/wukongdaily/apk.git" ;;
  *)  echo "不支持的版本: $IMM_VERSION"; exit 1 ;;
esac

CUSTOM_PACKAGES=""
source "shell/custom-packages-${IMM_VERSION}.sh"

if [ "$IMM_VERSION" != "25" ] && [ "${ENABLE_STORE:-false}" = "true" ]; then
  CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-store"
  echo "✅ 已追加 luci-app-store"
fi

echo "第三方软件包: $CUSTOM_PACKAGES"
echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

echo "Create pppoe-settings"
mkdir -p /home/build/immortalwrt/files/etc/config

cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "cat pppoe-settings"
cat /home/build/immortalwrt/files/etc/config/pppoe-settings

if [ -z "$CUSTOM_PACKAGES" ]; then
  echo "⚪️ 未选择 任何第三方软件包"
else
  echo "🔄 正在同步第三方软件仓库 Cloning repo..."
  git clone --depth=1 "$STORE_REPO" /tmp/store-repo

  mkdir -p /home/build/immortalwrt/extra-packages
  cp -r /tmp/store-repo/run/x86/* /home/build/immortalwrt/extra-packages/

  echo "✅ Run files copied to extra-packages:"
  ls -lh /home/build/immortalwrt/extra-packages/*.run || true

  if [ "$PKG_FORMAT" = "apk" ]; then
    sh shell/apk-prepare-packages.sh
  else
    sh shell/prepare-packages.sh
  fi
  ls -lah /home/build/immortalwrt/packages/
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始构建固件..."
PACKAGES="$CUSTOM_PACKAGES"

if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

if echo "$PACKAGES" | grep -q "luci-app-openclash"; then
    echo "✅ 已选择 luci-app-openclash，添加 openclash core"
    mkdir -p files/etc/openclash/core
    META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64-v1.tar.gz"
    wget -qO- "$META_URL" | tar xOvz > files/etc/openclash/core/clash_meta
    chmod +x files/etc/openclash/core/clash_meta
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O files/etc/openclash/GeoIP.dat
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O files/etc/openclash/GeoSite.dat
    if [ "$IMM_VERSION" != "23" ]; then
        URL=$(curl -s https://api.github.com/repos/vernesong/OpenClash/releases/latest \
          | grep "browser_download_url.*${PKG_FORMAT}" \
          | head -n1 \
          | cut -d '"' -f 4)
        echo "OpenClash latest ${PKG_FORMAT}: $URL"
        wget "$URL" -P /home/build/immortalwrt/packages/
    fi
else
    echo "⚪️ 未选择 luci-app-openclash"
fi

if [ "$IMM_VERSION" != "23" ] && echo "$PACKAGES" | grep -q "luci-app-ssr-plus"; then
    echo "✅ 已选择 luci-app-ssr-plus，添加 mihomo core"
    mkdir -p files/usr/bin
    MIHOMO_VERSION=$(curl -s https://api.github.com/repos/MetaCubeX/mihomo/releases/latest \
      | grep '"tag_name"' \
      | head -n1 \
      | cut -d '"' -f 4)
    echo "mihomo latest version: $MIHOMO_VERSION"
    MIHOMO_URL="https://github.com/MetaCubeX/mihomo/releases/download/${MIHOMO_VERSION}/mihomo-linux-amd64-compatible-${MIHOMO_VERSION}.gz"
    wget -qO- "$MIHOMO_URL" | gzip -dc > files/usr/bin/mihomo
    chmod +x files/usr/bin/mihomo
    echo "✅ 已下载 mihomo core"
    ls -lah files/usr/bin
else
    echo "⚪️ 未选择 luci-app-ssr-plus"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE="$PROFILE"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
