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

echo "Please enter root password to setup"
read -s MYSQL_ROOT_PASSWORD

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

dnf install maven -y
VALIDATE $? "installing  maven"


id roboshop
if [ id -ne 0 ]
then 
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Roboshop user creation "
else
    echo -e "Roboshop user i salready existed no need to create .. $G SKIPPING..$N"
fi



mkdir -p  /app 
VALIDATE $? "creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
VALIDATE $? "downloading shippingg service"


cd /app
rm -rf /app/* 
unzip /tmp/shipping.zip
VALIDATE $? "unzipping shipping service code"

mvn clean package 
VALIDATE $? "cleaning package"

mv target/shipping-1.0.jar shipping.jar
VALIDATE $? "Renaming jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying shipping systemctl file"

systemctl daemon-reload
VALIDATE $? "daemon reload"

systemctl enable shipping 
systemctl start shipping
VALIDATE $? "Enabling and starting the shipping"

dnf install mysql -y 
VALIDATE $? "installing mysql"

mysql -h mysql.daws84s.site -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.daws84s.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.daws84s.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h mysql.daws84s.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi


