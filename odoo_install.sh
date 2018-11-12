#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
clear;

CopyrightLogo='
==========================================================================
# 最近更新：2018-11-12
# 支持版本 Ubuntu 14.04, 15.04, 16.04 and 18.04
# 作者: Ivan Deng
# 支持: http://www.sunpop.cn
#-------------------------------------------------------------------------------
# 本脚本将安装Odoo到你的服务器上，一般而言，整个过程在3~5分钟完成
#-------------------------------------------------------------------------------
# 使用方法1，直接在主机上执行以下指令
# wget https://sunpop.cn/download/odoo_install.sh && bash odoo_install.sh 2>&1 | tee odoo.log
# 然后选择要安装的类型，1为从odoo官网安装，2为安装本地社区版，3为安装本地企业版，选择2和3时请确保已上传相关文件包至当前目录
#-------------------------------------------------------------------------------
# 本脚本执行完成后，您将得到
#-------------------------------------------------------------------------------
# 1. 中文字体，PDF报表，时间同步处理时区问题，SCSS编译等odoo支持组件
# 2. postgres 10 安装在 /usr/lib/postgresql/10
# 3. postgres 10 配置在 /etc/postgresql/10/main
# 4. odoo12 最新版 安装在 /usr/lib/python3/dist-packages/odoo
# 5. odoo12 配置文件位于 /etc/odoo/odoo.conf
# 6. odoo12 访问地址为(用你的域名代替 yourserver.com) http://yourserver.com:8069
# 7. 一个 r.sh 文件用于重启 odoo 服务，使用root用户登录后键入bash r.sh 即可执行
# todo: 选择社区版 or 企业版，可前期初始化管理密码
==========================================================================';
echo "$CopyrightLogo";
# remove old file
rm odoo_*

#--------------------------------------------------
# 变量定义
#--------------------------------------------------
O_USER="odoo"
O_HOME="/usr/lib/python3/dist-packages/odoo"
O_HOME_EXT="/$O_USER/${O_USER}-server"
# 安装 WKHTMLTOPDF，默认设置为 True ，如果已安装则设置为 False.
INSTALL_WKHTMLTOPDF="True"
# 中文字体相关
O_FONT="http://cdn.sunpop.cn/download/microsoft.zip"
# 默认 odoo 端口 8069，建议安装 nginx 做前端端口映射，这样才能使用 livechat
O_PORT="8069"
# 选择要安装的odoo版本，如: 12.0, 11.0, 10.0 或者 saas-18. 如果使用 'master' 则 master 分支将会安装
O_VERSION="12.0"
O_COMMUNITY_LATEST="http://nightly.odoocdn.com/12.0/nightly/deb/odoo_12.0.latest_all.deb"
# 如果要安装odoo企业版，则在此设置为 True
IS_ENTERPRISE="False"
# 设置超管的用户名及密码
O_SUPERADMIN="admin"
# 设置 odoo 配置文件名
O_CONFIG="${O_USER}"
# WKHTMLTOPDF 下载链接，将使用 sunpop.cn 的cdn下载以加快速度，注意主机版本及 WKHTMLTOPDF的版本
WKHTMLTOX_X64="http://cdn.sunpop.cn/download/wkhtmltox-0.12.1_linux-trusty-amd64.deb"
WKHTMLTOX_X32="http://cdn.sunpop.cn/download/wkhtmltox-0.12.1_linux-trusty-i386.deb"

