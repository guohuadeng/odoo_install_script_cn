#!/usr/bin/env bash
sudo systemctl restart postgresql.service && sudo rm /var/log/odoo/* && sudo systemctl restart odoo