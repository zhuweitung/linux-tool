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

# 简易随机数
random_num=$((RANDOM % 12 + 4))
# 生成伪装路径
camouflage="/$(head -n 10 /dev/urandom | md5sum | head -c ${random_num})/"

# 从 /etc/os-release 文件中获取一些变量
source '/etc/os-release'
# 从VERSION中提取发行版系统的英文名称，为了在debian/ubuntu下添加相对应的Nginx apt源
VERSION=$(echo "${VERSION}" | awk -F "[()]" '{print $2}')

# 检查系统
check_system() {
    if [[ "${ID}" == "ubuntu" && $(echo "${VERSION_ID}" | cut -d '.' -f1) -ge 16 ]]; then
        echo -e "${OK} ${GreenBG} 当前系统为 Ubuntu ${VERSION_ID} ${UBUNTU_CODENAME} ${Font}"
        apt update
    else
        echo -e "${Error} ${RedBG} 当前系统为 ${ID} ${VERSION_ID} 不在支持的系统列表内，安装中断 ${Font}"
        exit 1
    fi
}

# 判断是否为root
check_root() {
    if [ 0 == $UID ]; then
        echo -e "${OK} ${GreenBG} 当前用户是root用户，进入安装流程 ${Font}"
        sleep 3
    else
        echo -e "${Error} ${RedBG} 当前用户不是root用户，请切换到root用户后重新执行脚本 ${Font}"
        exit 1
    fi
}

# 打印信息到屏幕
print() {
    if [[ 0 -eq $? ]]; then
        echo -e "${OK} ${GreenBG} $1 完成 ${Font}"
        sleep 1
    else
        echo -e "${Error} ${RedBG} $1 失败${Font}"
        exit 1
    fi
}

# 安装依赖
install_dependency() {
    apt install -y curl wget git zip unzip net-tools bc qrencode build-essential libpcre3 libpcre3-dev zlib1g-dev dbus
    print "安装 依赖"
}

# 基础优化
optimize_system() {
    # 最大文件打开数
    sed -i '/^\*\ *soft\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
    sed -i '/^\*\ *hard\ *nofile\ *[[:digit:]]*/d' /etc/security/limits.conf
    echo '* soft nofile 65536' >>/etc/security/limits.conf
    echo '* hard nofile 65536' >>/etc/security/limits.conf

    # 关闭 Selinux
    if [[ "${ID}" == "centos" ]]; then
        sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
        setenforce 0
    fi
}

# 域名解析检测
check_domain() {
    read -rp "请输入你的域名信息(eg:www.kedr.cc):" domain
    domain_ip=$(ping "${domain}" -c 1 | sed '1{s/[^(]*(//;s/).*//;q}')
    echo -e "${OK} ${GreenBG} 正在获取 公网ip 信息，请耐心等待 ${Font}"
    local_ip=$(curl https://api-ipv4.ip.sb/ip)
    echo -e "域名dns解析IP：${domain_ip}"
    echo -e "本机IP: ${local_ip}"
    sleep 2
    if [[ $(echo "${local_ip}" | tr '.' '+' | bc) -eq $(echo "${domain_ip}" | tr '.' '+' | bc) ]]; then
        echo -e "${OK} ${GreenBG} 域名dns解析IP 与 本机IP 匹配 ${Font}"
        sleep 2
    else
        echo -e "${Error} ${RedBG} 请确保域名添加了正确的 A 记录，否则将无法正常使用 V2ray ${Font}"
        echo -e "${Error} ${RedBG} 域名dns解析IP 与 本机IP 不匹配 是否继续安装？（y/n）${Font}" && read -r install
        case $install in
        [yY][eE][sS] | [yY])
            echo -e "${GreenBG} 继续安装 ${Font}"
            sleep 2
            ;;
        *)
            echo -e "${RedBG} 安装终止 ${Font}"
            exit 2
            ;;
        esac
    fi
}

