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
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y
VALIDATE $? "enabling nodejs.20"

dnf install nodejs -y
VALIDATE $? "installing nodejs"

id roboshop
if [ id -ne 0 ]
then
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
  VALIDATE $? "Roboshop user creation "
else
 echo -e "Teh id is alredy there no need to create ...$G SKIPPING ..$N"
 fi


 mkdir -p  /app
 VALIDATE $? "Creating app directory"


curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
VALIDATE $? "downloading zip file of user component "


rm -rf /app/*
cd /app 
unzip /tmp/user.zip
 VALIDATE $? "unzipping user component"


 
npm install 
VALIDATE $? "downloading dependencies"


cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "copying user service file"

systemctl daemon-reload
VALIDATE $? "daemon reload"

systemctl enable user 
systemctl start user
VALIDATE $? "enabling and starting the user "

END_TIME=$(date +%s)

TOTAL_TIME=$(($START_TIME - $END_TIME))

echo -e "Total time taken to execute the script is $R $TOTAL_TIME seconds $N "



