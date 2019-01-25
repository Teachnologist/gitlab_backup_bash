#!/bin/bash

typeset -A config
config[gitlab_backup_directory]="/var/opt/gitlab/backups/"
config[mysql_backup_directory]="/your/destination/directory"


config["log"]=`date +"%s"`_log.txt
config["logpath"]="/var/gitlab_backup"

config["max_files"]=10

config["admin_email"]="myemail@emails.com"
config["email_subject"]="Gitlab Backup"
config["email_body"]="Backup log text attached to this email"
