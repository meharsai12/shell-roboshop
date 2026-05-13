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

mkdir -p $LOGS_FOLDER    # if we add -p if we run n times ifd folder ewxistis no creation if not it will create 

 echo "Script started  Executing at time ::  $(date)"


 if [ $USERID -ne 0 ]
 then 
  echo  -e " You don't have root access ,  $R Please run the script with root access $N "
  exit 1
 else

  echo -e " You have root access $G you can perform actions $N"

  fi

# instaed of validating  eeach time it takes exit status of previous command  as input and validated each time where we require it and use it
VALIDATE(){
    if [ $1 -eq 0 ]
    then 
    echo  -e "$2  is :: ... $G  success  $N"
    else
    echo -e  "$2 .. ::  $R is failure  $N  "
    exit 1

    fi
}

dnf module disable nodejs -y
VALIDATE $? "disabling default nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "enabling nodejs-20"

dnf install nodejs -y
VALIDATE $? "installing nodejs"

id roboshop
if [ $? -ne 0 ]
then
 useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
 VALIDATE $? "Roboshop system user creation"
else
  echo -e  "The  user is already existed ..  $G SKIPPING $N  "
fi

mkdir -p  /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "downloading the catalogue zip file to temp folder"

rm -rf /app/*
cd /app
VALIDATE $? "Navigating to app folder"

unzip /tmp/catalogue.zip
VALIDATE $? "Unzipping the catalogue zip file here"

npm install 
VALIDATE $? "installing dependencies"


cp $SCRIPT_DIR/catalogue.service  /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogueservice"

systemctl daemon-reload
VALIDATE $? "catalogue daemon-reload"

systemctl enable catalogue 
VALIDATE $? " enabling catalogue service"

systemctl start catalogue
VALIDATE $? "starting catalogue service"


cp  $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongodb repo "


dnf install mongodb-mongosh -y
VALIDATE $? "installing mongodb client"

STATUS=$(mongosh --host mongodb.daws84s.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.daws84s.site </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading data into MongoDB"
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi


