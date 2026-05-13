USERID=$(id -u)

R="\e[31m"  #red colour
G="\e[32m"  #green colour
Y="\e[33m"  #yellow colour
N="\e[0m"   #no colour

LOGS_FOLDER="/var/logs/roshop-logs"
SCRIPT_NAME=$(echo $0  | cut -d "." -f1 ) 
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER 

echo -e "Script executed at .. ::  $G $(date) $N"


if [ USERID -ne 0 ]
then 
echo -e " $R You don't root access to perform  $N"
exit 1
else
echo -e " $G You have rooot access to perform actions $N"
fi


VALIDATE(){
    if [ $1 -eq  0 ]
    then 
    echo -e " $2 is .....  $Y success $N "
    else
    echo -e " $2 is .....  $Y Failure $N "
    fi
}

dnf module disable redis -y
VALIDATE $? "Diable default redis "

dnf module enable redis:7 -y
VALIDATE $? "enabling redis:7 version"

dnf install redis -y 
VALIDATE $? "installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
VALIDATE $? "Edited redis.conf to accept remote connections"

systemctl enable redis 
VALIDATE $? "enabling redis"

systemctl start redis 
VALIDATE $? "Starting redis"