#--------------------------------------------------
# 更新服务器，多数要人工干预，故可以注释
# 升级服务器到 ubuntu 18，不需要可以注释
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
function ConfirmInstall()
{
	echo -e "[Notice] Confirm Install - odoo 12 \nPlease select your odoo version: (1~4)"
	select selected in 'Odoo 12 Community from odoo.com' 'Odoo 12 Community from local[odoo_12.0.latest_all.deb]' 'Odoo 12 Enterprise from local[odoo_12.0+e.latest_all.deb]' 'Exit'; do break; done;
	[ "$selected" == 'Exit' ] && echo 'Exit Install.' && exit;
	[ "$selected" != '' ] &&  echo -e "[OK] You Selected: ${selected}\n" && O_TYPE=$selected && return 0;
	ConfirmInstall;
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
    echo -e "\n--- Installing Python 3 + pip3 --"
    sudo apt-get install python3 python3-pip -y

    echo -e "\n---- Install tool packages ----"
    sudo apt-get install wget git bzr python-pip gdebi-core -y

    echo -e "\n--- Install other required packages"
    sudo apt-get install node-clean-css -y
    sudo apt-get install node-less -y
    sudo apt-get install python-gevent -y

    #--------------------------------------------------
    # 安装 Wkhtmltopdf
    #--------------------------------------------------
    if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
      echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 12 ----"
      #pick up correct one from x64 & x32 versions:
      if [ "`getconf LONG_BIT`" == "64" ];then
          _url=$WKHTMLTOX_X64
      else
          _url=$WKHTMLTOX_X32
      fi
      sudo wget $_url
      sudo gdebi --n `basename $_url`
      sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
      sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
    else
      echo "Wkhtmltopdf isn't installed due to the choice of the user!"
    fi

    #--------------------------------------------------
    # 安装中文字体，装完后要重启
    #--------------------------------------------------
    sudo sh -c 'echo "LANG=\"zh_CN.UTF-8\"" > /etc/default/locale'
    apt install -y xfonts-utils
    apt install -y unzip
    sudo apt-get install -y ttf-wqy-* && sudo apt-get install ttf-wqy-zenhei && sudo apt-get install ttf-wqy-microhei && apt-get install -y language-pack-zh-hant language-pack-zh-hans
    sudo chmod 0755 /usr/share/fonts/truetype/wqy && sudo chmod 0755 /usr/share/fonts/truetype/wqy/*
    mkdir /usr/share/fonts/truetype/microsoft
    sudo wget $O_FONT -O /usr/share/fonts/truetype/microsoft/microsoft.zip
    unzip -q -d /usr/share/fonts/truetype/microsoft /usr/share/fonts/truetype/microsoft/microsoft.zip
    rm /usr/share/fonts/truetype/microsoft/microsoft.zip
    sudo chmod 0755 /usr/share/fonts/truetype/microsoft && sudo chmod 0755 /usr/share/fonts/truetype/microsoft/*
    cd /usr/share/fonts/truetype/wqy && mkfontscale && mkfontdir && fc-cache -fv
    cd /usr/share/fonts/truetype/microsoft && mkfontscale && mkfontdir && fc-cache -fv

    #--------------------------------------------------
    # cron 配置时间同步，必须要做，避免多数问题，最好停用本机ntpd服务器
    #--------------------------------------------------
    sudo apt-get install ntpdate -y
    sudo systemctl disable ntpd;sudo /etc/init.d/ntp stop;sudo /usr/sbin/ntpdate cn.pool.ntp.org
    sudo echo "0  */2  * * *   root    /usr/sbin/ntpdate cn.pool.ntp.org >> /tmp/tmp.txt" >> /etc/crontab
}
#--------------------------------------------------
# 安装 PostgreSQL Server 10.0
#--------------------------------------------------
function InstallPg()    {
    echo -e "\n---- Prepare Install PostgreSQL 10 Server ----"
    sudo apt-get install curl ca-certificates -y
    sudo apt-get install -y wget ca-certificates
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

    echo -e "\n---- Installing PostgreSQL 10 Server ----"
    sudo apt-key update
    sudo apt-get update
    sudo apt-get install postgresql-10 -y

    echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
    sudo su - postgres -c "createuser -s $O_USER" 2> /dev/null || true
}

#--------------------------------------------------
# 安装odoo
#--------------------------------------------------
function InstallOdoo()    {
    echo -e "\n==== Installing ODOO Server ===="
    if [ "$O_TYPE" == 'Odoo 12 Community from odoo.com [C Remote]' ]; then
        sudo wget $O_COMMUNITY_LATEST
        sudo gdebi --n `basename $O_COMMUNITY_LATEST`
    fi;
    if [ "$O_TYPE" == 'Odoo 12 Community from local[odoo_12.0.latest_all.deb]' ]; then
        sudo dpkg -i odoo_12.0.latest_all.deb;sudo apt-get -f -y install
    fi;
    if [ "$O_TYPE" == 'Odoo 12 Enterprise from local[odoo_12.0+e.latest_all.deb]' ]; then
        sudo dpkg -i odoo_12.0+e.latest_all.deb;sudo apt-get -f -y install
    fi;
}
#--------------------------------------------------
# 设置重启脚本，完成安装
#--------------------------------------------------
function InstallDone()    {
    sudo touch /root/r.sh
    sudo sh -c 'echo "#!/usr/bin/env bash" > /root/r.sh'
    sudo sh -c 'echo "sudo systemctl restart postgresql.service && sudo rm /var/log/odoo/*.log && sudo systemctl restart odoo" >> /root/r.sh'
    chmod +x r.sh

    echo -e "* Odoo 12 Server Install Done"
    echo "The Odoo server is up and running. Specifications:"
    echo "Port: $O_PORT"
    echo "User service: $O_USER"
    echo "User PostgreSQL: $O_USER"
    echo "Code location: /usr/lib/python3/dist-packages/odoo"
    echo "Restart Odoo service: sudo service $O_CONFIG restart"
    echo "Or: sudo bash /root/r.sh"
    echo "Please visit our website to get more detail."
    echo "http://www.sunpop.cn"
    echo "-----------------------------------------------------------"
}

#--------------------------------------------------
# 执行安装
#--------------------------------------------------
ConfirmInstall;
InstallBase;
InstallPg;
InstallOdoo;
InstallDone;
#SetPassword;
