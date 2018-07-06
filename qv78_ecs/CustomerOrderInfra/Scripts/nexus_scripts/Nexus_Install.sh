#!/usr/bin/bash

yum update -y
#######################################  JAVA INSTALLATION ###################################################
if [ -n `which java` ]; then
 echo "Java is not installed,Installing Java now "
 yum install java -y
else
 echo "Java is installed"
fi

#######################################  WGET INSTALLATION ###################################################
if [ ! -x /usr/bin/wget ]; then
    #command -v wget >/dev/null 2>&1 || { echo >&2 "wget is not installed " }
    echo "installing wget now"
    yum install -y wget
fi

sudo mkdir /app && cd /app
sudo wget https://sonatype-download.global.ssl.fastly.net/nexus/3/nexus-3.0.2-02-unix.tar.gz
sudo tar -xvf nexus-3.0.2-02-unix.tar.gz
sudo mv nexus-3.0.2-02 nexus
sudo adduser nexus
sudo chown -R nexus:nexus /app/nexus
sudo ln -s /app/nexus/bin/nexus /etc/init.d/nexus
sudo chkconfig --add nexus
sudo chkconfig --levels 345 nexus on
sudo service nexus start
sudo service nexus status
sudo service nexus stop
sudo service nexus start
