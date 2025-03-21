#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/bin/dpkg:/bin/pwd:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
clear;

CopyrightLogo='
==========================================================================
# 最近更新：2025-03-20
# 支持版本 Ubuntu 24.04 64位
# 支持版本 python版本跟随操作系统，Ubuntu 20(Python3.8.10)
# 作者: Ivan Deng
# 支持: https://www.odooai.cn
#-------------------------------------------------------------------------------
# 本脚本将安装Odoo到你的服务器上，一般而言，整个过程在3~5分钟完成
# 为使中文设置生效，建议重启一下机器。 执行 reboot
#-------------------------------------------------------------------------------
# 使用方法，直接在主机上执行以下指令
#-------------------------------------------------------------------------------
# (1) 选择要安装的类型
# 1为从odoo官网安装odoo18，2为安装本地社区版odoo18，3为安装本地企业版odoo18(请联系购买)
# 选择2时请确保 odoo_18.0.latest_all.deb 已上传至当前目录
# 选择3时请确保 odoo_18.0+e.latest_all.deb 已上传至当前目录
# (2) 选择要安装的Postgresql 数据库
# 数据库安装上，当前 ubuntu 24 默认已经是安装 Postgresql 16
# 选择 PG14 版本将有更好性能，部份阿里云服务器无法访问最新 postgresql 官网源会导致安装失败
# (3) 选择是否要安装Nginx
# 安装Nginx则可直接使用80端口访问odoo，同时可使用网站即时通讯。
# 注意，当前Nginx的配置只支持 www.* 开始的网站。如果域名为其它或者是IP，请自行更改 nginx.conf
#-------------------------------------------------------------------------------
# 本脚本执行完成后，您将得到
#-------------------------------------------------------------------------------
# 1. 中文字体，PDF报表，时间同步，SCSS编译等odoo支持组件
# 2. postgres 16 安装在 /usr/lib/postgresql/16
# 3. postgres 16 配置在 /etc/postgresql/16/main
# 4. odoo 最新版 安装在 /usr/lib/python3/dist-packages/odoo
# 5. odoo 配置文件位于 /etc/odoo/odoo.conf
# 6. Nginx 作为反向代理，开启了多worker工作模式，可使用odoo在线即时通讯
# 7. odoo访问地址为(用你的域名代替 yourserver.com) http://yourserver.com 或者http://yourserver.com:8069
# 8. 一个 r.sh 文件用于重启 odoo 服务，使用root用户登录后键入bash r.sh 即可执行
# 9. 使用最新的pdf打印组件wkhtmltox 0.12.5 版本，打印更清晰
# 10.增加python库，主要支持企业版中 ical, ldap, esc/pos，参考 https://www.odooai.cn/documentation/16.0/zh_CN/administration/install/install.html
#-------------------------------------------------------------------------------
# 如遇问题，可卸载 pg 及 odoo，重新安装
#-------------------------------------------------------------------------------
## sudo aptitude remove  -y postgresql
## sudo aptitude remove  -y odoo
==========================================================================';
echo "$CopyrightLogo";
#--------------------------------------------------
# 变量定义
#--------------------------------------------------
# 当前目录
CURDIR=$(pwd)
# Ubuntu的版本号
U_Version=$(lsb_release -r --short)
U_Version=${U_Version:0:2}
O_USER="odoo"
O_HOME="/usr/lib/python3/dist-packages/odoo"
O_HOME_EXT="/$O_USER/${O_USER}-server"
# 安装 WKHTMLTOPDF，默认设置为 True ，如果已安装则设置为 False.
INSTALL_WKHTMLTOPDF="True"
# 中文字体相关
O_FONT="https://www.odooai.cn/download/microsoft.zip"
# 默认 odoo 端口 8069，建议安装 nginx 做前端端口映射，这样才能使用 livechat
O_PORT="8069"
# 选择要安装的odoo版本
O_TYPE=""
O_VERSION="16.0"
O_COMMUNITY_LATEST_16="http://nightly.odoocdn.com/16.0/nightly/deb/odoo_18.0.latest_all.deb"
# 如果要安装odoo企业版，则在此设置为 True
IS_ENTERPRISE="False"
# 选择要安装的pg版本
O_PG=""
# 选择是否要安装nginx，True安装，Fale不安装
O_NGINX="False"
# 设置超管的用户名及密码
O_SUPERADMIN="admin"
# 设置 odoo 配置文件名
O_CONFIG="${O_USER}"
# WKHTMLTOPDF 下载链接，使用https后停用cdn，注意主机版本及 WKHTMLTOPDF的版本
WKHTMLTOX_X64="https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb"
WKHTMLTOX_X32="https://www.odooai.cn/download/wkhtmltox_0.12.5-1.trusty-i386.deb"
# LibPng处理，主要是 U18的bug
LIBPNG_X64="https://www.odooai.cn/download/libpng12-0_1.2.54-1ubuntu1.1_amd64.deb"
LIBPNG_X32="https://www.odooai.cn/download/libpng12-0_1.2.54-1ubuntu1.1_i386.deb"
O_R_FILE="https://www.odooai.cn/download/r18.txt"
# odoo.conf 下载链接，将使用 odooai.cn的
O_CONF_FILE="https://www.odooai.cn/download/odoo.conf"
O_NGINX_CONF_FILE="https://www.odooai.cn/download/nginx.conf"

