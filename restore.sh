#!/bin/bash

source config.sh



touch ${config["log"]}
exec &> ${config["log"]}

ATTACHMENT_PATH=${config["logpath"]}/${config["log"]}
GITLAB_BACKUP_DIRECTORY=${config[gitlab_backup_directory]}
MYSQL_BACKUP_DIRECTORY=${config[mysql_backup_directory]}
MAX_FILES=${config["max_files"]}
SUBSTRING='_gitlab_backup.tar'
DATE_WITH_TIME=`date "+%Y-%m-%d %H:%M:%S"`

#go to root
cd /

#go to mysqlbackup directory
cd $MYSQL_BACKUP_DIRECTORY

#find the latest file that as the words gitlab_backup
${LATEST_FILE=default}
LAST_FILE_MOD=''
READABLE=''

for sql in "$MYSQL_BACKUP_DIRECTORY"/*
do
if [ -f "$sql" ] && [[ "$sql" = *"$SUBSTRING"* ]]; 
then
stat_cmd=$(which stat)
type=$($stat_cmd --format="%F" $sql)
mod_time=$($stat_cmd --format="%Y" $sql)
t=$($stat_cmd --format="%y" $sql)
name=$(basename $sql)

  printf "$sql : $mod_time $t\n"

#get eligible file with greatest date
if ((mod_time > LAST_FILE_MOD)) || [ -z "$LAST_FILE_MOD" ];
then
LAST_FILE_MOD="$mod_time"
LATEST_FILE="$name"
READABLE="$t"
printf "LESS TIME $LAST_FILE_MOD $LATEST_FILE $READABLE" 
else

printf "GREATER $sql $t"
fi
  

else
printf "not eligible file: $sql\n"
fi
done


printf "Read by gitlab"
printf "To be exported$LAST_FILE_MOD $LATEST_FILE $READABLE\n"

if  [ ! -z "$LATEST_FILE" ];
then
#mv the file to the gitlab backup directory
cp $LATEST_FILE $GITLAB_BACKUP_DIRECTORY

#strip gitlab backup and run restore
# main string
str="$LATEST_FILE"
 
# delimiter string
delimiter="$SUBSTRING"
 
#length of main string
strLen=${#str}
#length of delimiter string
dLen=${#delimiter}
 
#iterator for length of string
i=0
#length tracker for ongoing substring
wordLen=0
#starting position for ongoing substring
strP=0
 
array=()
while [ $i -lt $strLen ]; do
    if [ $delimiter == ${str:$i:$dLen} ]; then
        array+=(${str:strP:$wordLen})
        strP=$(( i + dLen ))
        wordLen=0
        i=$(( i + dLen ))
    fi
    i=$(( i + 1 ))
    wordLen=$(( wordLen + 1 ))
done
array+=(${str:strP:$wordLen})
 
declare -p array

printf array
LATEST_FILE_NAME=${array[0]}
printf "latest file name $LATEST_FILE_NAME"

printf "run restore at this time"
else
printf "File not available"
fi

if  [ ! -z "$LATEST_FILE_NAME" ];
then
chown -R git:git $GITLAB_BACKUP_DIRECTORY
cd $GITLAB_BACKUP_DIRECTORY
chmod 600 $LATEST_FILE 
printf "\nUSE GITLAB HERE: "$LATEST_FILE_NAME
echo "yes" | gitlab-rake gitlab:backup:restore BACKUP=$LATEST_FILE_NAME
printf "\n************************SCRIPT COMPLETE**********************************\n"
else
printf "no file to backup"
fi


#send email to admin
EMAIL_SUBJECT="${config["email_subject"]} $DATE_WITH_TIME"
EMAIL_BODY="Restoration of backup file $LATEST_FILE Complete"
ADMIN_EMAIL=${config["admin_email"]}

echo "$EMAIL_BODY" | mail -a "$ATTACHMENT_PATH" -s "$EMAIL_SUBJECT" "$ADMIN_EMAIL"

echo "email sent"
rm "$ATTACHMENT_PATH"

exit
