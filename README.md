# Linux 脚本工具箱
>  记录自己常用的linux脚本

- [Linux 脚本工具箱](#linux-脚本工具箱)
    - [vless ws tls nginx一键安装脚本](#vless-ws-tls-nginx一键安装脚本)
    - [Sky-Box工具箱实用脚本](#sky-box工具箱实用脚本)
      - [BBR一键管理脚本](#bbr一键管理脚本)
      - [SWAP一键安装/卸载脚本](#swap一键安装卸载脚本)
      - [Route-trace 路由追踪测试](#route-trace-路由追踪测试)
      - [三网Speedtest测速](#三网speedtest测速)
    - [一键DD纯净系统](#一键dd纯净系统)
    - [官方docker一键安装](#官方docker一键安装)
    - [官方docker-compose安装(amd架构)](#官方docker-compose安装amd架构)
    - [docker-compose安装(arm架构)](#docker-compose安装arm架构)

### vless ws tls nginx一键安装脚本

```bash
# 安装
# 需提前准备域名、证书文件、证书密钥文件
bash <(curl -Ls https://raw.githubusercontent.com/zhuweitung/linux-tool/master/v2ray/install.sh)

# 卸载
bash <(curl -Ls https://raw.githubusercontent.com/zhuweitung/linux-tool/master/v2ray/uninstall.sh)
```

*本脚本基于[wulabing/V2Ray_ws-tls_bash_onekey](https://github.com/wulabing/V2Ray_ws-tls_bash_onekey)修改*



### Sky-Box工具箱实用脚本

#### BBR一键管理脚本

```bash
bash <(curl -Ls https://raw.githubusercontent.com/BlueSkyXN/ChangeSource/master/tcp.sh)
```

#### SWAP一键安装/卸载脚本

```bash
bash <(curl -Ls https://raw.githubusercontent.com/BlueSkyXN/ChangeSource/master/swap.sh)
```

#### Route-trace 路由追踪测试

```bash
bash <(curl -Ls https://raw.githubusercontent.com/BlueSkyXN/Route-trace/main/rt.sh)
```

#### 三网Speedtest测速

```bash
bash <(curl -Ls https://raw.githubusercontent.com/BlueSkyXN/SpeedTestCN/main/superspeed.sh)
```

*老源于[BlueSkyXN/SKY-BOX](https://github.com/BlueSkyXN/SKY-BOX)*



### 一键DD纯净系统

```bash
apt-get install -y xz-utils openssl gawk file \
&& bash <(curl -Ls https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh) -u 20.04 -v 64 -p "自定义root密码" -port "自定义ssh端口" -a
```

*来源于[MoeClub/Note](https://github.com/MoeClub/Note)*



### 官方docker一键安装

```bash
bash <(curl -Ls https://get.docker.com)
docker -v
systemctl enable docker
```

来源于[Install Docker Engine on Ubuntu | Docker Documentation](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script)



### 官方docker-compose安装(amd架构)

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version
```

来源于[Install Docker Compose | Docker Documentation](https://docs.docker.com/compose/install/#install-compose-on-linux-systems)



### docker-compose安装(arm架构)

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/v2.2.3/docker-compose-$(uname -s | tr '[A-Z]' '[a-z]')-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
docker-compose --version
```

