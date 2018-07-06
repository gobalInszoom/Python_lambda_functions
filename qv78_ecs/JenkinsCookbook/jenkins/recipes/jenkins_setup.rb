#
# Cookbook:: jenkins
# Recipe:: jenkins_setup
# Author:Bhupesh
# Copyright:: 2017, The Authors, All Rights Reserved.


#execute 'update' do
  #not_if 'yum update -y'
#end

yum_repository "jenkins" do
  baseurl "http://pkg.jenkins-ci.org/redhat"
  gpgkey "http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key"
  #components ["binary/"]
  action :create
end

execute 'java' do
  not_if 'yum install -y java'
end


execute 'wget' do
  not_if 'yum install -y wget'
end


package 'jenkins'

service 'jenkins' do
  supports [:stop, :start, :restart]
  action [:start, :enable]
end

bash 'waiting for Jenkins to up and running...' do
  code <<-EOH
   n=0
   until [ $n -eq 200 ]
 do
 printf '.'
 n=$(curl -sL -w "%{http_code}\\n" "http://localhost:8080/jnlpJars/jenkins-cli.jar" -o /dev/null)
 sleep 5
done
EOH
end



bash 'Update default password' do
  code <<-EOH
   cd /var/lib/jenkins/users/admin/
   mv config.xml config_bkp1.xml
   echo -n 'admin{bar}' | sha256sum>pwd.txt
   VAL="$(cat pwd.txt | rev |  cut -c 4- | rev)"
   echo $VAL
   VAL1="bar:"
   sed "s#<passwordHash>.*#<passwordHash>$VAL1$VAL</passwordHash>#" config_bkp1.xml > config.xml
  EOH
end


service 'jenkins' do
  action [:restart]
end


install_path = "/tmp/jenkins-cli.jar"

bash 'waiting for Jenkins to up and running...' do
 action:run
end



bash 'Download JenKins Cli Jar' do
  code <<-EOH
  wget -O /tmp/jenkins-cli.jar  http://localhost:8080/jnlpJars/jenkins-cli.jar
  EOH
  not_if { ::File.exist?(install_path) }
end


script "Plug-ins List " do
  interpreter "bash"
  user "root"
  cwd "/tmp"
  code <<-EOH
    #insert bash script
plugins='subversion
promoted-builds
matrix-project
conditional-buildstep
parameterized-trigger
build-pipeline-plugin
downstream-ext
dashboard-view
join
credentials
powershell
script-security
clearcase-ucm-plugin
tfs'
echo "${plugins}" > /tmp/plug-ins.txt
EOH
end


bash 'Download Plgins' do
  code <<-EOH
  while read line; do
     extn='.jpi'
     file="/var/lib/jenkins/plugins/$line$extn"
     if [ -f "$file" ]; then
          echo "plug-in $line already exit"
     else
          java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 install-plugin $line   --username admin --password admin;
     fi;
   done < /tmp/plug-ins.txt
EOH
end




bash "turn of Set-up Wizard " do
  code <<-EOH
    cat /etc/sysconfig/jenkins | sed -i "s/-Djava.awt.headless=true/-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false/g" /etc/sysconfig/jenkins
  EOH
end


service 'jenkins' do
  action [:restart]
end

