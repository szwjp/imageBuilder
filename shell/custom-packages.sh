#!/bin/bash
# 自定义软件包配置 (ImmortalWrt 25.12.x, APK)
# 启用方式: 把包名加入下方对应的 CUSTOM_PACKAGES 行即可; 备选包见文末清单
# 主 Web 服务器: nginx 经 uwsgi 跑 LuCI, 自签 HTTPS 监听 80/443; uhttpd 降级为 8080/8443 备用
# nginx-full 自带 nginx-ssl-util(自签证书), nginx-mod-luci 自动拉入 uwsgi 并接线 LuCI

# ============ 公共基础包 ============
CUSTOM_PACKAGES="$CUSTOM_PACKAGES curl"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES openssh-sftp-server"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES nginx-full nginx-mod-luci"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES kmod-tcp-bbr"

# ============ 第三方 (szwjp/luci 仓库, 见 shell/luci-dirs.txt) ============
# 文件管理
CUSTOM_PACKAGES="$CUSTOM_PACKAGES bash quickfile luci-app-quickfile luci-i18n-quickfile-zh-cn"
# 流量监控 by timsaya
CUSTOM_PACKAGES="$CUSTOM_PACKAGES bandix luci-app-bandix luci-i18n-bandix-zh-cn"
# 代理内核 (官方源自带 homeproxy 和 passwall; 以下为自封装内核 apk, 覆盖官方源低版本)
CUSTOM_PACKAGES="$CUSTOM_PACKAGES xray-core sing-box hysteria kmod-nft-socket kmod-nft-tproxy luci-app-passwall2 luci-i18n-passwall2-zh-cn"
# 反向代理
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-lucky-zh-cn"

# ============ ImmortalWrt 官方源 ============
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-acme-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-adblock-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-autoreboot-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-banip-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-base-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-ddns-go-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-diskman-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-firewall-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-homeproxy-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-ipsec-vpnd-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-netdata-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-openvpn-server-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-package-manager-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-samba4-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-sqm-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-ttyd-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-uhttpd-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-upnp-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-i18n-wol-zh-cn"