#--------------------------------------------------
# 更新服务器，多数要人工干预，故可以注释
# 升级服务器到 ubuntu 20，不需要可以注释
#--------------------------------------------------
# echo -e "\n---- Update Server ----"
# apt install update-manager
# apt-get update && sudo apt-get dist-upgrade
# do-release-upgrade -d -m server -q
# sudo add-apt-repository universe
# sudo apt-get update
# sudo apt-get upgrade -y
#--------------------------------------------------
# End 更新服务器
#--------------------------------------------------

#--------------------------------------------------
# 脚本：安装类型，设置密码
#--------------------------------------------------
function ConfirmPg()
{
	echo -e "[Notice] Confirm Install - Postgresql \nPlease select your version: "
	select selected in 'Postgresql 16[Recommend. OS default]' 'Postgresql 13' 'Postgresql 12.x' 'None'; do break; done;
	[ "$selected" != '' ] &&  echo -e "[OK] You Selected: ${selected}\n" && O_PG=$selected && return 0;
	ConfirmPg;
}
function ConfirmOdoo()
{
	echo -e "[Notice] Confirm Install - Odoo 18 \nPlease select your odoo version: (1~9)"
	select selected in 	'Odoo 18 Community from odoo.com 远程社区版' 'Odoo 18 Community from local[odoo_18.0.latest_all.deb] 本地社区版' 'Odoo 18 Enterprise from local[odoo_18.0+e.latest_all.deb] 本地企业版' 'None';
	do break; done;
	[ "$selected" != '' ] &&  echo -e "[OK] You Selected: ${selected}\n" && O_TYPE=$selected && return 0;
	ConfirmOdoo;
}
function ConfirmNg()
{
	echo -e "[Notice] Confirm Install - Nginx for web forward: "
	select selected in 'Nginx for Odoo in port 80[Yes]' 'Odoo standalone in port 8069[No]'; do break; done;
	[ "$selected" != '' ] &&  echo -e "[OK] You Selected: ${selected}\n" && O_NGINX=$selected && return 0;
	ConfirmNg;
}

