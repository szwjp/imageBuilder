#!/bin/sh
# 99-custom.sh 就是immortalwrt固件首次启动时运行的脚本 位于固件内的/etc/uci-defaults/99-custom.sh
# Log file for debugging
LOGFILE="/etc/config/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >>$LOGFILE
# 设置默认防火墙规则，方便单网口虚拟机首次访问 WebUI
# 因为本项目中 单网口模式是dhcp模式 直接就能上网并且访问web界面 避免新手每次都要修改/etc/config/network中的静态ip
# 当你刷机运行后 都调整好了 你完全可以在web页面自行关闭 wan口防火墙的入站数据
# 具体操作方法：网络——防火墙 在wan的入站数据 下拉选项里选择 拒绝 保存并应用即可。
# 按名称查找 wan zone 并放行入站 (不硬编码索引, 避免防火墙配置顺序变化导致失效)
wan_zone=$(uci show firewall | awk -F '[.=]' '/\.name=.wan.$/ {print $2; exit}')
if [ -n "$wan_zone" ]; then
    uci set "firewall.$wan_zone.input='ACCEPT'"
    echo "wan zone ($wan_zone) 入站已放行" >>$LOGFILE
else
    echo "warning: cannot find wan zone, skip firewall input ACCEPT" >>$LOGFILE
fi

# 设置主机名映射，解决安卓原生 TV 无法联网的问题
uci add dhcp domain
uci set "dhcp.@domain[-1].name=time.android.com"
uci set "dhcp.@domain[-1].ip=203.107.6.88"

# 检查配置文件pppoe-settings是否存在 该文件由build.sh动态生成
SETTINGS_FILE="/etc/config/pppoe-settings"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "PPPoE settings file not found. Skipping." >>$LOGFILE
else
    # 读取pppoe信息($enable_pppoe、$pppoe_account、$pppoe_password)
    . "$SETTINGS_FILE"
fi

