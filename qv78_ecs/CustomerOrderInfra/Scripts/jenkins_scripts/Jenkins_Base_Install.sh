#!/bin/sh


#######################################  JAVA INSTALLATION ###################################################
if [ -n `which java` ]; then
echo "Java is not installed,Installing Java now "
yum install -y java
else
echo "Java is installed"
fi

#######################################  WGET INSTALLATION ###################################################

if [ ! -x /usr/bin/wget ]; then
    #command -v wget >/dev/null 2>&1 || { echo >&2 "wget is not installed " }
    echo "installing wget now"
    yum install -y wget
fi

####################################### JENKINS INSTALLATION ################################################

if ps aux | grep -v "grep" | grep "jenkins.war"
then
    echo "Jenkins is already running"
else
   echo "Jenkins  is starting now,downloading latest Jenkins "
   wget https://updates.jenkins-ci.org/download/war/2.36/jenkins.war
  echo "export JENKINS_HOME=/efs" >> ~/.bashrc
# echo "Jenkins Home is $JENKINS_HOME" >> ~/.bashrc
  source ~/.bashrc
  echo "Jenkins is starting now"
  nohup java -jar jenkins.war &
  sleep 150
fi

##################################################  ENCRYPT & PLUGIN ###########################################################

cd $JENKINS_HOME/users/admin/
mv config.xml config_bkp1.xml
##echo 'admin |  openssl enc -aes-128-cbc -a -salt -pass pass:admin'>pwd.txt
#pwd = 'cat pwd.txt'
#echo "$pwd"

#echo admin |  openssl enc -aes-128-cbc -a -salt -pass pass:admin >pwd.txt
echo -n 'admin{bar}' | sha256sum>pwd.txt
VAL="$(cat pwd.txt | rev |  cut -c 4- | rev)"
#VAL="$(cat pwd.txt)"
echo $VAL
VAL1="bar:"
#echo "$VAL1$VAL"
sed "s#<passwordHash>.*#<passwordHash>$VAL1$VAL</passwordHash>#" config_bkp1.xml > config.xml
cp -rf /tmp/def_plugin/* /efs/plugins
kill $(ps aux | grep 'jenkins' | awk '{print $2}')
rm -f pwd.txt
cd /tmp/jenkins_scripts
nohup java -jar jenkins.war &
