#!/usr/bin/sh

yum install wget -y
wget https://packages.chef.io/files/stable/chef-server/12.11.1/el/6/chef-server-core-12.11.1-1.el6.x86_64.rpm
chmod 777 chef-server-core-12.11.1-1.el6.x86_64.rpm
rpm -Uvh chef-server-core-12.11.1-1.el6.x86_64.rpm
echo " Chef server is reconfiguring"
chef-server-ctl reconfigure
sleep 60
chef-server-ctl status
echo " Creating USER"
chef-server-ctl user-create ec2-user ec2 user chef_devops@in.tesco.com 'ec2user' --filename ec2-user.pem
echo "Creating ORGANISATION"
chef-server-ctl org-create dev_ops 'devops_cust' --association_user ec2-user --filename dev_ops-validator.pem
wget https://packages.chef.io/files/stable/chef-manage/2.4.4/el/7/chef-manage-2.4.4-1.el7.x86_64.rpm
chmod 777 chef-manage-2.4.4-1.el7.x86_64.rpm
echo " Chef Managemnt console is installing"
chef-server-ctl install chef-manage
sleep 60
chef-manage-ctl reconfigure --accept-license
chef-manage-ctl status
