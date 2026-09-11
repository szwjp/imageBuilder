# 支持的设备

## x86-64 工作流

| 🖥️ 工作流分类            | 处理器            | 备注         | luci版本        |
| ---------------- | -------------- | ---------- |---------- |
| x86-64 efi.img.gz  | Intel/AMD | EFI向下兼容传统BIOS |25.12.x |
| x86-64 OpenWrt安装器   | Intel/AMD | ISO格式适用于任何虚拟机和任何物理机 引导后输入ddd来安装 |25.12.x |

> 固件本身为 x86-64 架构；上表"适用于任何虚拟机/物理机"指 x86-64 平台的虚机与物理机，
> 不包含 ARM 设备。

## 版本与分支对应关系

| target 参数 | 构建所用分支 | 配置文件名 | ImageBuilder 镜像 |
| --- | --- | --- | --- |
| `immortalwrt` | `master` | `x86-64/imm.config` | `immortalwrt/imagebuilder:x86-64-openwrt-<版本>` |
| `openwrt` | `openwrt` | `x86-64/openwrt.config` | `openwrt/imagebuilder:x86-64-<版本>` |

`openwrt` 分支不含 `.github/workflows/`，因此只能从 master 页面触发工作流并选择 `target=openwrt`。

## 📁 项目功能目录树

```
ImmortalWrt-ImageBuilder/
├── .github/workflows/          # GitHub Actions 工作流目录（仅 master 分支有）
│   ├── build.yml                   # 固件构建工作流 (target 参数选择 ImmortalWrt/OpenWrt)
│   └── clean-workflow.yml          # 工作流清理
├── x86-64/                      # x86-64 平台配置目录
│   ├── build.sh                 # 构建脚本
│   └── imm.config               # 25.12.x 版本配置（openwrt 分支为 openwrt.config）
├── shell/                       # 构建脚本和包管理目录
│   ├── custom-packages.sh       # 自定义软件包配置 (25.12.x, APK)
│   └── prepare-packages.sh      # 第三方 apk 整理脚本 (同名包取舍规则见文件头注释)
└── files/etc/uci-defaults/      # 固件自定义文件目录
    └── 99-custom.sh             # 固件首次启动配置脚本
```
