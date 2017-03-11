#!/bin/sh
for ((i=0; i<31; ++i))
do
	#scp /usr/local/hadoop-2.7.1/etc/hadoop/hadoop-metrics2.properties hadoop@192.168.1.$i:/usr/local/hadoop-2.7.1/etc/hadoop/
	./ganglia-pwd.exp $i
done
