#!/bin/bash
set -euo pipefail

# 容器内 ImageBuilder 工作目录: ImmortalWrt 为 /home/build/immortalwrt, OpenWrt 为 /builder
# 由 workflow 按 target 注入, 本地手动构建默认 ImmortalWrt 路径
WORK_DIR="${WORK_DIR:-/home/build/immortalwrt}"
STORE_REPO="https://github.com/szwjp/luci.git"
# 供应链加固: 锁定到指定 commit, 升级第三方包时同步更新 (git ls-remote https://github.com/szwjp/luci.git master)
STORE_REPO_REF="${STORE_REPO_REF:-4e389ea063427433f93d55627eb44b9cd230a009}"
LUCI_DIRS_FILE="${LUCI_DIRS_FILE:-shell/luci-dirs.txt}"

CUSTOM_PACKAGES=""
source "${WORK_DIR}/shell/custom-packages.sh"

echo "第三方软件包: $CUSTOM_PACKAGES"
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
# 收紧权限, 防止固件镜像内明文凭据被普通用户读取
chmod 600 "${WORK_DIR}/files/etc/config/pppoe-settings"

if [ -z "$CUSTOM_PACKAGES" ]; then
  echo "⚪️ 未选择 任何第三方软件包"
else
  echo "🔄 正在同步第三方软件仓库..."
  # sparse-checkout 只拉需要的软件目录, 避免全量下载约 400MB 的代理内核 apk
  rm -rf /tmp/store-repo
  if git clone --depth=1 --filter=blob:none --sparse "$STORE_REPO" /tmp/store-repo; then
    git -C /tmp/store-repo fetch --depth=1 origin "$STORE_REPO_REF"
    git -C /tmp/store-repo checkout --detach "$STORE_REPO_REF"
    if [ -f "${WORK_DIR}/shell/luci-dirs.txt" ]; then
      (cd /tmp/store-repo && git sparse-checkout set --cone $(grep -v '^#' "${WORK_DIR}/shell/luci-dirs.txt"))
    else
      echo "⚠️ shell/luci-dirs.txt 不存在, 退化为全量 checkout"
      (cd /tmp/store-repo && git sparse-checkout disable)
    fi

    mkdir -p "${WORK_DIR}/extra-packages"
    # szwjp/luci 仓库结构: 每个一级子目录存放一个软件的 .apk
    cp -r /tmp/store-repo/* "${WORK_DIR}/extra-packages/"
    echo "✅ 第三方包已复制至 extra-packages:"
    ls -lh "${WORK_DIR}/extra-packages/" | head -30

    (cd "${WORK_DIR}" && sh shell/prepare-packages.sh)
    ls -lah "${WORK_DIR}/packages/"
  else
    # 第三方包缺失时构建仍会成功但固件缺包, 属静默失败, 直接终止
    echo "❌ 上游仓库克隆失败, 第三方包无法集成" >&2
    exit 1
  fi
fi

# 版本注入: 固件版本号由构建参数动态生成 (workflow 传入 BUILD_VERSION), 避免硬编码
# 注意: .config 是 bind-mount 的单文件, 不能用 sed -i (会新建 inode 导致挂载失效), 用临时文件覆盖内容保 inode
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
