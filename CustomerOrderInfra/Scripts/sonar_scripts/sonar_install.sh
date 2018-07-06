#!/usr/bin/sh

sudo yum update -y
sudo yum install wget -y

sudo wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u45-b14/jdk-8u45-linux-x64.rpm"
sudo wget http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm
sudo wget http://cdn.mysql.com//Downloads/Connector-Python/mysql-connector-python-2.1.4-1.el7.x86_64.rpm
sudo wget http://cdn.mysql.com//Downloads/Connector-Python/mysql-connector-python-cext-2.1.4-1.el7.x86_64.rpm
sudo wget http://cdn.mysql.com//Downloads/MySQLGUITools/mysql-utilities-1.6.4-1.el7.noarch.rpm
sudo wget -O /etc/yum.repos.d/sonar.repo http://downloads.sourceforge.net/project/sonar-pkg/rpm/sonar.repo

sudo rpm -Uvh jdk-8u45-linux-x64.rpm
sudo rpm -Uvh mysql-community-release-el7-5.noarch.rpm
sudo rpm -Uvh mysql-connector-python-2.1.4-1.el7.x86_64.rpm
sudo rpm -Uvh mysql-connector-python-cext-2.1.4-1.el7.x86_64.rpm
sudo rpm -Uvh mysql-utilities-1.6.4-1.el7.noarch.rpm

sudo yum install sonar -y
sudo yum install mysql-server mysql* -y

sudo service mysql start
sudo service mysql status

# To set the password to mysql root use syntax : mysqladmin -u root password <password>
mysqladmin -u root password root

mysql -u root -proot -e "CREATE USER 'sonar'@'localhost' IDENTIFIED BY 'password';"
mysql -u root -proot -e "CREATE DATABASE sonar CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -u root -proot -e "GRANT ALL PRIVILEGES ON sonar.* TO 'sonar'@'localhost';"

sudo sed -i -e 's|#sonar.jdbc.username=|sonar.jdbc.username=sonar|g' \
			-e 's|#sonar.jdbc.password=|sonar.jdbc.password=password|g' \
			-e 's|#sonar.jdbc.url=jdbc:mysql|sonar.jdbc.url=jdbc:mysql|g' \
			-e 's|#sonar.web.javaOpts|sonar.web.javaOpts|g' \
			-e 's|#sonar.web.host|sonar.web.host|g' \
			-e 's|#sonar.web.port|sonar.web.port|g' /opt/sonar/conf/sonar.properties

sudo /opt/sonar/bin/linux-x86-64/sonar.sh start
sudo /opt/sonar/bin/linux-x86-64/sonar.sh status
exit 0
