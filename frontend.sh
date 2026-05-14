#!/bin/bash

USERID=$(id -u)

R="\e[31m"  #red colour
G="\e[32m"  #green colour
Y="\e[33m"  #yellow colour
N="\e[0m"   #no colour

LOGS_FOLDER="/var/logs/roshop-logs"
SCRIPT_NAME=$(echo $0  | cut -d "." -f1 ) 
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
START_TIME=$(date +%s)

mkdir -p $LOGS_FOLDER    # if we add -p if we run n times ifd folder ewxistis no creation if not it will create 

 echo "Script started  Executing at time ::  $(date)"   | tee -a $LOG_FILE


 if [ $USERID -ne 0 ]
 then 
  echo  -e " You don't have root access ,  $R Please run the script with root access $N "   | tee -a $LOG_FILE
  exit 1
 else

  echo -e " You have root access $G you can perform actions $N"   | tee -a $LOG_FILE

  fi

# instaed of validating  eeach time it takes exit status of previous command  as input and validated each time where we require it and use it
VALIDATE(){
    if [ $1 -eq 0 ]
    then 
    echo  -e "$2  is :: ... $G  success  $N"   | tee -a $LOG_FILE
    else
    echo -e  "$2 .. ::  $R is failure  $N  "   | tee -a $LOG_FILE
    exit 1

    fi
}



dnf module list nginx   &>>$LOG_FILE
VALIDATE $? "nginx available list"

dnf module disable nginx -y   &>>$LOG_FILE
VALIDATE $? "diabling default nginx"

dnf module enable nginx:1.24 -y      &>>$LOG_FILE
VALIDATE $? "enabling nginx 1.24"

dnf install nginx -y     &>>$LOG_FILE
VALIDATE $? "installing  nginx 1.24"

systemctl enable nginx   &>>$LOG_FILE
VALIDATE $? "enabling nginx"

systemctl start nginx    &>>$LOG_FILE
VALIDATE $? "starting nginx"

rm -rf /usr/share/nginx/html/*   &>>$LOG_FILE
VALIDATE $? "removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip    &>>$LOG_FILE
VALIDATE $? "downloading frontend zip file in tmp folder"

cd /usr/share/nginx/html     &>>$LOG_FILE
VALIDATE $? "navigating to nginx defaulyt htmll file"

unzip /tmp/frontend.zip  &>>$LOG_FILE
VALIDATE $? "unzipping frontmd file in default nginx html file"

rm -rf /etc/nginx/nginx.conf  &>>$LOG_FILE
VALIDATE $? "Remove default nginx conf"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf  &>>$LOG_FILE
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx  &>>$LOG_FILE
VALIDATE $? "Restarting nginx"