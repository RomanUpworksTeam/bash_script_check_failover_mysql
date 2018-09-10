#!/bin/bash
DATE=`date '+%Y-%m-%d %H:%M:%S'`
old_status1=`cat ./status1`
old_status2=`cat ./status2`
old_status3=`cat ./status3`
node1=(178.162.203.108)
node2=(178.162.207.221)
node3=(178.162.207.220)
status1=0
status2=0
status3=0
master=0
MYSQL_PWD="root"
#echo "CHECK IN TIME $DATE" >> /var/log/mysql_select_master.log
stat_node1=`mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e "SHOW SLAVE STATUS\G" | grep "Slave_SQL_Running:" | awk '{ print $2 }' ` 2>/dev/null
stat_node2=`mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e "SHOW SLAVE STATUS\G" | grep "Slave_SQL_Running:" | awk '{ print $2 }' ` 2>/dev/null
stat_node3=`mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e "SHOW SLAVE STATUS\G" | grep "Slave_SQL_Running:" | awk '{ print $2 }' ` 2>/dev/null
echo "#######################################################################" >> /var/log/mysql_select_master.log
echo "#**********************CHECK MYSQL REPLICATION STATUS*****************#" >> /var/log/mysql_select_master.log
echo "#*****************************AUTOR IRAJ NOROUZI**********************#" >> /var/log/mysql_select_master.log
echo "#********************CHECK IN TIME $DATE****************#" >> /var/log/mysql_select_master.log
echo "#######################################################################" >> /var/log/mysql_select_master.log

mysqladmin ping -h$node1 -P3306 -uroot -p$MYSQL_PWD 2>/dev/null
if [ $? -eq 0 ];then
status1=1
echo "Check Mysql Servis on $node1 Status Is UP" >> /var/log/mysql_select_master.log
else
echo "Check Mysql Servis on $node1 Status Is Down" >> /var/log/mysql_select_master.log
stat_node1=Down
fi

mysqladmin ping -h$node2 -P3306 -uroot -p$MYSQL_PWD 2>/dev/null
if [ $? -eq 0 ];then
status2=1;
echo "Check Mysql Servis on $node2 Status Is UP" >> /var/log/mysql_select_master.log
else
echo "Check Mysql Servis on $node2 Status Is Down" >> /var/log/mysql_select_master.log
stat_node2=Down
fi

mysqladmin ping -h$node3 -P3306 -uroot -p$MYSQL_PWD 2>/dev/null
if [ $? -eq 0 ];
then
status3=1;
echo "Check Mysql Servis on $node3 Status Is UP" >> /var/log/mysql_select_master.log
else
echo "Check Mysql Servis on $node3 Status Is Down" >> /var/log/mysql_select_master.log
stat_node3=Down

fi

if [ "$stat_node1" == "" ];
then
stat_node1="No is Master"
fi
if [ "$stat_node2" == "" ];
then
stat_node2="No is Master"
fi
if [ "$stat_node3" == "" ];
then
stat_node3="No is Master"
fi




if [ "$old_status1" == "$status1" ] && [ "$old_status2" == "$status2" ] && [ "$old_status3" == "$status3" ];
then
#echo "No CHANGES ON SERVERS ... $node1 = $status1 - $node2 = $status2 - $node3 = $status3" >> /var/log/mysql_select_master.log
echo "STABLE STATUS  ... $node1 is slave  = $stat_node1 - $node2 is slave = $stat_node2 - $node3 is slave  = $stat_node3" >> /var/log/mysql_select_master.log
exit 0
fi

echo "START : (STOP SLAVE) (RESET MASTER)(RESET SLAVE ALL) execute on each server ... " >> /var/log/mysql_select_master.log
mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"stop slave;" 2>/dev/null
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"stop slave;" 2>/dev/null
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"stop slave;" 2>/dev/null

mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"RESET MASTER;" 2>/dev/null
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"RESET MASTER;" 2>/dev/null
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"RESET MASTER;" 2>/dev/null

mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"RESET SLAVE ALL;" 2>/dev/null
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"RESET SLAVE ALL;" 2>/dev/null
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"RESET SLAVE ALL;" 2>/dev/null

echo "END : (STOP SLAVE) (RESET MASTER)(RESET SLAVE ALL) execute on each server ... " >> /var/log/mysql_select_master.log
echo "STOP PORT FORWARDING  ... " >> /var/log/mysql_select_master.log
pidnode1=`ps aux | grep -v grep | grep "ssh -f -L 3306:$node1:3306 root@$node1 -N" | awk '{print $2}'`
kill -9 $pidnode1 2>/dev/null

pidnode2=`ps aux | grep -v grep | grep "ssh -f -L 3306:$node2:3306 root@$node2 -N" | awk '{print $2}'`
kill -9 $pidnode2 2>/dev/null

