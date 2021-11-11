#!/usr/bin/env bash
sudo systemctl restart postgresql && sudo rm /var/log/odoo/*
sudo systemctl stop odoo
sudo systemctl start odoo
sudo systemctl status postgresql && sudo systemctl status odoo