function SetPassword()
{
	DefaultPassword=`echo -n "${IPAddress}_${RandomValue}_$(date)" | md5sum | sed "s/ .*//" | cut -b -12`;
	echo '[Notice] odoo super Master password:';
	echo "odoo Master Password: ${DefaultPassword}";
	echo '==========================================================================';
}
#--------------------------------------------------
# 安装其它常用依赖，用odoo的deb安装已经默认安装大部分
#--------------------------------------------------
function InstallBase()
{
    # 如果是 centos 执行
    # yum install apt
    # 注意，更新pip 后，可以直接pip，不要pip3
    sudo pip3 install --upgrade pip
    # 删除旧文件，更新源
    rm wkhtmltox*
    sudo apt-get update
    sudo apt upgrade -y
    # 本地化
    sudo apt-get install aptitude -y;sudo aptitude install -y locales


    echo -e "\n--- Installing Python 3 + pip3 --"
#    begin o18 基本
    sudo apt install git wget nodejs npm python3 build-essential libzip-dev python3-dev libxslt1-dev python3-pip libldap2-dev libsasl2-dev -y
    sudo apt install python3-wheel python3-venv python3-setuptools node-less libjpeg-dev xfonts-75dpi xfonts-base libpq-dev libffi-dev fontconfig -y
#    end o18 基本
    sudo apt-get install python3-polib gdebi -y
    sudo apt-get install python3-babel python3-dateutil python3-decorator python3-docutils python3-feedparser python3-gevent python3-html2text -y
    sudo apt-get install python3-jinja2 python3-libsass python3-lxml python3-mako -y
    sudo apt-get install python3-mock python3-ofxparse python3-passlib python3-psutil python3-psycopg2 -y
    sudo apt-get install python3-pydot python3-pyparsing python3-pypdf2 python3-reportlab -y
    sudo apt-get install python3-qrcode python3-vobject  python3-zeep  python3-pyldap -y
    sudo apt-get install python3-xlwt python3-xlsxwriter -y
    sudo apt-get install fonts-inconsolata -y
    sudo apt-get install fonts-font-awesome -y
    sudo apt-get install fonts-roboto-unhinted -y
    # 要注意版本，3.6.x 用 2=2.7.4-1
    sudo apt-get install python3-serial python3-usb python3-vatnumber python3-werkzeug python3-suds -y
    sudo apt-get install libldap2-dev -y
    # nginx 源码安装的支持
    sudo apt-get install libpcre3 libpcre3-dev -y
    sudo apt-get install zlib1g-dev -y
    sudo apt-get install openssl -y
    sudo apt-get install libssl-dev -y

    echo -e "\n---- Install tool packages ----"
    # 要单独执行，因为 u16和u18有些包不同，放一个语句容易出错
    sudo apt-get install sntp -y
    sudo apt-get install git -y
    sudo apt-get install bzr -y
    sudo apt-get install gdebi-core -y
    sudo apt-get install xfonts-base xfonts-75dpi -y

    echo -e "\n--- Install other required packages"
    sudo apt-get install node-clean-css -y
    sudo apt-get install node-less -y
    sudo apt-get install python-gevent -y
    sudo apt-get install libxml2-dev libxslt1-dev libevent-dev libsasl2-dev libldap2-dev libpq-dev libpng-dev libjpeg-dev xz-utils -y
    # 中文字体
    sudo apt-get install xfonts-utils -y
    sudo apt-get install unzip -y
    sudo apt-get install ttf-wqy-* -y && sudo apt-get install ttf-wqy-zenhei -y && sudo apt-get install ttf-wqy-microhei -y
    sudo apt-get install language-pack-zh-hant language-pack-zh-hans -y

    sudo pip3 install phonenumbers num2words scss libsass polib
    sudo pip3 install python-Levenshtein
    sudo pip3 install python-barcode
    sudo pip3 install vobject qrcode pycrypto
    # 注意，1.2.0才支持xlsx，其它高版本只支持xls
    sudo pip3 install xlrd==1.2.0
    sudo pip3 install pyldap
    sudo pip3 install rsa
    sudo pip3 install zxcvbn
#    sudo pip3 install firebase_admin
    # 中文分词
    sudo pip3 install jieba
    # odoo18 企业版
    sudo pip3 install zeep
    # 微信与阿里
    sudo pip3 install wechatpy==1.8.18 python-alipay-sdk pycryptodome alipay-sdk-python==3.6.778
    sudo pip3 install itsdangerous==0.24
    sudo pip3 install kdniao==0.1.2
    sudo pip3 install xmltodict==0.11.0
    export CRYPTOGRAPHY_DONT_BUILD_RUST=1
    sudo pip3 install  cffi
    sudo pip3 install  rust
    sudo pip3 install paramiko
    sudo pip3 install oauthlib
    # odoo18 增加
    sudo pip3 install pdfminer openai
    sudo pip3 install dashscope
    echo -e "\n--- Install Lib from Odoo 18 official list"
    # 下载 r18.txt 文件并安装
    sudo wget -x -q $O_R_FILE -O r18.txt
    sudo pip3 install -r r18.txt
    sudo pip3 install paddlepaddle==2.6.2
    sudo pip3 install paddleocr==2.9.1
    sudo pip3 install diskcache==5.6.3
    sudo pip3 install bardapi==1.0.0
    sudo pip3 install numpy==1.26.4 --upgrade
    sudo pip3 install pyOpenSSL==21.0.0 --upgrade
    sudo pip3 install cryptography==3.4.8 --upgrade
    #     python3 -m pip install xxxx

    # 设置时区，默认先不设置，因为有时是境外主机
    # sudo timedatectl set-timezone "Asia/Shanghai"
    # sudo timedatectl set-timezone "America/New_York"
    # 将你的硬件时钟设置为协调世界时（UTC）：
    sudo timedatectl set-local-rtc 0
    # 自动时间同步到远程NTP服务器，须卸载ntp
    sudo apt-get remove ntp -y
    sudo timedatectl set-ntp no
    sudo apt-get install ntpdate -y
    # 设置系统时间与网络时间同步
    ntpdate cn.pool.ntp.org
    # 将系统时间写入硬件时间
    sudo hwclock --systohc
    #--------------------------------------------------
    # 在 u18里要增加下载内容
    #--------------------------------------------------
    if [ $U_Version = "18" ]; then
      echo -e "\n--- Install extra for ubuntu 18"
      #pick up correct one from x64 & x32 versions:
      if [ "`getconf LONG_BIT`" == "64" ];then
          _url=$LIBPNG_X64
      else
          _url=$LIBPNG_X32
      fi
      sudo wget $_url
#      sudo wget https://www.odooai.cn/download/libpng12-0_1.2.54-1ubuntu1.1_amd64.deb
#      sudo gdebi --n `basename https://www.odooai.cn/download/libpng12-0_1.2.54-1ubuntu1.1_amd64.deb`
      sudo gdebi --n `basename $_url`
      echo "libpng-12 is installed."
    fi

    #--------------------------------------------------
    # 安装 Wkhtmltopdf
    #--------------------------------------------------
    if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
      echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO ----"
      sudo apt-get install xvfb -y
      sudo apt-get install wkhtmltopdf -y

#      sudo ln -f -s /usr/local/bin/wkhtmltopdf /usr/bin
#      sudo ln -f -s /usr/local/bin/wkhtmltoimage /usr/bin
    else
      echo "Wkhtmltopdf isn't installed due to the choice of the user!"
    fi

    #--------------------------------------------------
    # 安装中文字体，装完后要重启
    #--------------------------------------------------
    sudo sh -c 'echo "LANG=\"zh_CN.UTF-8\"" > /etc/default/locale'
    sudo chmod -R 0755 /usr/share/fonts/truetype/wqy && sudo chmod -R 0755 /usr/share/fonts/truetype/wqy/*
    sudo rm -rf /usr/share/fonts/truetype/microsoft
    sudo mkdir /usr/share/fonts/truetype/microsoft
    sudo wget -x -q $O_FONT -O /usr/share/fonts/truetype/microsoft/microsoft.zip
#    sudo wget -x -q https://www.odooai.cn/download/microsoft.zip -O /usr/share/fonts/truetype/microsoft/microsoft.zip
    sudo unzip -q -d /usr/share/fonts/truetype/microsoft /usr/share/fonts/truetype/microsoft/microsoft.zip
    sudo rm /usr/share/fonts/truetype/microsoft/microsoft.zip
    sudo chmod -R 0755 /usr/share/fonts/truetype/microsoft && sudo chmod -R 0755 /usr/share/fonts/truetype/microsoft/*
    cd /usr/share/fonts/truetype/wqy && sudo mkfontscale && sudo mkfontdir && sudo fc-cache -fv
    cd /usr/share/fonts/truetype/microsoft && sudo mkfontscale && sudo mkfontdir && sudo fc-cache -fv

    #--------------------------------------------------
    # cron 配置时间同步，必须要做，避免多数问题，最好停用本机ntpd服务器
    #--------------------------------------------------
    sudo apt-get install ntpdate -y
    sudo systemctl disable ntpd;sudo /etc/init.d/ntp stop;sudo /usr/sbin/ntpdate cn.pool.ntp.org
    sudo echo "0  */2  * * *   root    /usr/sbin/ntpdate cn.pool.ntp.org >> /tmp/tmp.txt" >> /etc/crontab
}
#--------------------------------------------------
# 安装 PostgreSQL Server 14, 13, 12
#--------------------------------------------------
function InstallPg()    {

    if [ "$O_PG" != 'None' ]; then
        echo -e "\n---- Prepare Install $O_PG ----"
        sudo apt-get install curl ca-certificates -y
        sudo apt-get install -y wget ca-certificates
        sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
        sudo wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

        echo -e "\n---- Installing Postgresql Server ----"
        sudo apt-key update
        sudo apt-get update
    fi;

    if [ "$O_PG" == 'Postgresql 16[Recommend. OS default]' ]; then
        sudo apt-get install postgresql-16 postgresql-client -y
    fi;

    if [ "$O_PG" == 'Postgresql 13' ]; then
        sudo apt-get install postgresql-13 -y
    fi;

    if [ "$O_PG" == 'Postgresql 12.x' ]; then
        sudo apt-get install postgresql -y
        sudo apt-get install postgresql-contrib -y
    fi;
}

