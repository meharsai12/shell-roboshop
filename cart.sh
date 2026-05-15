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

 echo "Script started  Executing at time ::  $(date)"  | tee -a $LOG_FILE


 if [ $USERID -ne 0 ]
 then 
  echo  -e " You don't have root access ,  $R Please run the script with root access $N "  | tee -a $LOG_FILE
  exit 1
 else

  echo -e " You have root access $G you can perform actions $N"  | tee -a $LOG_FILE

  fi

# instaed of validating  eeach time it takes exit status of previous command  as input and validated each time where we require it and use it
VALIDATE(){
    if [ $1 -eq 0 ]
    then 
    echo  -e "$2  is :: ... $G  success  $N"  | tee -a $LOG_FILE  
    else
    echo -e  "$2 .. ::  $R is failure  $N  "  | tee -a $LOG_FILE
    exit 1

    fi
}

dnf module disable nodejs -y  &>>$LOG_FILE
VALIDATE $? "diabling the default nodejs"

dnf module enable nodejs:20 -y  &>>$LOG_FILE 
VALIDATE $? "enabling nodejs:20 "

dnf install nodejs -y  &>>$LOG_FILE
VALIDATE $? "installing the nodejs"

id roboshop 
if [ $? -ne  0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>$LOG_FILE
    VALIDATe $? "Roboshop user crteation "
else
    echo -e "The user already existed so $G SKIPPING..$N"
fi

mkdir -p  /app &>>$LOG_FILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
VALIDATE $? "Unzipping cart component code"


cd /app 
rm -rf /app/*
unzip /tmp/cart.zip  &>>$LOG_FILE
VALIDATE $? "unzipping the cart component code"

npm install  &>>$LOG_FILE
VALIDATE $? "installing dependencies"

cp $SCRIPT_DIR/cart.service  /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "copying user component service "

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reload "


systemctl enable cart  &>>$LOG_FILE
systemctl start cart
VALIDATE $? "enabling and starting the cart service"


END_TIME=$(date +%s)

TOTAL_TIME=$(($START_TIME - $END_TIME))

echo -e "Total time taken to execute the script is $R $TOTAL_TIME seconds $N "