# 旧配置文件检测
check_old_config_exist() {
    if [[ -f $v2ray_qr_config_file ]]; then
        echo -e "${OK} ${GreenBG} 检测到旧配置文件，即将删除旧文件配置 ${Font}"
        rm -rf $v2ray_qr_config_file
        echo -e "${OK} ${GreenBG} 已删除旧配置  ${Font}"
    fi
}

# 设置端口
set_port() {
    read -rp "请输入连接端口（default:443）:" port
    [[ -z ${port} ]] && port="443"
}

# 安装v2ray
install_v2ray() {
    if [[ -d ${v2ray_conf_dir} ]]; then
        rm -rf ${v2ray_conf_dir}
    fi
    rm -rf $v2ray_systemd_file
    systemctl daemon-reload
    bash <(curl -Ls https://raw.githubusercontent.com/zhuweitung/linux-tool/master/v2ray/install_v2ray.sh) && systemctl daemon-reload
    print "安装 V2ray"
}

# 检测nginx是否存在
check_nginx_exist() {
    if [[ -f "/usr/sbin/nginx" ]]; then
        echo -e "${OK} ${GreenBG} Nginx已存在，跳过nginx安装过程 ${Font}"
        sleep 2
    else
        nginx_install
    fi
}

# 安装nginx
nginx_install() {
    apt install -y nginx
    print "安装 nginx"
}

# v2ray配置文件增加tls
add_v2ray_conf_tls() {
    if [[ ! -d ${v2ray_conf_dir} ]]; then
        mkdir -p ${v2ray_conf_dir}
    fi
    cd ${v2ray_conf_dir} || exit
    wget --no-check-certificate https://raw.githubusercontent.com/zhuweitung/linux-tool/master/v2ray/vless_tls_config.json -O ${v2ray_conf}
    modify_path
    modify_inbound_port
    modify_UUID
}

# 修改伪装路径
modify_path() {
    sed -i "/\"path\"/c \\\t  \"path\":\"${camouflage}\"" ${v2ray_conf}
    print "V2ray 伪装路径 修改"
}

# 修改入站端口
modify_inbound_port() {
    if [[ "$shell_mode" != "h2" ]]; then
        PORT=$((RANDOM + 10000))
        sed -i "9c \    \"port\":${PORT}," ${v2ray_conf}
    else
        sed -i "8c \    \"port\":${port}," ${v2ray_conf}
    fi
    print "V2ray inbound_port 修改"
}

# 修改uuid
modify_UUID() {
    [ -z "$UUID" ] && UUID=$(cat /proc/sys/kernel/random/uuid)
    sed -i "/\"id\"/c \\\t  \"id\":\"${UUID}\"," ${v2ray_conf}
    print "V2ray UUID 修改"
    [ -f ${v2ray_qr_config_file} ] && sed -i "/\"id\"/c \\  \"id\": \"${UUID}\"," ${v2ray_qr_config_file}
    echo -e "${OK} ${GreenBG} UUID:${UUID} ${Font}"
}

# 设置ssl证书
set_ssl_certificate() {
    read -rp "请输入证书文件路径:" ssl_certificate_path
    [[ -z ${ssl_certificate_path} ]] && exit
    [[ ! -f ${ssl_certificate_path} ]] && echo -e "${Error} ${RedBG} 证书文件不存在，请提前准备好证书并放在指定目录下 ${Font}"
    read -rp "请输入证书密钥文件路径:" ssl_certificate_key_path
    [[ -z ${ssl_certificate_key_path} ]] && exit
    [[ ! -f ${ssl_certificate_key_path} ]] && echo -e "${Error} ${RedBG} 证书密钥文件不存在，请提前准备好证书密钥并放在指定目录下 ${Font}"
}

# 新增nginx配置文件
add_nginx_conf() {
    touch ${nginx_conf}
    cat >${nginx_conf} <<EOF
server {
    listen ${port} ssl http2;
    listen [::]:${port} http2;
    ssl_certificate       ${ssl_certificate_path};
    ssl_certificate_key   ${ssl_certificate_key_path};
    ssl_protocols         TLSv1.3;
    ssl_ciphers           TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;
    server_name           ${domain};
    root  ${nginx_web_dir};
    index index.html index.htm;
    error_page 400 = /400.html;

    ssl_early_data on;
    ssl_stapling on;
    ssl_stapling_verify on;
    add_header Strict-Transport-Security "max-age=31536000";

    location ${camouflage} {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:${PORT};
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        proxy_set_header Early-Data \$ssl_early_data;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name ${domain};
    return 301 https://${domain}\$request_uri;
}
EOF
    print "Nginx 配置修改"
}

# 安装站点
install_website() {
    if [[ -d ${nginx_web_dir} ]]; then
        rm -rf ${nginx_web_dir}
    fi
    git clone https://github.com/zhuweitung/3DCEList.git ${nginx_web_dir}
    print "安装 web站点"
}

# 生成v2ray二维码配置文件
gen_v2ray_qr_config_file() {
    cat >$v2ray_qr_config_file <<EOF
{
  "v": "2",
  "ps": "${domain}",
  "add": "${domain}",
  "port": "${port}",
  "id": "${UUID}",
  "aid": "${alterID}",
  "net": "ws",
  "type": "none",
  "host": "${domain}",
  "path": "${camouflage}",
  "tls": "tls"
}
EOF
}

# 解析v2ray二维码配置文件
extraction_v2ray_qr_config_file() {
    grep "$1" $v2ray_qr_config_file | awk -F '"' '{print $4}'
}

# 生成v2ray配置信息
gen_v2ray_info_file() {
    {
        echo -e "${OK} ${GreenBG} V2ray+ws+tls 安装成功 ${Font}"
        echo -e "${Red} V2ray 配置信息 ${Font}"
        echo -e "${Red} 地址（address）:${Font} $(extraction_v2ray_qr_config_file '\"add\"') "
        echo -e "${Red} 端口（port）：${Font} $(extraction_v2ray_qr_config_file '\"port\"') "
        echo -e "${Red} 用户id（UUID）：${Font} $(extraction_v2ray_qr_config_file '\"id\"')"

        if [[ $(grep -ic 'VLESS' ${v2ray_conf}) == 0 ]]; then
            echo -e "${Red} 额外id（alterId）：${Font} $(extraction_v2ray_qr_config_file '\"aid\"')"
        fi

        echo -e "${Red} 加密（encryption）：${Font} none "
        echo -e "${Red} 传输协议（network）：${Font} $(extraction_v2ray_qr_config_file '\"net\"') "
        echo -e "${Red} 伪装类型（type）：${Font} none "
        echo -e "${Red} 路径（不要落下/）：${Font} $(extraction_v2ray_qr_config_file '\"path\"') "
        echo -e "${Red} 底层传输安全：${Font} tls "
    } >"${v2ray_info_file}"
}

# 打印v2ray配置信息
show_information() {
    cat "${v2ray_info_file}"
}

# 启动应用
start_process_systemd() {
    systemctl daemon-reload
    chown -R root.root /var/log/v2ray/
    if [[ "$shell_mode" != "h2" ]]; then
        nginx -s reload
        systemctl restart nginx
        print "Nginx 启动"
    fi
    systemctl restart v2ray
    print "V2ray 启动"
}

# 设置自启
enable_process_systemd() {
    systemctl enable v2ray
    print "设置 v2ray 开机自启"
    systemctl enable nginx
    print "设置 nginx 开机自启"
}

# 安装 vless+ws+tls
install_v2ray_ws_tls() {
    check_root
    check_system
    install_dependency
    optimize_system
    check_domain
    check_old_config_exist
    set_port
    install_v2ray
    check_nginx_exist
    add_v2ray_conf_tls
    set_ssl_certificate
    add_nginx_conf
    install_website
    gen_v2ray_qr_config_file
    gen_v2ray_info_file
    show_information
    start_process_systemd
    enable_process_systemd
}

install_v2ray_ws_tls