#--------------------------------------------------
# 安装odoo
#--------------------------------------------------
function InstallOdoo()    {
    if [ "$O_TYPE" != 'None' ]; then
        echo -e "\n==== Installing $O_TYPE===="
    fi;
    if [ "$O_TYPE" == 'Odoo 18 Community from odoo.com 远程社区版' ]; then
        sudo wget $O_COMMUNITY_LATEST_16 -O odoo_18.0.latest_all.deb
        sudo gdebi --n `basename $O_COMMUNITY_LATEST`
    fi;
    if [ "$O_TYPE" == 'Odoo 18 Community from local[odoo_18.0.latest_all.deb] 本地社区版' ]; then
        sudo dpkg -i $CURDIR/odoo_18.0.latest_all.deb;sudo apt-get -f -y install
    fi;
    if [ "$O_TYPE" == 'Odoo 18 Enterprise from local[odoo_18.0+e.latest_all.deb] 本地企业版' ]; then
        sudo dpkg -i $CURDIR/odoo_18.0+e.latest_all.deb;sudo apt-get -f -y install
#        sudo dpkg -i odoo_18.0+e.latest_all.deb;sudo apt-get -f -y install
    fi;

    if [ "$O_TYPE" != 'None' ]; then
        # 下载个性化配置文件，将odoo用户加至管理组（方便，如有更高安全要求可另行处理）
        sudo wget -x -q $O_CONF_FILE -O /etc/odoo/odoo.conf
    #    sudo wget -x -q https://www.odooai.cn/download/odoo.conf -O /etc/odoo/odoo.conf
        sudo usermod -a -G root odoo
        # 处理附加模块, npm
        sudo apt-get install npm -y
        sudo npm -g install npm
        sudo npm install npm@latest -g
        sudo npm install -g n
        sudo n latest
        sudo n stable
        sudo n lts
        sudo npm install -g postcss
        sudo npm install -g rtlcss
        # 设置个性化目录
        sudo mkdir /usr/lib/python3/dist-packages/odoo/odoofile
        sudo mkdir /usr/lib/python3/dist-packages/odoo/odoofile/addons
        sudo mkdir /usr/lib/python3/dist-packages/odoo/odoofile/filestore
        sudo mkdir /usr/lib/python3/dist-packages/odoo/odoofile/sessions
        sudo mkdir /usr/lib/python3/dist-packages/odoo/myaddons
        sudo mkdir /usr/lib/python3/dist-packages/odoo/mytheme
        sudo mkdir /usr/lib/python3/dist-packages/odoo/backups
        sudo chown -R odoo:odoo /var/log/odoo
        sudo chown -R odoo:odoo /usr/lib/python3/dist-packages/odoo/odoofile/
        sudo chown -R odoo:odoo /usr/lib/python3/dist-packages/odoo/backups/
        sudo chmod -R 755 /usr/lib/python3/dist-packages/odoo/odoofile
        sudo chmod -R 755 /usr/lib/python3/dist-packages/odoo/odoofile/filestore
        sudo chmod -R 755 /usr/lib/python3/dist-packages/odoo/odoofile/sessions
        sudo chmod -R 755 /usr/lib/python3/dist-packages/odoo/odoofile/addons
        sudo chmod -R 755 /usr/lib/python3/dist-packages/odoo/addons
        sudo chmod -R 755 /usr/lib/python3/dist-packages/odoo/myaddons
        sudo chmod -R 755 /usr/lib/python3/dist-packages/odoo/mytheme
        sudo chmod -R 755 /usr/lib/python3/dist-packages/odoo/backups
    fi;
}
#--------------------------------------------------
# 安装 Nginx 作为 web 转发，启用 polling
#--------------------------------------------------
function InstallNg()    {
    if [ "$O_NGINX" == 'Nginx for Odoo in port 80[Yes]' ]; then
        echo -e "\n---- Prepare Install $O_NGINX ----"
        sudo apt-get install nginx -y
        sudo wget -x -q $O_NGINX_CONF_FILE -O /etc/nginx/nginx.conf; sudo nginx -s reload
        echo -e "\n---- Nginx Done ----"
    fi;
}
#--------------------------------------------------
# 设置重启脚本，完成安装
#--------------------------------------------------
function InstallDone()    {
    sudo rm $CURDIR/r.sh
    sudo touch $CURDIR/r.sh
    sudo sh -c 'echo "#!/usr/bin/env bash" > $CURDIR/r.sh'
    sudo sh -c 'echo "sudo systemctl restart postgresql && sudo rm /var/log/odoo/*.log && sudo systemctl restart odoo" >> $CURDIR/r.sh'
    sudo sh -c 'echo "sudo systemctl status postgresql && sudo systemctl status odoo" >> $CURDIR/r.sh'
    sudo chmod +x r.sh

    echo -e "* $O_TYPE Install Done"
    echo "The Odoo server is up and running. Specifications:"
    echo "Port: $O_PORT"
    echo "User service: $O_USER"
    echo "User PostgreSQL: $O_USER"
    echo "Code location: /usr/lib/python3/dist-packages/odoo"
    echo "Restart Odoo service: sudo service $O_CONFIG restart"
    echo "Or: sudo bash /root/r.sh"
    echo "Please Reboot the server to make chinese setting effective."
    echo "Please visit our website to get more detail."
    echo "https://www.odooai.cn"
    echo "-----------------------------------------------------------"
}

#--------------------------------------------------
# 执行安装
#--------------------------------------------------
ConfirmOdoo;
ConfirmPg;
ConfirmNg;
InstallBase;
InstallPg;
InstallOdoo;
InstallNg;
InstallDone;
#SetPassword;