# 1. 先获取所有物理接口列表
ifnames=""
for iface in /sys/class/net/*; do
    iface_name=$(basename "$iface")
    if [ -e "$iface/device" ] && echo "$iface_name" | grep -Eq '^eth|^en'; then
        ifnames="$ifnames $iface_name"
    fi
done
ifnames=$(echo "$ifnames" | awk '{$1=$1};1')

count=$(echo "$ifnames" | wc -w)
echo "Detected physical interfaces: $ifnames" >>$LOGFILE
echo "Interface count: $count" >>$LOGFILE

# 2. 映射 WAN/LAN 接口 (本项目仅 x86-64: 默认最后一个接口为 WAN, 其余为 LAN)
wan_ifname=""
lan_ifnames=""
total_interfaces=$(echo "$ifnames" | wc -w)
wan_ifname=$(echo "$ifnames" | awk -v total="$total_interfaces" '{print $total}')
lan_ifnames=$(echo "$ifnames" | awk -v total="$total_interfaces" '{for(i=1;i<total;i++) printf "%s ", $i; if(total>1) printf "\n"}' | sed 's/[[:space:]]*$//')
echo "Using last interface as WAN mapping: WAN=$wan_ifname LAN=$lan_ifnames" >>"$LOGFILE"

# 3. 配置网络
if [ "$count" -eq 1 ]; then
    # 单网口设备，DHCP模式
    uci set network.lan.proto='dhcp'
    uci delete network.lan.ipaddr
    uci delete network.lan.netmask
    uci delete network.lan.gateway
    uci delete network.lan.dns
    uci commit network || {
        echo "error: uci commit network failed" >>$LOGFILE
    }
elif [ "$count" -gt 1 ]; then
    # 多网口设备配置
    # 配置WAN
    uci set network.wan=interface
    uci set network.wan.device="$wan_ifname"
    uci set network.wan.proto='dhcp'

    # 配置WAN6
    uci set network.wan6=interface
    uci set network.wan6.device="$wan_ifname"
    uci set network.wan6.proto='dhcpv6'

    # 查找 br-lan 设备 section
    section=$(uci show network | awk -F '[.=]' '/\.@?device\[[0-9]+\]\.name=.br-lan.$/ {print $2; exit}')
    if [ -z "$section" ]; then
        # br-lan 不存在(如 config_generate 因 /etc/board.json 已存在而未生成 lan), 主动创建, 避免 LAN 全部失效
        echo "br-lan not found, creating it" >>$LOGFILE
        uci add network device
        uci set network.@device[-1].name='br-lan'
        uci set network.@device[-1].type='bridge'
        section='@device[-1]'
    fi

    # 删除原有ports
    uci -q delete "network.$section.ports"
    # 添加LAN接口端口
    for port in $lan_ifnames; do
        uci add_list "network.$section.ports"="$port"
    done
    # 开启 STP 防止多 LAN 口接入同一交换机时产生环路
    uci set "network.$section.stp"='1'
    echo "Updated br-lan ports: $lan_ifnames" >>$LOGFILE

    # LAN口设置静态IP (显式绑定 br-lan, 并确保 lan 接口存在)
    uci set network.lan=interface
    uci set network.lan.device='br-lan'
    uci set network.lan.proto='static'
    # 多网口设备 支持修改为别的管理后台地址 在Github Action 的UI上自行输入即可
    uci set network.lan.netmask='255.255.255.0'
    # 设置路由器管理后台地址
    IP_VALUE_FILE="/etc/config/custom_router_ip.txt"
    if [ -f "$IP_VALUE_FILE" ]; then
        CUSTOM_IP=$(cat "$IP_VALUE_FILE")
        # 兜底校验: 非合法 IPv4 时退回默认地址, 避免把坏值写进 network 导致失联
        if echo "$CUSTOM_IP" | grep -Eq '^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$'; then
            # 用户在UI上设置的路由器后台管理地址
            uci set network.lan.ipaddr=$CUSTOM_IP
            echo "custom router ip is $CUSTOM_IP" >> $LOGFILE
        else
            uci set network.lan.ipaddr='192.168.1.1'
            echo "warning: invalid custom router ip '$CUSTOM_IP', fallback to 192.168.1.1" >> $LOGFILE
        fi
        # 读完即删: 该文件仅用于首启注入地址, 留在 /etc/config 下无意义
        rm -f "$IP_VALUE_FILE"
    else
        uci set network.lan.ipaddr='192.168.1.1'
        echo "default router ip is 192.168.1.1" >> $LOGFILE
    fi

    # PPPoE设置 (只影响WAN口，不依赖LAN配置)
    echo "enable_pppoe value: $enable_pppoe" >>$LOGFILE
    if [ "$enable_pppoe" = "yes" ]; then
        echo "PPPoE enabled, configuring..." >>$LOGFILE
        uci set network.wan.proto='pppoe'
        uci set network.wan.username="$pppoe_account"
        uci set network.wan.password="$pppoe_password"
        uci set network.wan.peerdns='1'
        uci set network.wan.auto='1'
        uci set network.wan6.proto='none'
        echo "PPPoE config done." >>$LOGFILE
    else
        echo "PPPoE not enabled." >>$LOGFILE
    fi

    uci commit network || {
        echo "error: uci commit network failed" >>$LOGFILE
    }
fi

# 设置所有网口可访问网页终端
uci -q delete ttyd.@ttyd[0].interface

# 设置所有网口可连接 SSH
uci set dropbear.@dropbear[0].Interface=''
uci commit

# 设置编译作者信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="Packaged by szwjp"
if [ -f "$FILE_PATH" ]; then
    sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"
fi

# 若luci-app-advancedplus (进阶设置)已安装 则去除zsh的调用 防止命令行报 /usr/bin/zsh: not found的提示
if [ -f /usr/lib/lua/luci/controller/advancedplus.lua ]; then
    sed -i '/\/usr\/bin\/zsh/d' /etc/profile
    sed -i '/\/bin\/zsh/d' /etc/init.d/advancedplus
    sed -i '/\/usr\/bin\/zsh/d' /etc/init.d/advancedplus
    echo "fix ttyd show msg: /usr/bin/zsh: not found" >>$LOGFILE
fi

# nginx 为主 Web 服务器 (80/443, 自签 HTTPS, 经 uwsgi 跑 LuCI), 由 nginx-full + nginx-mod-luci 提供
# nginx 默认 include conf.d/*.locations, quickfile 等插件无需专项配置即可被服务
# uhttpd 降级为备用入口, 移至 8080(http)/8443(https) 以让出 80/443 给 nginx
uci -q delete uhttpd.main.listen_http
uci add_list uhttpd.main.listen_http='0.0.0.0:8080'
uci add_list uhttpd.main.listen_http='[::]:8080'
uci -q delete uhttpd.main.listen_https
uci add_list uhttpd.main.listen_https='0.0.0.0:8443'
uci add_list uhttpd.main.listen_https='[::]:8443'
uci commit uhttpd
# nginx-mod-luci 的 60_nginx-luci-support 会 disable+stop uhttpd, 这里重新启用以保留备用入口
/etc/init.d/uhttpd enable
/etc/init.d/uhttpd restart
echo "uhttpd moved to 8080/8443 (backup); nginx primary on 80/443" >>$LOGFILE

# 80 与 443 均直接提供 LuCI: 把默认只做 80→443 跳转的 _redirect2ssl 改为直接服务 conf.d 内容
# 不修改 _lan (其 uci_manage_ssl 由 nginx-util 管理), 避免改动被重置
uci -q delete nginx._redirect2ssl.return
uci add_list nginx._redirect2ssl.include='restrict_locally'
uci add_list nginx._redirect2ssl.include='conf.d/*.locations'
uci commit nginx
# 60_nginx-luci-support 已先启动 nginx(用默认跳转配置), 重启使其加载上面的 80 直连配置
/etc/init.d/nginx restart

# 若安装了dockerd 则设置docker的防火墙规则
# 扩大docker涵盖的子网范围 '172.16.0.0/12'
# 方便各类docker容器的端口顺利通过防火墙
if command -v dockerd >/dev/null 2>&1; then
    echo "检测到 Docker，正在配置防火墙规则..."

    # 删除所有名为 docker 的 zone (含 uci add 创建的匿名 section, 保证脚本可重复执行)
    for dz_old in $(uci show firewall | awk -F '[.=]' '/\.name=.docker.$/ {print $2}'); do
        uci -q delete "firewall.$dz_old"
    done

    # 先获取所有 forwarding 索引，倒序排列删除
    for idx in $(uci show firewall | grep "=forwarding" | cut -d[ -f2 | cut -d] -f1 | sort -rn); do
        src=$(uci get firewall.@forwarding[$idx].src 2>/dev/null)
        dest=$(uci get firewall.@forwarding[$idx].dest 2>/dev/null)
        echo "Checking forwarding index $idx: src=$src dest=$dest"
        if [ "$src" = "docker" ] || [ "$dest" = "docker" ]; then
            echo "Deleting forwarding @forwarding[$idx]"
            uci delete firewall.@forwarding[$idx]
        fi
    done

    # 用 uci add 重建 zone + forwarding (避免直接追加文件在脚本重跑时产生重复配置)
    # 注意: uci add 返回的句柄不带包名前缀, 后续 set/add_list 必须补 firewall. 前缀, 否则 uci 报 Entry not found
    dz=$(uci add firewall zone)
    uci set "firewall.$dz.name='docker'"
    uci set "firewall.$dz.input='ACCEPT'"
    uci set "firewall.$dz.output='ACCEPT'"
    uci set "firewall.$dz.forward='ACCEPT'"
    uci add_list "firewall.$dz.subnet='172.16.0.0/12'"

    df1=$(uci add firewall forwarding)
    uci set "firewall.$df1.src='docker'"
    uci set "firewall.$df1.dest='lan'"

    df2=$(uci add firewall forwarding)
    uci set "firewall.$df2.src='docker'"
    uci set "firewall.$df2.dest='wan'"

    df3=$(uci add firewall forwarding)
    uci set "firewall.$df3.src='lan'"
    uci set "firewall.$df3.dest='docker'"

    uci commit firewall
    echo "Docker 防火墙规则已配置 (zone: $dz)" >>$LOGFILE
else
    echo "未检测到 Docker，跳过防火墙配置。"
fi

# PPPoE 凭据已写入 network 配置, 删除明文源文件避免残留
rm -f "$SETTINGS_FILE"

exit 0
