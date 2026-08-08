#!/bin/bash
set -euo pipefail

WORK_DIR="/builder"
STORE_REPO="https://github.com/szwjp/luci.git"

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
  git clone --depth=1 "$STORE_REPO" /tmp/store-repo

  mkdir -p "${WORK_DIR}/extra-packages"
  # szwjp/luci 仓库结构: .run 文件在仓库根目录, 子目录存放 .apk
  if [ -d /tmp/store-repo ]; then
    cp -r /tmp/store-repo/* "${WORK_DIR}/extra-packages/"
    echo "✅ 第三方包已复制至 extra-packages:"
    ls -lh "${WORK_DIR}/extra-packages/"*.run || true
  else
    echo "⚠️ 上游仓库克隆失败, 跳过第三方包"
  fi

  (cd "${WORK_DIR}" && sh shell/apk-prepare-packages.sh)
  ls -lah "${WORK_DIR}/packages/"
fi

# 版本注入: 固件版本号/源地址由构建参数动态生成 (workflow 传入 BUILD_VERSION), 避免硬编码
if [ -n "${BUILD_VERSION:-}" ]; then
    sed "s|^CONFIG_VERSION_NUMBER=.*|CONFIG_VERSION_NUMBER=\"$BUILD_VERSION\"|" "${WORK_DIR}/.config" > /tmp/version-config.tmp
    cat /tmp/version-config.tmp > "${WORK_DIR}/.config"
    rm -f /tmp/version-config.tmp
    echo "固件版本已注入: $BUILD_VERSION | 源: $(grep '^CONFIG_VERSION_REPO' "${WORK_DIR}/.config")"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始构建固件..."
PACKAGES="$CUSTOM_PACKAGES"

if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="${WORK_DIR}/files" ROOTFS_PARTSIZE="$ROOTFS_PARTSIZE"

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
