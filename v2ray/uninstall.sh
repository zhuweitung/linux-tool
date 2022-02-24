#!/bin/bash

# 打印颜色
Green="\033[32m"
Red="\033[31m"
Yellow="\033[33m"
GreenBG="\033[42;37m"
RedBG="\033[41;37m"
YellowBG="\033[43;37m"
Font="\033[0m"

# 通知信息模板
OK="${Green}[OK]${Font}"
Error="${Red}[错误]${Font}"
Warning="${Red}[警告]${Font}"

# v2ray文件路径配置
v2ray_conf_dir="/etc/v2ray"
v2ray_conf="${v2ray_conf_dir}/config.json"
v2ray_info_file="${v2ray_conf_dir}/v2ray_info.inf"
v2ray_qr_config_file="${v2ray_conf_dir}/vless_qr.json"
v2ray_access_log="/var/log/v2ray/access.log"
v2ray_error_log="/var/log/v2ray/error.log"
v2ray_bin_dir="/usr/local/bin/v2ray"
v2ctl_bin_dir="/usr/local/bin/v2ctl"
v2ray_systemd_file="/etc/systemd/system/v2ray.service"
# nginx文件路径配置
nginx_dir="/etc/nginx"
nginx_conf_dir="${nginx_dir}/conf.d"
nginx_conf="${nginx_conf_dir}/v2ray.conf"
nginx_web_dir="/var/www/3DCEList"

# 其他变量
shell_mode="ws"

# 停止进程
stop_process_systemd() {
    if [[ "$shell_mode" != "h2" ]]; then
        systemctl stop nginx
    fi
    systemctl stop v2ray
}

# 卸载 v2ray nginx
uninstall() {
    stop_process_systemd
    [[ -f $v2ray_systemd_file ]] && rm -f $v2ray_systemd_file
    [[ -f $v2ray_bin_dir ]] && rm -rf $v2ray_bin_dir
    [[ -f $v2ctl_bin_dir ]] && rm -rf $v2ctl_bin_dir
    if [[ -d $nginx_dir ]]; then
        echo -e "${OK} ${Green} 是否卸载 Nginx [Y/N]? ${Font}"
        read -r uninstall_nginx
        case $uninstall_nginx in
        [yY][eE][sS] | [yY])
            rm -rf $nginx_dir
            apt --purge remove nginx nginx-common nginx-core -y && apt autoremove -y
            echo -e "${OK} ${Green} 已卸载 Nginx ${Font}"
            ;;
        *) ;;
        esac
    fi
    [[ -d $v2ray_conf_dir ]] && rm -rf $v2ray_conf_dir
    [[ -d ${nginx_web_dir} ]] && rm -rf ${nginx_web_dir}
    systemctl daemon-reload
    echo -e "${OK} ${GreenBG} 已卸载 ${Font}"
}

uninstall