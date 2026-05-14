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

mkdir -p $LOGS_FOLDER 

echo -e "Script executed at .. ::  $G $(date) $N"  | tee -a $LOG_FILE| tee -a $LOG_FILE


if [ USERID -ne 0 ]
then 
echo -e " $R You don't root access to perform  $N"   | tee -a $LOG_FILE
exit 1
else
echo -e " $G You have rooot access to perform actions $N"  | tee -a $LOG_FILE
fi


VALIDATE(){
    if [ $1 -eq  0 ]
    then 
    echo -e " $2 is .....  $Y success $N "  | tee -a $LOG_FILE
    else
    echo -e " $2 is .....  $Y Failure $N "  | tee -a $LOG_FILE
    fi
}

dnf module disable redis -y  &>>$LOG_FILE
VALIDATE $? "Diable default redis "

dnf module enable redis:7 -y    &>>$LOG_FILE
VALIDATE $? "enabling redis:7 version"

dnf install redis -y    &>>$LOG_FILE
VALIDATE $? "installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf   &>>$LOG_FILE
VALIDATE $? "Edited redis.conf to accept remote connections"

systemctl enable redis  &>>$LOG_FILE
VALIDATE $? "enabling redis"

systemctl start redis   &>>$LOG_FILE
VALIDATE $? "Starting redis"

END_TIME=$(date +%s)

TOTAL_TIME=$(($START_TIME - $END_TIME))

echo -e "Total time taken to execute the script is $R $TOTAL_TIME seconds $N "