# ============ 备选包清单 (按功能分组; 启用时加入上方对应行) ============
# 注意: luci-app-run 与 quickfile 的 nginx 配置冲突, 请勿同时集成
# 文件管理: luci-app-run
# 主题: luci-theme-aurora luci-app-aurora-config luci-i18n-aurora-config-zh-cn
# 分区扩容: luci-app-partexp luci-i18n-partexp-zh-cn
# 网络加速: luci-i18n-turboacc-zh-cn
# 代理: luci-i18n-nikki-zh-cn luci-app-ssr-plus luci-i18n-ssr-plus-zh-cn luci-app-openclash luci-compat kmod-tun kmod-inet-diag ip-full unzip luci-app-passwall luci-i18n-passwall-zh-cn
# 其他: luci-i18n-3cat-zh-cn luci-i18n-3ginfo-lite-zh-cn luci-i18n-acl-zh-cn luci-i18n-adblock-fast-zh-cn luci-i18n-advanced-reboot-zh-cn luci-i18n-airplay2-zh-cn luci-i18n-amule-zh-cn luci-i18n-antiblock-zh-cn luci-i18n-appfilter-zh-cn luci-i18n-argon-config-zh-cn luci-i18n-aria2-zh-cn luci-i18n-arpbind-zh-cn luci-i18n-attendedsysupgrade-zh-cn luci-i18n-battstatus-zh-cn luci-i18n-bcp38-zh-cn luci-i18n-bitsrunlogin-go-zh-cn luci-i18n-bmx7-zh-cn luci-i18n-cd8021x-zh-cn luci-i18n-cifs-mount-zh-cn luci-i18n-clamav-zh-cn luci-i18n-cloudflared-zh-cn luci-i18n-commands-zh-cn luci-i18n-coovachilli-zh-cn luci-i18n-cpulimit-zh-cn luci-i18n-crowdsec-firewall-bouncer-zh-cn luci-i18n-dae-zh-cn luci-i18n-daed-zh-cn luci-i18n-dashboard-zh-cn luci-i18n-dawn-zh-cn luci-i18n-dcwapd-zh-cn luci-i18n-ddns-zh-cn luci-i18n-docker-zh-cn luci-i18n-dockerman-zh-cn luci-i18n-dsl-zh-cn luci-i18n-dufs-zh-cn luci-i18n-dump1090-zh-cn luci-i18n-email-zh-cn luci-i18n-eoip-zh-cn luci-i18n-eqos-zh-cn luci-i18n-example-zh-cn luci-i18n-filebrowser-go-zh-cn luci-i18n-filebrowser-zh-cn luci-i18n-filemanager-zh-cn luci-i18n-frpc-zh-cn luci-i18n-frps-zh-cn luci-i18n-fwknopd-zh-cn luci-i18n-gost-zh-cn luci-i18n-hd-idle-zh-cn luci-i18n-https-dns-proxy-zh-cn luci-i18n-irqbalance-zh-cn luci-i18n-keepalived-zh-cn luci-i18n-ksmbd-zh-cn luci-i18n-lldpd-zh-cn luci-i18n-lxc-zh-cn luci-i18n-microsocks-zh-cn luci-i18n-minidlna-zh-cn luci-i18n-minieap-zh-cn luci-i18n-modemband-zh-cn luci-i18n-mosquitto-zh-cn luci-i18n-msd_lite-zh-cn luci-i18n-music-remote-center-zh-cn luci-i18n-mwan3-zh-cn luci-i18n-n2n-zh-cn luci-i18n-natmap-zh-cn luci-i18n-nextdns-zh-cn luci-i18n-nfs-zh-cn luci-i18n-ngrokc-zh-cn luci-i18n-nlbwmon-zh-cn luci-i18n-nps-zh-cn luci-i18n-nut-zh-cn luci-i18n-ocserv-zh-cn luci-i18n-oled-zh-cn luci-i18n-olsr-zh-cn luci-i18n-olsr-services-zh-cn luci-i18n-olsr-viz-zh-cn luci-i18n-omcproxy-zh-cn luci-i18n-openlist-zh-cn luci-i18n-openvpn-zh-cn luci-i18n-openwisp-zh-cn luci-i18n-oscam-zh-cn luci-i18n-p910nd-zh-cn luci-i18n-pagekitec-zh-cn luci-i18n-pbr-zh-cn luci-i18n-pppoe-relay-zh-cn luci-i18n-pppoe-server-zh-cn luci-i18n-privoxy-zh-cn luci-i18n-ps3netsrv-zh-cn luci-i18n-qbittorrent-zh-cn luci-i18n-qos-zh-cn luci-i18n-radicale3-zh-cn luci-i18n-ramfree-zh-cn luci-i18n-rclone-zh-cn luci-i18n-rp-pppoe-server-zh-cn luci-i18n-rtp2httpd-zh-cn luci-i18n-rustdesk-server-zh-cn luci-i18n-ser2net-zh-cn luci-i18n-smartdns-zh-cn luci-i18n-sms-tool-js-zh-cn luci-i18n-snmpd-zh-cn luci-i18n-softethervpn-zh-cn luci-i18n-spotifyd-zh-cn luci-i18n-squid-zh-cn luci-i18n-sshtunnel-zh-cn luci-i18n-statistics-zh-cn luci-i18n-syncthing-zh-cn luci-i18n-sysuh3c-zh-cn luci-i18n-tailscale-community-zh-cn luci-i18n-timewol-zh-cn luci-i18n-tinyproxy-zh-cn luci-i18n-tor-zh-cn luci-i18n-transmission-zh-cn luci-i18n-travelmate-zh-cn luci-i18n-ua2f-zh-cn luci-i18n-udpxy-zh-cn luci-i18n-unbound-zh-cn luci-i18n-usb-printer-zh-cn luci-i18n-usteer-zh-cn luci-i18n-ustreamer-zh-cn luci-i18n-v2raya-zh-cn luci-i18n-vlmcsd-zh-cn luci-i18n-vnstat2-zh-cn luci-i18n-vsftpd-zh-cn luci-i18n-watchcat-zh-cn luci-i18n-wechatpush-zh-cn luci-i18n-wifischedule-zh-cn luci-i18n-xfrpc-zh-cn luci-i18n-xinetd-zh-cn luci-i18n-xlnetacc-zh-cn luci-i18n-zerotier-zh-cn
