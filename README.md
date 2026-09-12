# ImmortalWrt-ImageBuilder

基于 CI 的 ImageBuilder 工作流，用于自动化构建 ImmortalWrt 固件（仅支持 x86-64）。

## 功能特性

- 支持自定义固件大小（默认 1GB，推荐 1G-2G）
- 支持可选预安装 Docker
- 支持按需增加第三方软件（见 `PACKAGES.md`）
- 仅支持 25.12.x 版本
- 提供 ISO 安装器格式

## 📁 项目功能目录树

```
ImmortalWrt-ImageBuilder/
├── .github/workflows/          # GitHub Actions 工作流目录（仅 master 分支有）
│   ├── build.yml                   # 固件构建工作流 (target 参数选择 ImmortalWrt/OpenWrt)
│   └── clean-workflow.yml          # 工作流清理
├── x86-64/                      # x86-64 平台配置目录
│   ├── build.sh                 # 构建脚本
│   ├── imm.config               # ImmortalWrt 25.12.x 配置（openwrt 分支为 openwrt.config）
├── shell/                       # 构建脚本和包管理目录
│   ├── custom-packages.sh       # 自定义软件包配置 (25.12.x, APK)
│   └── prepare-packages.sh      # 第三方 apk 整理脚本（同名/多版本取舍规则见文件头注释）
└── files/etc/uci-defaults/      # 固件自定义文件目录
    └── 99-custom.sh             # 固件首次启动配置脚本
```

> ⚠️ 两条分支的分工：`master` 只放工作流与通用文档，`openwrt` 分支放 OpenWrt 专用配置
> (`x86-64/openwrt.config`) 与不同的包启用集合，**且不含 `.github/workflows/`**。
> 因此 `target=openwrt` 的构建必须从 master 页面触发（工作流会自行 `git checkout openwrt`）；
> 直接切到 openwrt 分支是找不到工作流的。

## 构建方式：直接使用上游官方 ImageBuilder

构建不再依赖 Docker 镜像，改为在 runner 上下载上游发布的 ImageBuilder 压缩包直接使用：

| target | 下载地址 |
| --- | --- |
| `immortalwrt` | `https://downloads.immortalwrt.org/releases/<版本>/targets/x86/64/immortalwrt-imagebuilder-<版本>-x86-64.Linux-x86_64.tar.zst` |
| `openwrt` | `https://downloads.openwrt.org/releases/<版本>/targets/x86/64/openwrt-imagebuilder-<版本>-x86-64.Linux-x86_64.tar.zst` |

流程：校验 URL 存在 → 下载 → 用官方 `sha256sums` 校验 → 解包到 workspace → 用本仓库的平台配置覆盖 `.config` → 执行 `x86-64/build.sh`。

> 这样做的原因：上游为每个已发布版本都提供 ImageBuilder 压缩包，而 `immortalwrt/imagebuilder`
> 的 Docker 镜像自 2026-07 起就没有继续跟进新版本（停在 25.12.1），导致新发布的固件版本无法构建。
> 压缩包与校验和都在官方下载站，可追溯；`docker` 相关步骤已全部移除。

## 第三方软件包如何进入固件

1. 在 `shell/custom-packages.sh` 中把包名加入 `CUSTOM_PACKAGES`（默认启用项见 `PACKAGES.md`）。
2. 构建时 `x86-64/build.sh` 克隆自维护仓库 [szwjp/luci](https://github.com/szwjp/luci)，
   全量复制到 `extra-packages/`，再由 `shell/prepare-packages.sh` 整理进 ImageBuilder 的 `packages/`。
3. **同名包按设计优先使用第三方这一份**（覆盖官方源版本），因此不需要额外配置源优先级。
4. 同一个包在仓库里出现多份时（不同版本或同版本不同内容），`prepare-packages.sh` 的取舍规则：

   | 情况 | 规则 |
   | --- | --- |
   | 同包名、版本不同 | 保留版本号最高者 |
   | 同包名、版本号相同 | 保留目录名字典序靠前者并打印告警（可用 `EXTERNAL_APK_PRIORITY="passwall pwcore"` 指定优先目录） |

   历史上该步骤依赖 `find` 遍历顺序，结果不确定，现已改为确定性选择并逐条打印取舍。

## 操作手册

### 基本用法

1. Fork 本项目
2. 在 fork 后的项目中点击 【Actions】
3. 找到 Build Firmware 工作流，选择 target（`immortalwrt` 或 `openwrt`）与参数后点击 【Run workflow】

### 固件默认属性

- **单网口设备**：默认采用 DHCP 模式，自动获取 IP
- **多网口设备**：默认 WAN 口采用 DHCP 模式，LAN 口 IP 为 192.168.1.1（最后一个网口为 WAN，其余为 LAN）
- **自定义管理地址**：`custom_router_ip` 输入项**仅对多网口设备生效**；单网口走 DHCP，该输入会被忽略
- **管理入口**：nginx 为主 Web 服务器，`http://<管理IP>`(80) 与 `https://<管理IP>`(443) 均可直接访问（HTTPS 为自签证书，浏览器会报不安全，点继续即可）；uhttpd 为备用入口 `http://<管理IP>:8080` / `https://<管理IP>:8443`
- 若在工作流中勾选了拨号信息，则 WAN 口模式为 PPPoE 拨号模式（同样仅多网口生效）
- 建议拨号用户使用之前重启一次光猫

### 特别说明

本项目构建的固件，WAN 口防火墙规则入站默认是开启的，待首次调试完毕后，建议自行关闭。操作方法：网络 - 防火墙 - WAN 的入站选择拒绝，然后保存并应用即可。

Release 资产使用固定 tag（`Autobuild-x86-64` / `Autobuild-OpenWrt-x86-64` 等），
每次构建会覆盖同名资产，即**每个 target 只保留最近一次构建结果**。
