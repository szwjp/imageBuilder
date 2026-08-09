# ImmortalWrt-ImageBuilder

基于 CI 的 ImageBuilder 工作流，用于自动化构建 ImmortalWrt 固件（仅支持 x86-64）。

## 功能特性

- 支持自定义固件大小（默认 1GB，推荐 1G-2G）
- 支持可选预安装 Docker
- 支持按需增加第三方软件
- 仅支持 25.12.x 版本
- 提供 ISO 安装器格式

## 📁 项目功能目录树

```
ImmortalWrt-ImageBuilder/
├── .github/workflows/          # GitHub Actions 工作流目录
│   ├── build.yml                   # 固件构建工作流 (target 参数选择 ImmortalWrt/OpenWrt)
│   └── clean-workflow.yml          # 工作流清理
├── x86-64/                      # x86-64 平台配置目录
│   ├── build.sh                 # 构建脚本
│   └── imm.config               # 25.12.x 版本配置
├── shell/                       # 构建脚本和包管理目录
│   ├── custom-packages.sh       # 自定义软件包配置 (25.12.x, APK)
│   ├── prepare-packages.sh      # 软件包准备脚本 (apk)
│   └── luci-dirs.txt            # 第三方 apk 源目录白名单 (sparse-checkout)
└── files/etc/uci-defaults/      # 固件自定义文件目录
    └── 99-custom.sh             # 固件首次启动配置脚本
```

> 注：`build.yml` 的 target 选择 `openwrt` 时，构建基于独立的 `openwrt` 分支（含 openwrt 专用配置 `x86-64/openwrt.config` 与不同的包启用集合）。

## 操作手册

### 基本用法

1. Fork 本项目
2. 在 fork 后的项目中点击 【Actions】
3. 找到 Build Firmware 工作流，选择 target（`immortalwrt` 或 `openwrt`）与参数后点击 【Run workflow】

### 固件默认属性

- **单网口设备**：默认采用 DHCP 模式，自动获取 IP
- **多网口设备**：默认 WAN 口采用 DHCP 模式，LAN 口 IP 为 192.168.1.1（最后一个网口为 WAN，其余为 LAN）
- **管理入口**：nginx 为主 Web 服务器，`http://<管理IP>`(80) 与 `https://<管理IP>`(443) 均可直接访问（HTTPS 为自签证书，浏览器会报不安全，点继续即可）；uhttpd 为备用入口 `http://<管理IP>:8080` / `https://<管理IP>:8443`
- 若在工作流中勾选了拨号信息，则 WAN 口模式为 PPPoE 拨号模式
- 建议拨号用户使用之前重启一次光猫

### 特别说明

本项目构建的固件，WAN 口防火墙规则入站默认是开启的，待首次调试完毕后，建议自行关闭。操作方法：网络 - 防火墙 - WAN 的入站选择拒绝，然后保存并应用即可。