pidnode3=`ps aux | grep -v grep | grep "ssh -f -L 3306:$node3:3306 root@$node3 -N" | awk '{print $2}'`
kill -9 $pidnode3 2>/dev/null


if [ $status1 -eq 1 ] && [ $status2 -eq 1 ] && [ $status3 -eq 1 ];
then

mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"SET GLOBAL READ_ONLY=0;" 2>/dev/null
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"CHANGE MASTER TO MASTER_HOST='cephmon01',MASTER_USER='root',MASTER_PASSWORD='$MYSQL_PWD',MASTER_AUTO_POSITION = 1;" > /dev/null 2>/dev/null
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE; SET GLOBAL READ_ONLY=1;" > /dev/null 2>/dev/null
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"CHANGE MASTER TO MASTER_HOST='cephmon01',MASTER_USER='root',MASTER_PASSWORD='$MYSQL_PWD',MASTER_AUTO_POSITION = 1;" > /dev/null 2>/dev/null
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE; SET GLOBAL READ_ONLY=1;" > /dev/null 2>/dev/null

mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%' identified by 'monitor';" > /dev/null 2>/dev/null
msql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" 2>/dev/null

master=1
ssh -f -L 3306:$node1:3306 root@$node1 -N 2>/dev/null

fi

if [ $status1 -eq 1 ]  && [ $status2 -eq 1 ] && [ $status3 -eq 0 ];
then
mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"SET GLOBAL READ_ONLY=0;" 2>/dev/null
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"CHANGE MASTER TO MASTER_HOST='cephmon01',MASTER_USER='root',MASTER_PASSWORD='$MYSQL_PWD',MASTER_AUTO_POSITION = 1;" 2>/dev/null
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE; SET GLOBAL READ_ONLY=1;" > /dev/null 2>&1

mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%' identified by 'monitor';" > /dev/null 2>&1
mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" > /dev/null 2>&1

master=1
ssh -f -L 3306:$node1:3306 root@$node1 -N
fi

if [ $status1 -eq 1 ] && [ $status2 -eq 0 ] && [ $status3 -eq 1 ];
then
mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"SET GLOBAL READ_ONLY=0;" 2>/dev/null
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"CHANGE MASTER TO MASTER_HOST='cephmon01',MASTER_USER='root',MASTER_PASSWORD='$MYSQL_PWD',MASTER_AUTO_POSITION = 1;" 2>/dev/null
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE; SET GLOBAL READ_ONLY=1;" > /dev/null 2>&1

mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%' identified by 'monitor';" > /dev/null 2>&1
mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" > /dev/null 2>&1

master=1
ssh -f -L 3306:$node1:3306 root@$node1 -N
fi

if [ $status1 -eq 0 ] && [ $status2 -eq 1 ] && [ $status3 -eq 1 ];
then
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"SET GLOBAL READ_ONLY=0;" 2>/dev/null
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"CHANGE MASTER TO MASTER_HOST='cephmon02',MASTER_USER='root',MASTER_PASSWORD='$MYSQL_PWD',MASTER_AUTO_POSITION = 1;" 2>/dev/null

mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE; SET GLOBAL READ_ONLY=1;" > /dev/null 2>&1

mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%' identified by 'monitor';" > /dev/null 2>&1
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" > /dev/null 2>&1

master=2
ssh -f -L 3306:$node2:3306 root@$node2 -N 2>/dev/null
fi

if [ $status1 -eq 0 ] && [ $status2 -eq 1 ] && [ $status3 -eq 0 ];
then
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"SET GLOBAL READ_ONLY=0;"

mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%' identified by 'monitor';" > /dev/null 2>&1
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" > /dev/null 2>&1

master=2
ssh -f -L 3306:$node2:3306 root@$node2 -N 2>/dev/null
fi

if [ $status1 -eq 0 ] && [ $status2 -eq 0 ] && [ $status3 -eq 1 ];
then
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"SET GLOBAL READ_ONLY=0;" 2>/dev/null

mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"GRANT usage,replication client on *.* to monitor@'%' identified by 'monitor';" > /dev/null 2>&1
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"CREATE DATABASE sysbench" > /dev/null 2>&1

master=3
ssh -f -L 3306:$node3:3306 root@$node3 -N 2>/dev/null
fi

if [ $status1 -eq 0 ] && [ $status2 -eq 0 ] && [ $status3 -eq 0 ];
then
echo "Send sms three server is down" >> /var/log/mysql_select_master.log
fi

mysql -h$node1 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE;" 2>/dev/null
mysql -h$node2 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE;" 2>/dev/null
mysql -h$node3 -P3306 -uroot -p$MYSQL_PWD -e"START SLAVE;" 2>/dev/null



echo $status1 > ./status1
echo $status2 > ./status2
echo $status3 > ./status3
