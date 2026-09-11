# 支持的第三方软件列表如下

> 第三方软件 = ImmortalWrt 官方源以外的软件包，来源为自维护仓库 [szwjp/luci](https://github.com/szwjp/luci)。
> 该仓库按"一个软件一个目录"存放 .apk，构建时由 `x86-64/build.sh` 与 `shell/prepare-packages.sh` 整理进 ImageBuilder 的 `packages/` 目录，**与官方源同名的包按设计优先使用这里这一份**。
>
> 「当前编译」列的三种状态：
> - ✅：已写入 `shell/custom-packages.sh`，默认编译进固件
> - ➕：未显式写入，但作为 ✅ 项的依赖被自动装入（已验证）
> - ❌：仓库中已有 apk，但当前未启用；需要时把包名加进 `shell/custom-packages.sh` 对应行即可
>
> 本表「当前编译」列按 **openwrt 分支**（`target=openwrt`）的包集合标注，与 master（ImmortalWrt）不同：
> master 默认不启用代理类第三方包，openwrt 分支启用 `passwall2` / `ssr-plus` / `luci-app-run`。

| 第三方软件名称            | 简介 / 功能描述                                   | 当前编译 | 来源 / 项目地址                                                                       |
| ------------------------ | ------------------------------------------------- | -------- | ------------------------------------------------------------------------------------- |
| luci-app-quickfile       | 文件管理器 (依赖 nginx 主服务)                     | ✅        | 自维护 [szwjp/luci](https://github.com/szwjp/luci/tree/master/quickfile)               |
| luci-theme-aurora        | 极光主题 0.9                                        | ❌        | [eamonxg/luci-theme-aurora](https://github.com/eamonxg/luci-theme-aurora)              |
| luci-app-bandix          | Bandix 流量监控 0.11                               | ✅        | [timsaya/luci-app-bandix](https://github.com/timsaya/luci-app-bandix)                  |
| luci-app-lucky           | Lucky 大吉：ipv6/ipv4 端口转发、反向代理            | ➕        | [gdy666/lucky](https://github.com/gdy666/lucky)                                        |
| luci-app-homeproxy       | 代理工具 (官方源自带，仅启用中文语言包)             | ❌        | [immortalwrt/homeproxy](https://github.com/immortalwrt/homeproxy)                      |
| luci-app-openvpn-server  | OpenVPN 服务端 (自维护分支，规避 /etc/config 冲突)  | ❌        | [szwjp/luci-app-openvpn-server](https://github.com/szwjp/luci-app-openvpn-server)      |
| luci-app-ipsec-vpnd      | IPSec VPN 服务端                                    | ❌        | [szwjp/luci-app-ipsec-vpnd](https://github.com/szwjp/luci-app-ipsec-vpnd)              |
| luci-app-amlogic         | 晶晨宝盒 (仅限 ARM-64 平台，x86-64 无意义)          | ❌        | [ophub/luci-app-amlogic](https://github.com/ophub/luci-app-amlogic)                    |
| luci-app-adguardhome     | 本地 DNS 去广告解决方案                             | ❌        | [AdGuardTeam/AdGuardHome](https://github.com/AdguardTeam/AdGuardHome)                  |
| luci-app-advancedplus    | 高级设置                                            | ❌        | [sirpdboy/luci-app-advancedplus](https://github.com/sirpdboy/luci-app-advancedplus)    |
| luci-app-netspeedtest    | 网络测速插件-支持 Speedtest 测试                    | ❌        | [sirpdboy/luci-app-netspeedtest](https://github.com/sirpdboy/luci-app-netspeedtest)    |
| luci-app-netwizard       | 网络配置向导插件                                    | ❌        | [sirpdboy/luci-app-netwizard](https://github.com/sirpdboy/luci-app-netwizard)          |
| luci-app-partexp         | 分区扩容插件                                        | ❌        | [sirpdboy/luci-app-partexp](https://github.com/sirpdboy/luci-app-partexp)              |
| luci-app-quickstart      | iStore 首页和网络向导                               | ❌        | [szwjp/luci](https://github.com/szwjp/luci/tree/master/luci-app-quickstart)            |
| luci-app-turboacc        | TurboACC 网络加速器 (集成 BBR、shortcut)            | ❌        | [szwjp/luci](https://github.com/szwjp/luci/tree/master/turboacc)                       |
| luci-theme-kucat         | 酷猫主题                                            | ❌        | [sirpdboy/luci-theme-kucat](https://github.com/sirpdboy/luci-theme-kucat)              |
| luci-app-mosdns          | 高性能 DNS 分流器，支持 DoH/DoQ 等                  | ❌        | [sbwml/luci-app-mosdns](https://github.com/sbwml/luci-app-mosdns)                      |
| luci-app-nekobox         | 代理工具                                            | ❌        | [Thaolga/luci-app-nekobox](https://github.com/Thaolga/openwrt-nekobox)                 |
| luci-app-nikki           | 代理工具                                            | ❌        | [nikkinikki-org/nikki](https://github.com/nikkinikki-org/OpenWrt-nikki)                |
| luci-app-momo            | 代理工具                                            | ❌        | [nikkinikki-org/momo](https://github.com/nikkinikki-org/OpenWrt-momo)                  |
| luci-app-passwall2       | 代理工具                                            | ✅        | [Openwrt-Passwall/openwrt-passwall2](https://github.com/Openwrt-Passwall/openwrt-passwall2) |
| luci-app-ssr-plus        | 代理工具                                            | ✅        | [szwjp/luci](https://github.com/szwjp/luci/tree/master/ssrp)                           |
| tailscale                | ZeroTier 类似的 VPN 工具，基于 WireGuard            | ❌        | [tailscale/tailscale](https://github.com/tailscale/tailscale)                          |
| luci-app-gecoosac        | 集客 AC                                             | ❌        | [lwb1978/openwrt-gecoosac](https://github.com/lwb1978/openwrt-gecoosac)                |
| luci-app-taskplan        | 任务计划                                            | ❌        | 自维护 [szwjp/luci](https://github.com/szwjp/luci/tree/master/taskplan)                |
| luci-app-easytier        | 组网                                                | ❌        | [EasyTier/luci-app-easytier](https://github.com/EasyTier/luci-app-easytier)            |
| luci-app-unishare        | 统一文件共享 (webdav 共享)，第三方仓库中暂无 apk      | ❌        | 自维护                                                                                 |
| luci-app-uninstall       | 高级卸载 1.1.8 (用于彻底卸载插件)，第三方仓库中暂无 apk | ❌        | [出处](https://www.bilibili.com/video/BV1dK1xBVEHF)                                   |
| luci-app-rtp2httpd       | IPTV 流媒体转发服务器                               | ❌        | [stackia/rtp2httpd](https://github.com/stackia/rtp2httpd)                              |
| luci-app-run             | 自定义运行脚本                                      | ✅        | 自维护 [szwjp/luci](https://github.com/szwjp/luci/tree/master/luci-app-run)            |

> 说明：`❌` 不等于"不可用"——对应 apk 已在第三方仓库中，需要时在 `shell/custom-packages.sh` 里取消对应注释即可；启用后同名包会覆盖官方源版本。
