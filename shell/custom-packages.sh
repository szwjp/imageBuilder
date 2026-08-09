#!/bin/bash
# 自定义软件包配置 (OpenWrt 25.12.x, APK)
# 启用方式: 把包名加入下方对应的 CUSTOM_PACKAGES 行即可; 备选包见文末清单
# 主 Web 服务器: nginx 经 uwsgi 跑 LuCI, 自签 HTTPS 监听 80/443; uhttpd 降级为 8080/8443 备用
# nginx-full 自带 nginx-ssl-util(自签证书), nginx-mod-luci 自动拉入 uwsgi 并接线 LuCI

# ============ 公共基础包 ============
CUSTOM_PACKAGES="$CUSTOM_PACKAGES curl"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES openssh-sftp-server"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES nginx-full nginx-mod-luci"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES kmod-tcp-bbr"

# ============ 第三方 (szwjp/luci 仓库, 见 shell/luci-dirs.txt) ============
# 文件管理 (注意: luci-app-run 与 quickfile 的 nginx 配置冲突, 请勿同时集成)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES bash quickfile luci-app-quickfile luci-i18n-quickfile-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-run"
# 流量监控 by timsaya
CUSTOM_PACKAGES="$CUSTOM_PACKAGES bandix luci-app-bandix luci-i18n-bandix-zh-cn"
# 代理 (自封装内核 apk 覆盖官方源低版本; naiveproxy 走官方源)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES xray-core sing-box hysteria kmod-nft-socket kmod-nft-tproxy luci-app-passwall2 luci-i18n-passwall2-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES xray-core sing-box hysteria luci-app-passwall luci-i18n-passwall-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES kmod-nft-tproxy kmod-nft-socket xray-core naiveproxy luci-app-ssr-plus luci-i18n-ssr-plus-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-homeproxy-zh-cn"
# 反向代理
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-lucky-zh-cn"
# 网络加速
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-turboacc-zh-cn"
# 官方源不含 openvpn-server, 作为第三方加入
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-openvpn-server-zh-cn"

# ============ 官方源 ============
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-acme-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-adblock-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-base-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-ddns-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-firewall-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-package-manager-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-samba4-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-sqm-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-ttyd-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-uhttpd-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-upnp-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-wol-zh-cn"

# ============ 备选包清单 (按功能分组; 启用时加入上方对应行) ============
# 主题: luci-theme-aurora luci-app-aurora-config luci-i18n-aurora-config-zh-cn
# 分区扩容: luci-app-partexp luci-i18n-partexp-zh-cn
# 代理: luci-i18n-nikki-zh-cn luci-app-openclash luci-compat kmod-tun kmod-inet-diag bash ip-full unzip
# 其他: luci-i18n-acl-zh-cn luci-i18n-adblock-fast-zh-cn luci-i18n-advanced-reboot-zh-cn luci-i18n-antiblock-zh-cn luci-i18n-apinger-zh-cn luci-i18n-aria2-zh-cn luci-i18n-attendedsysupgrade-zh-cn luci-i18n-babeld-zh-cn luci-i18n-banip-zh-cn luci-i18n-bcp38-zh-cn luci-i18n-bmx7-zh-cn luci-i18n-chrony-zh-cn luci-i18n-clamav-zh-cn luci-i18n-cloudflared-zh-cn luci-i18n-commands-zh-cn luci-i18n-coovachilli-zh-cn luci-i18n-crowdsec-firewall-bouncer-zh-cn luci-i18n-csshnpd-zh-cn luci-i18n-dawn-zh-cn luci-i18n-dcwapd-zh-cn luci-i18n-dockerman-zh-cn luci-i18n-dump1090-zh-cn luci-i18n-email-zh-cn luci-i18n-eoip-zh-cn luci-i18n-example-zh-cn luci-i18n-filebrowser-zh-cn luci-i18n-filemanager-zh-cn luci-i18n-frpc-zh-cn luci-i18n-frps-zh-cn luci-i18n-fwknopd-zh-cn luci-i18n-hd-idle-zh-cn luci-i18n-https-dns-proxy-zh-cn luci-i18n-irqbalance-zh-cn luci-i18n-keepalived-zh-cn luci-i18n-ksmbd-zh-cn luci-i18n-libreswan-zh-cn luci-i18n-lldpd-zh-cn luci-i18n-lxc-zh-cn luci-i18n-minidlna-zh-cn luci-i18n-mosquitto-zh-cn luci-i18n-mwan3-zh-cn luci-i18n-natmap-zh-cn luci-i18n-nextdns-zh-cn luci-i18n-nlbwmon-zh-cn luci-i18n-nut-zh-cn luci-i18n-ocserv-zh-cn luci-i18n-olsr-zh-cn luci-i18n-olsr-services-zh-cn luci-i18n-olsr-viz-zh-cn luci-i18n-omcproxy-zh-cn luci-i18n-openlist-zh-cn luci-i18n-openvpn-zh-cn luci-i18n-openwisp-zh-cn luci-i18n-p910nd-zh-cn luci-i18n-pagekitec-zh-cn luci-i18n-partexp-zh-cn luci-i18n-pbr-zh-cn luci-i18n-privoxy-zh-cn luci-i18n-qos-zh-cn luci-i18n-radicale3-zh-cn luci-i18n-rp-pppoe-server-zh-cn luci-i18n-rustdesk-server-zh-cn luci-i18n-ser2net-zh-cn luci-i18n-smartdns-zh-cn luci-i18n-snmpd-zh-cn luci-i18n-softether-zh-cn luci-i18n-squid-zh-cn luci-i18n-sshtunnel-zh-cn luci-i18n-statistics-zh-cn luci-i18n-strongswan-swanctl-zh-cn luci-i18n-tailscale-community-zh-cn luci-i18n-tinyproxy-zh-cn luci-i18n-tor-zh-cn luci-i18n-transmission-zh-cn luci-i18n-travelmate-zh-cn luci-i18n-udpxy-zh-cn luci-i18n-unbound-zh-cn luci-i18n-usteer-zh-cn luci-i18n-ustreamer-zh-cn luci-i18n-v2raya-zh-cn luci-i18n-vnstat2-zh-cn luci-i18n-watchcat-zh-cn luci-i18n-wifihistory-zh-cn luci-i18n-wifischedule-zh-cn luci-i18n-xfrpc-zh-cn luci-i18n-xinetd-zh-cn
