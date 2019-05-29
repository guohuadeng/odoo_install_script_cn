#!/usr/bin/env bash
sudo systemctl stop postgresql && sudo rm /var/log/odoo/* && sudo systemctl stop odoo
sudo systemctl status postgresql && sudo systemctl status odoo