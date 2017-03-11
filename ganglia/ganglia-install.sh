#!/bin/sh
for ((i=1; i<31; ++i))  
do  
	scp ./ganglia-3.7.2-2.el7.x86_64.rpm hadoop@192.168.1.$i:/home/hadoop
	scp /etc/ganglia/gmond.conf hadoop@192.168.1.$i:/home/hadoop
	scp ./libconfuse-2.7-7.el7.x86_64.rpm hadoop@192.168.1.$i:/home/hadoop
	scp ./ganglia-gmond-3.7.2-2.el7.x86_64.rpm hadoop@192.168.1.$i:/home/hadoop
	./ganglia-pwd.exp $i
	echo "done with 192.168.1.$i"
done
