# [Odoo](https://www.odoo.com "Odoo's Homepage") Install Script

This script is based on the install script from
** André Schenkels (https://github.com/aschenkels-ictstudio/openerp-install-scripts)
** Yenthe666 https://github.com/Yenthe666/InstallScript

# 使用方法，直接在主机上执行以下指令
```
wget https://sunpop.cn/download/odoo_install.sh && bash odoo_install.sh 2>&1 | tee odoo.log
```

#-------------------------------------------------------------------------------
# 本脚本执行完成后，您将得到
#-------------------------------------------------------------------------------
# 1. 中文字体，PDF报表，时间同步，SCSS编译等odoo支持组件
# 2. postgres 10 安装在 /usr/lib/postgresql/10
# 3. postgres 10 配置在 /etc/postgresql/10/main
# 4. odoo 最新版 安装在 /usr/lib/python3/dist-packages/odoo
# 5. odoo 配置文件位于 /etc/odoo/odoo.conf
# 6. odoo访问地址为(用你的域名代替 yourserver.com) http://yourserver.com:8069
# 7. 一个 r.sh 文件用于重启 odoo 服务，使用root用户登录后键入bash r.sh 即可执行
# todo: 选择社区版 or 企业版，可前期初始化管理密码