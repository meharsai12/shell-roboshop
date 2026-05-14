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
  echo  -e " You don't have root access ,  $R Please run the script with root access $N " | tee -a $LOG_FILE
  exit 1
 else

  echo -e " You have root access $G you can perform actions $N"  | tee -a $LOG_FILE

  fi

# instaed of validating  eeach time it takes exit status of previous command  as input and validated each time where we require it and use it
VALIDATE(){
    if [ $1 -eq 0 ]
    then 
    echo  -e "$2  is :: ... $G  success  $N"   | tee -a $LOG_FILE
    else
    echo -e  "$2 .. ::  $R is failure  $N  "  | tee -a $LOG_FILE
    exit 1

    fi
}

dnf module disable nodejs -y     &>>$LOG_FILE
VALIDATE $? "disabling default nodejs"

dnf module enable nodejs:20 -y   &>>$LOG_FILE
VALIDATE $? "enabling nodejs-20"

dnf install nodejs -y   &>>$LOG_FILE
VALIDATE $? "installing nodejs"

id roboshop
if [ $? -ne 0 ]
then
 useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>$LOG_FILE
 VALIDATE $? "Roboshop system user creation"
else
  echo -e  "The  user is already existed ..  $G SKIPPING $N  "
fi

mkdir -p  /app  
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE
VALIDATE $? "downloading the catalogue zip file to temp folder"

rm -rf /app/*     &>>$LOG_FILE
cd /app      &>>$LOG_FILE
VALIDATE $? "Navigating to app folder"
 
unzip /tmp/catalogue.zip  &>>$LOG_FILE
VALIDATE $? "Unzipping the catalogue zip file here"

npm install   &>>$LOG_FILE
VALIDATE $? "installing dependencies"


cp $SCRIPT_DIR/catalogue.service  /etc/systemd/system/catalogue.service  &>>$LOG_FILE
VALIDATE $? "copying catalogueservice"

systemctl daemon-reload   &>>$LOG_FILE
VALIDATE $? "catalogue daemon-reload"

systemctl enable catalogue   &>>$LOG_FILE
VALIDATE $? " enabling catalogue service"

systemctl start catalogue  &>>$LOG_FILE
VALIDATE $? "starting catalogue service"


cp  $SCRIPT_DIR/mongodb.repo /etc/yum.repos.d/mongo.repo  &>>$LOG_FILE
VALIDATE $? "copying mongodb repo "


dnf install mongodb-mongosh -y  &>>$LOG_FILE
VALIDATE $? "installing mongodb client"

STATUS=$(mongosh --host mongodb.daws84s.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.daws84s.site </app/db/master-data.js  &>>$LOG_FILE
    VALIDATE $? "Loading data into MongoDB" 
else
    echo -e "Data is already loaded ... $Y SKIPPING $N"
fi

END_TIME=$(date +%s)

TOTAL_TIME=$(($START_TIME - $END_TIME))

echo -e "Total time taken to execute the script is $R $TOTAL_TIME seconds $N "

