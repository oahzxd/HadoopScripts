#!/bin/sh
if [ $# != 2 ]; then
    echo "useage: setting.sh 102 master[slave]"
    exit
fi

echo "
deb http://mirrors.163.com/debian/ jessie main non-free contrib
deb http://mirrors.163.com/debian/ jessie-updates main non-free contrib
deb http://mirrors.163.com/debian/ jessie-backports main non-free contrib
deb-src http://mirrors.163.com/debian/ jessie main non-free contrib
deb-src http://mirrors.163.com/debian/ jessie-updates main non-free contrib
deb-src http://mirrors.163.com/debian/ jessie-backports main non-free contrib
deb http://mirrors.163.com/debian-security/ jessie/updates main non-free contrib
deb-src http://mirrors.163.com/debian-security/ jessie/updates main non-free contrib
" > /etc/apt/sources.list

apt-get update


#
# 删除安装包
#
yes | sudo apt-get remove iptables 
yes | sudo apt-get remove network-manager
yes | sudo apt-get install openssh-server

#
# 建立用户组和用户
#
groupadd hadoop
useradd -g hadoop hadoop
echo 'hadoop:12345' | sudo chpasswd
mkdir /home/hadoop
mkdir /home/hadoop/.ssh/

if [ $2 = "master" ]; then
    echo -e "\n\n" | ssh-keygen -t rsa -f ./id_rsa
    mv ./id_rsa /home/hadoop/.ssh/
fi

cp ./id_rsa.pub /home/hadoop/.ssh/authorized_keys
chown -R hadoop:hadoop /home/hadoop 
chown -R hadoop:hadoop /home/hadoop/.ssh/
chown hadoop:hadoop /home/hadoop/.ssh/authorized_keys 
chmod 700 /home/hadoop/.ssh/
chmod 600 /home/hadoop/.ssh/authorized_keys

echo "=================="
echo "Setting user done!"
echo "=================="

#
#配置ip
#
ip=$1
echo "
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp

auto eth0:1
iface eth0:1 inet static
address 192.168.188."$ip"
netmask 255.255.255.0
network 192.168.188.0
broadcast 192.168.188.255
gateway 192.168.188.1" > /etc/network/interfaces

/etc/init.d/networking restart
echo "====================="
echo "Setting network done!"
echo "====================="

tar -xf ./jdk-8u65-linux-x64.tar.gz
tar -xf ./hadoop-2.6.2.tar.gz
tar -xf ./scala-2.10.4.tgz
tar -xf ./spark-1.2.0-bin-hadoop2.4.tgz

cp -R ./jdk1.8.0_65 /opt/java
cp -R ./hadoop-2.6.2 /opt/hadoop
cp -R ./scala-2.10.4 /opt/scala
cp -R ./spark-1.2.0-bin-hadoop2.4 /opt/spark

rm -R ./jdk1.8.0_65
rm -R ./hadoop-2.6.2
rm -R ./scala-2.10.4
rm -R ./spark-1.2.0-bin-hadoop2.4


echo "================"
echo "Copy file done!"
echo "================"

#
# 配置hadoop
#
JAVA_HOME=/opt/java
HADOOP_HOME=/opt/hadoop
SCALA_HOME=/opt/scala
SPARK_HOME=/opt/spark

echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile
echo "export HADOOP_HOME=$HADOOP_HOME" >> /etc/profile
echo "export PATH=$HADOOP_HOME/bin:$JAVA_HOME/bin:$PATH" >> /etc/profile

echo "export SCALA_HOME=$SCALA_HOME" >> /etc/profile
echo "export SPARK_HOME=$SPARK_HOME" >> /etc/profile
echo "export PATH=$SCALA_HOME/bin:$SPARK_HOME/bin:$HADOOP_HOME/bin:$JAVA_HOME/bin:$PATH" >> /etc/profile

echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh
echo "export JAVA_HOME=$JAVA_HOME" >> $SPARK_HOME/conf/spark-env.sh
echo "export SCALA_HOME=$SCALA_HOME" >> $SPARK_HOME/conf/spark-env.sh
echo "export SPARK_MASTER_IP=192.168.188.$ip" >> $SPARK_HOME/conf/spark-env.sh
echo "export SPARK_WORKER_MEMORY=2g" >> $SPARK_HOME/conf/spark-env.sh
echo "export YARN_CONF_DIR=$HADOOP_HOME/etc/hadoop" >> $SPARK_HOME/conf/spark-env.sh
echo "export HADOOP_HOME=$HADOOP_HOME" >> $SPARK_HOME/conf/spark-env.sh
echo "export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop" >> $SPARK_HOME/conf/spark-env.sh

if [ $2 != "master" ]; then
    new_slave="slave"$((ip-100))
    echo $new_slave >> ./config/slaves
    i=0
    for line in `cat ./hostslist`
    do
	i=$((i+1))
	if [ $((i%2)) != 0 ]; then
	    scp ./config/slaves hadoop@$line:$HADOOP_HOME/etc/hadoop/
	    scp ./config/slaves hadoop@$line:$SPARK_HOME/conf/
	else
	    echo $line >> ./config/slaves
	fi
    done
    echo $new_slave >> ./config/slaves
    echo "192.168.188."$ip" "$new_slave >> ./hostslist
    echo $new_slave > /etc/hostname
    echo "==================="
    echo "transfer back done!"
    echo "==================="
fi

cp ./hosts /etc/hosts
cp ./config/core-site.xml $HADOOP_HOME/etc/hadoop/
cp ./config/hdfs-site.xml $HADOOP_HOME/etc/hadoop/
cp ./config/mapred-site.xml $HADOOP_HOME/etc/hadoop/
cp ./config/yarn-site.xml $HADOOP_HOME/etc/hadoop/
cp ./config/masters $HADOOP_HOME/etc/hadoop/
cp ./config/slaves $HADOOP_HOME/etc/hadoop/
cp ./config/slaves $SPARK_HOME/conf/

chown -R hadoop:hadoop /opt/java
chown -R hadoop:hadoop /opt/hadoop
chown -R hadoop:hadoop /opt/scala
chown -R hadoop:hadoop /opt/spark

echo "========="
echo "ALL DONE!"
echo "========="

reboot


