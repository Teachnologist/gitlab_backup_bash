#!/bin/bash

source config.sh



touch ${config["log"]}
exec &> ${config["log"]}

ATTACHMENT_PATH=${config["logpath"]}/${config["log"]}
GITLAB_BACKUP_DIRECTORY=${config[gitlab_backup_directory]}
MYSQL_BACKUP_DIRECTORY=${config[mysql_backup_directory]}
MAX_FILES=${config["max_files"]}
DATE_WITH_TIME=`date "+%Y-%m-%d %H:%M:%S"`

#run backup from gitlab
gitlab-rake gitlab:backup:create

#go to root
cd /

#go to gitlab backup directory
cd "$GITLAB_BACKUP_DIRECTORY"

#move appropriate files to the mysqldumps directory
for sql in "$GITLAB_BACKUP_DIRECTORY"/*
do
if [ -f "$sql" ]; then
echo -n "is a file $sql"
mv "$sql" "$MYSQL_BACKUP_DIRECTORY"
else
echo "not eligible file"
echo -n "*$sql"
fi
done

#go to root
cd /

#go to gitlab backup directory
cd "$MYSQL_BACKUP_DIRECTORY"

#parse directory
declare -A array
indexed=()

count=0

for file in "$MYSQL_BACKUP_DIRECTORY"/*
do


stat_cmd=$(which stat)

if [ -e "$file" ]; then
  type=$($stat_cmd --format="%A" $file | cut -c 1)


  echo -n $type
  mod_time=$($stat_cmd --format="%Y" $file)

array[${mod_time}]=${file}

indexed[$count]=${mod_time}
(( count++ ))
else
  echo "File does not exist"
fi


done

echo "Array sorted oldest 0 to youngest 1+ items and indexes:"

sorted=( $( printf "%s\n" "${indexed[@]}" | sort -n ) )

increment_index=$((${count}-1))
remainder_index=$((${increment_index}-$MAX_FILES))
echo "re index: ${remainder_index}"

#remove files be careful!
removed=0
for ((j=0;j<$remainder_index;j++)) do
key=${sorted[$j]}
echo ${j}" - "${array[${key}]}
echo "remove ${array[${key}]}"
rm ${array[${key}]}
(( removed++ ))
echo -n ""
done
echo "Total Files removed: ${removed} of ${increment_index}"

#send email to admin
EMAIL_SUBJECT="${config["email_subject"]} $DATE_WITH_TIME" 
EMAIL_BODY=${config["email_body"]}
ADMIN_EMAIL=${config["admin_email"]}

echo "$EMAIL_BODY" | mail -a "$ATTACHMENT_PATH" -s "$EMAIL_SUBJECT" "$ADMIN_EMAIL"

echo "email sent"
rm "$ATTACHMENT_PATH"
