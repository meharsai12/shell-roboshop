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

 echo "Script started  Executing at time ::  $(date)" | tee -a $LOG_FILE


 if [ $USERID -ne 0 ]
 then 
  echo  -e " You don't have root access ,  $R Please run the script with root access $N "  | tee -a $LOG_FILE
  exit 1
 else

  echo -e " You have root access $G you can perform actions $N"  | tee -a $LOG_FILE

  fi

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

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


dnf install mysql-server -y  &>>$LOG_FILE
VALIDATE $? "installing the mysql server"

systemctl enable mysqld  &>>$LOG_FILE
systemctl start mysqld  
VALIDATE $? "enabling and starting the mysql server"

mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD   &>>$LOG_FILE
VALIDATE $? "Setting MySQL root password"