#!/bin/bash

old_status1=`cat ./status1`
old_status2=`cat ./status2`
old_status3=`cat ./status3`

#echo $old_status1
#echo $old_status2
#echo $old_status3
node1=(178.162.203.108)
node2=(178.162.207.221)
node3=(178.162.207.220)

MYSQL_PWD="root"
status1=0
status2=0
status3=0
master=0


mysqladmin ping -h$node1 -P3306 -uroot -p$MYSQL_PWD 2>/dev/null
if [ $? -eq 0 ];then
status1=1
fi

mysqladmin ping -h$node2 -P3306 -uroot -p$MYSQL_PWD 2>/dev/null
if [ $? -eq 0 ];then
status2=1;
fi

mysqladmin ping -h$node3 -P3306 -uroot -p$MYSQL_PWD 2>/dev/null
if [ $? -eq 0 ];
then
status3=1;
fi

if [ "$old_status1" == "$status1" ] && [ "$old_status2" == "$status2" ] && [ "$old_status3" == "$status3" ];
then
echo "No CHANGE ..."
exit 0
fi


mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"stop slave;" 1>&2
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"stop slave;" 1>&2
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"stop slave;" 1>&2

mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"RESET SLAVE ALL;" 1>&2
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"RESET SLAVE ALL;" 1>&2
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"RESET SLAVE ALL;" 1>&2


pidnode1=`ps aux | grep -v grep | grep "ssh -f -L 3306:$node1:3306 root@$node1 -N" | awk '{print $2}'`
kill -9 $pidnode1

pidnode1=`ps aux | grep -v grep | grep "ssh -f -L 3306:$node2:3306 root@$node2 -N" | awk '{print $2}'`
kill -9 $pidnode3

pidnode1=`ps aux | grep -v grep | grep "ssh -f -L 3306:$node3:3306 root@$node3 -N" | awk '{print $2}'`
kill -9 $pidnode3
echo "test"

if [ $status1 -eq 1 ] && [ $status2 -eq 1 ] && [ $status3 -eq 1 ];
then

mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"SET GLOBAL READ_ONLY=0;"
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"CHANGE MASTER TO MASTER_HOST='cephmon01',MASTER_USER='root',MASTER_PASSWORD='$MYSQL_PWD',MASTER_AUTO_POSITION = 1;" > /dev/null 2>&1
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE; SET GLOBAL READ_ONLY=1;" > /dev/null 2>&1
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"CHANGE MASTER TO MASTER_HOST='cephmon01',MASTER_USER='root',MASTER_PASSWORD='$MYSQL_PWD',MASTER_AUTO_POSITION = 1;" > /dev/null 2>&1
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE; SET GLOBAL READ_ONLY=1;" > /dev/null 2>&1

mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%' identified by 'monitor';" > /dev/null 2>&1
msql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" > /dev/null 2>&1

master=1
ssh -f -L 3306:$node1:3306 root@$node1 -N

echo "test"
fi

if [ $status1 -eq 1 ]  && [ $status2 -eq 1 ] && [ $status3 -eq 0 ];
then
mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"SET GLOBAL READ_ONLY=0;"
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"CHANGE MASTER TO MASTER_HOST='cephmon01',MASTER_USER='root',MASTER_PASSWORD='$MYSQL_PWD',MASTER_AUTO_POSITION = 1;" >$
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE; SET GLOBAL READ_ONLY=1;" > /dev/null 2>&1

mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%' identified by 'monitor';" > /dev/null 2>&1
mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" > /dev/null 2>&1

master=1
ssh -f -L 3306:$node1:3306 root@$node1 -N
fi

if [ $status1 -eq 1 ] && [ $status2 -eq 0 ] && [ $status3 -eq 1 ];
then
mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"SET GLOBAL READ_ONLY=0;"
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"CHANGE MASTER TO MASTER_HOST='cephmon01',MASTER_USER='root',MASTER_PASSWORD='$MYSQL_PWD',MASTER_AUTO_POSITION = 1;" >$
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE; SET GLOBAL READ_ONLY=1;" > /dev/null 2>&1

mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%' identified by 'monitor';" > /dev/null 2>&1
mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" > /dev/null 2>&1

master=1
ssh -f -L 3306:$node1:3306 root@$node1 -N
fi

if [ $status1 -eq 0 ] && [ $status2 -eq 1 ] && [ $status3 -eq 1 ];
then
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"SET GLOBAL READ_ONLY=0;"
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"CHANGE MASTER TO MASTER_HOST='cephmon02',MASTER_USER='root',MASTER_PASSWORD='$MYSQL_PWD',MASTER_AUTO_POSITION = 1;" >$

mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE; SET GLOBAL READ_ONLY=1;" > /dev/null 2>&1

mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%' identified by 'monitor';" > /dev/null 2>&1
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" > /dev/null 2>&1

master=2
ssh -f -L 3306:$node2:3306 root@$node2 -N
fi

if [ $status1 -eq 0 ] && [ $status2 -eq 1 ] && [ $status3 -eq 0 ];
then
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"SET GLOBAL READ_ONLY=0;"

mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%' identified by 'monitor';" > /dev/null 2>&1
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" > /dev/null 2>&1

master=2
ssh -f -L 3306:$node2:3306 root@$node2 -N
fi

if [ $status1 -eq 0 ] && [ $status2 -eq 0 ] && [ $status3 -eq 1 ];
then
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"SET GLOBAL READ_ONLY=0;"

mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%' identified by 'monitor';" > /dev/null 2>&1
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" > /dev/null 2>&1

master=3
ssh -f -L 3306:$node3:3306 root@$node3 -N
fi

if [ $status1 -eq 0 ] && [ $status2 -eq 0 ] && [ $status3 -eq 0 ];
then
echo "Send sms three server is down" >> /var/log/mysql_select_master.log
fi

echo $status1 > ./status1
echo $status2 > ./status2
echo $status3 > ./status3
