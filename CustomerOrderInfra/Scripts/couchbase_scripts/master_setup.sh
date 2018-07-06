#!/usr/bin/sh

##### Mounting of ebs blocks for separation of data and logs #####
cd /
sudo file -s /dev/xvdb
sudo mkfs -t xfs /dev/xvdb
sudo mkfs -t xfs /dev/xvdc
sudo mkdir couchbasedata
sudo mkdir couchbaselogs
sudo mount /dev/xvdb couchbasedata/
sudo mount /dev/xvdc couchbaselogs/
sudo df
sudo mv /etc/fstab /etc/fstab_bkup
sudo mv /tmp/couchbase_scripts/fstab /etc/fstab
sudo sed -i -e 's/\r//g' /etc/fstab
sudo cat /etc/fstab
sudo mount -a
#sleep 150

##### Disabling of transparent_hugepages  #####
sudo mv /tmp/couchbase_scripts/disable-thp /etc/init.d/disable-thp
sudo chmod 755 /etc/init.d/disable-thp
sudo sed -i -e 's/\r//g' /etc/init.d/disable-thp
sudo service disable-thp restart
sudo chkconfig disable-thp on
cat /sys/kernel/mm/transparent_hugepage/enabled
cat /sys/kernel/mm/transparent_hugepage/defrag

##### Disable swapiness #####
sudo sysctl vm.swappiness=0
sudo mv /etc/sysctl.conf /etc/sysctl_bkup.conf
sudo mv /tmp/couchbase_scripts/sysctl.conf /etc/sysctl.conf
sudo sed -i -e 's/\r//g' /etc/sysctl.conf


#### Installing and configuring of Couchbase #####
sudo yum install wget -y
wget https://s3.amazonaws.com/couchbasepackage/couchbase-server-enterprise-4.5.1-centos7.x86_64.rpm
rpm --install couchbase-server-enterprise-4.5.1-centos7.x86_64.rpm
chmod 777 /couchbasedata
chmod 777 /couchbaselogs
sudo /etc/init.d/couchbase-server status
sudo /etc/init.d/couchbase-server stop
sudo /etc/init.d/couchbase-server start
sleep 150

#change the logs and data to two different ebs
/opt/couchbase/bin/couchbase-cli node-init -c localhost:8091 -u ec2-user -p ec2user --node-init-data-path=/couchbasedata
/opt/couchbase/bin/couchbase-cli setting-audit -c localhost:8091 -u ec2-user -p ec2user --audit-enabled 1 --audit-log-path=/couchbaselogs
/opt/couchbase/bin/couchbase-cli collect-logs-start -c localhost:8091 -u ec2-user -p ec2user --all-nodes
sudo mv /opt/couchbase/etc/couchbase/static_config /opt/couchbase/etc/couchbase/static_config_bkup
sudo mv /tmp/couchbase_scripts/static_config /opt/couchbase/etc/couchbase/static_config
sudo /etc/init.d/couchbase-server restart
sleep 50

#create groups
/opt/couchbase/bin/couchbase-cli group-manage -c localhost:8091 -u ec2-user -p ec2user --create --group-name=$1$2
/opt/couchbase/bin/couchbase-cli group-manage -c localhost:8091 -u ec2-user -p ec2user --create --group-name=$1$4
/opt/couchbase/bin/couchbase-cli group-manage -c localhost:8091 -u ec2-user -p ec2user --create --group-name=$1$7

#initialise the cluster
/opt/couchbase/bin/couchbase-cli cluster-init --cluster-username=ec2-user --cluster-password=ec2user --cluster-port=8091 --cluster-ramsize=8000 --cluster-fts-ramsize=4000 --index-storage-setting=memopt --services=data

#add nodes to different groups
/opt/couchbase/bin/couchbase-cli group-manage -c localhost:8091 -u ec2-user -p ec2user --group-name=$1$2 --add-servers=$3 --server-add-username=ec2-user --server-add-password=ec2user --services=data
/opt/couchbase/bin/couchbase-cli group-manage -c localhost:8091 -u ec2-user -p ec2user --group-name=$1$4 --add-servers=$5 --server-add-username=ec2-user --server-add-password=ec2user --services=data
/opt/couchbase/bin/couchbase-cli group-manage -c localhost:8091 -u ec2-user -p ec2user --group-name=$1$4 --add-servers=$6 --server-add-username=ec2-user --server-add-password=ec2user --services=data
/opt/couchbase/bin/couchbase-cli group-manage -c localhost:8091 -u ec2-user -p ec2user --group-name=$1$7 --add-servers=$8 --server-add-username=ec2-user --server-add-password=ec2user --services=data
/opt/couchbase/bin/couchbase-cli group-manage -c localhost:8091 -u ec2-user -p ec2user --group-name=$1$7 --add-servers=$9 --server-add-username=ec2-user --server-add-password=ec2user --services=data

#rebalance the cluster for first time
/opt/couchbase/bin/couchbase-cli rebalance -c localhost:8091 -u ec2-user -p ec2user
