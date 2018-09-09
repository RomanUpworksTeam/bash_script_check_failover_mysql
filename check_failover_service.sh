#!/bin/bash
while(true)
do
/bin/bash ./mysql_select_master.sh 1>&2
sleep 10;
done
