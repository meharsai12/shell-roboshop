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
  echo  -e " You don't have root access ,  $R Please run the script with root access $N " | tee -a $LOG_FILE
  exit 1
 else

  echo -e " You have root access $G you can perform actions $N" | tee -a $LOG_FILE

  fi

# echo "Please enter root password to setup"
# read -s MYSQL_ROOT_PASSWORD

# instaed of validating  eeach time it takes exit status of previous command  as input and validated each time where we require it and use it
VALIDATE(){
    if [ $1 -eq 0 ]
    then 
    echo  -e "$2  is :: ... $G  success  $N" | tee -a $LOG_FILE
    else
    echo -e  "$2 .. ::  $R is failure  $N  " | tee -a $LOG_FILE
    exit 1

    fi
}


dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "intslling python 3"



id roboshop
if [ id -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Roboshop user creation"
else
    echo -e "The roboshop user is already existed .. So $Y SKIPPING..$N "
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip
VALIDATE $? "downloading payment zip file "


rm -rf /app/*
cd /app 
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzipping payment file"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "installing pip 3 dependency"

cp $SCRIPT_DIR/payment.service  /etc/systemd/system/payment.service
VALIDATE $? "copying payment service "

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon-reload"

systemctl enable payment  &>>$LOG_FILE
systemctl start payment
VALIDATE $? "Enabling and starting the payment"

END_TIME=$(date +%s)

TOTAL_TIME=$(($START_TIME - $END_TIME))

echo -e "Total time taken to execute the script is $R $TOTAL_TIME seconds $N "
