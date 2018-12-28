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
# 6. Nginx 作为反向代理，开启了多worker工作模式，可使用odoo在线即时通讯
# 7. odoo访问地址为(用你的域名代替 yourserver.com) http://yourserver.com 或者http://yourserver.com:8069
# 8. 一个 r.sh 文件用于重启 odoo 服务，使用root用户登录后键入bash r.sh 即可执行
