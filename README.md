# ImmortalWrt-ImageBuilder

基于 CI 的 ImageBuilder 工作流，用于自动化构建 ImmortalWrt 固件（仅支持 x86-64）。

## 功能特性

- 支持自定义固件大小（默认 1GB，推荐 1G-2G）
- 支持可选预安装 Docker
- 支持按需增加第三方软件
- 支持 24.10.x、25.12.x 等版本
- 提供 ISO 安装器格式

## 📁 项目功能目录树

```
ImmortalWrt-ImageBuilder/
├── .github/workflows/          # GitHub Actions 工作流目录
│   ├── build-x86-64.yml            # 统一构建工作流 (通过参数选择版本和输出格式)
│   └── clean-workflow.yml          # 工作流清理
├── x86-64/                      # x86-64 平台配置目录
│   ├── build.sh                 # 统一构建脚本 (通过 IMM_VERSION 区分版本)
│   ├── imm.config               # 23.05.x/24.10.x 版本配置
│   └── imm25.config             # 25.12.x 版本配置
├── shell/                       # 构建脚本和包管理目录
│   ├── custom-packages-23.sh     # 自定义软件包配置 (23.05.x)
│   ├── custom-packages-24.sh     # 自定义软件包配置 (24.10.x)
│   ├── custom-packages-25.sh     # 自定义软件包配置 (25.12.x, APK)
│   ├── prepare-packages.sh      # 软件包准备脚本 (opkg)
│   ├── apk-prepare-packages.sh  # 软件包准备脚本 (apk)
│   └── switch_repository.sh     # 仓库切换脚本
└── files/etc/uci-defaults/      # 固件自定义文件目录
    └── 99-custom.sh             # 固件首次启动配置脚本
```

## 操作手册

### 基本用法

1. Fork 本项目
2. 在 fork 后的项目中点击 【Actions】
3. 找到需要的工作流后点击 【Run workflow】

### 固件默认属性

- **单网口设备**：默认采用 DHCP 模式，自动获取 IP
- **多网口设备**：默认 WAN 口采用 DHCP 模式，LAN 口 IP 为 192.168.1.1（最后一个网口为 WAN，其余为 LAN）
- 若在工作流中勾选了拨号信息，则 WAN 口模式为 PPPoE 拨号模式
- 建议拨号用户使用之前重启一次光猫

### 特别说明

本项目构建的固件，WAN 口防火墙规则入站默认是开启的，待首次调试完毕后，建议自行关闭。操作方法：网络 - 防火墙 - WAN 的入站选择拒绝，然后保存并应用即可。
