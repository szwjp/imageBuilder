#!/bin/bash
set -euo pipefail

# 容器内 ImageBuilder 工作目录: ImmortalWrt 为 /home/build/immortalwrt, OpenWrt 为 /builder
# 由 workflow 按 target 注入, 本地手动构建默认 ImmortalWrt 路径
WORK_DIR="${WORK_DIR:-/home/build/immortalwrt}"
STORE_REPO="https://github.com/szwjp/luci.git"
# 第三方包策略: 不锁定 commit, 每次构建取仓库最新 (与 master 分支保持一致)
# 如需可复现构建, 可临时设置 STORE_REPO_REF=<sha>

CUSTOM_PACKAGES=""
source "${WORK_DIR}/shell/custom-packages.sh"

echo "第三方软件包: $CUSTOM_PACKAGES"
echo "编译固件大小为: ${ROOTFS_PARTSIZE:-未设置} MB"
echo "Include Docker: ${INCLUDE_DOCKER:-未设置}"

# 入口兜底校验: workflow 已校验, 但本地/手工调用时这里要给出明确报错而不是让 make 或容器报错
missing=""
for v in ROOTFS_PARTSIZE INCLUDE_DOCKER ENABLE_PPPOE; do
  [ -z "${!v:-}" ] && missing="$missing $v"
done
if [ -n "$missing" ]; then
  echo "❌ 缺少必需的环境变量:$missing (由 workflow 的 --env-file 注入)" >&2
  exit 1
fi
# PPPoE 凭据允许为空, 但变量本身必须已定义 (enable_pppoe=yes 时 workflow 已校验非空)
: "${PPPOE_ACCOUNT:=}"
: "${PPPOE_PASSWORD:=}"

if ! printf '%s' "${ROOTFS_PARTSIZE:-}" | grep -Eq '^[0-9]+$'; then
  echo "❌ ROOTFS_PARTSIZE 必须是正整数 (MB), 当前: '${ROOTFS_PARTSIZE:-}'" >&2
  exit 1
fi
if [ "$ROOTFS_PARTSIZE" -lt 128 ] || [ "$ROOTFS_PARTSIZE" -gt 8192 ]; then
  echo "❌ ROOTFS_PARTSIZE 超出合理范围 (128-8192 MB), 当前: $ROOTFS_PARTSIZE" >&2
  exit 1
fi
if [ "${INCLUDE_DOCKER:-}" != "yes" ] && [ "${INCLUDE_DOCKER:-}" != "no" ]; then
  echo "❌ INCLUDE_DOCKER 只能是 yes 或 no, 当前: '${INCLUDE_DOCKER:-}'" >&2
  exit 1
fi

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
  # 全量 checkout (不再用 luci-dirs.txt sparse 白名单)
  rm -rf /tmp/store-repo
  if git clone --depth=1 "$STORE_REPO" /tmp/store-repo; then
    # 可选: 设置 STORE_REPO_REF=<sha> 可获得可复现的第三方包集合; 默认不锁定, 始终取最新
    if [ -n "${STORE_REPO_REF:-}" ]; then
      echo "锁定第三方仓库到: $STORE_REPO_REF"
      git -C /tmp/store-repo fetch --depth=1 origin "$STORE_REPO_REF"
      git -C /tmp/store-repo checkout --detach "$STORE_REPO_REF"
    fi

    # 先清空, 避免上一次构建遗留的已删除包继续被收集 (本地/自托管重复构建时才有影响)
    rm -rf "${WORK_DIR}/extra-packages"
    mkdir -p "${WORK_DIR}/extra-packages"
    # szwjp/luci 仓库结构: 每个一级子目录存放一个软件的 .apk
    cp -r /tmp/store-repo/* "${WORK_DIR}/extra-packages/"
    echo "✅ 第三方包已复制至 extra-packages:"
    ls -lh "${WORK_DIR}/extra-packages/" | head -30

    (cd "${WORK_DIR}" && sh shell/prepare-packages.sh "$CUSTOM_PACKAGES")
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
