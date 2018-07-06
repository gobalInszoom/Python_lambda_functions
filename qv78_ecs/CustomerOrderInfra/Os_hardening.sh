#! /bin/sh

echo $(date -u) "Welcome to OS hardening"
echo $(date -u) "Removing Unwanted FileSystems from the OS"

if [ -f "/etc/modprobe.d/CIS.conf" ]
then
        echo $(date -u) "File is found and will be deleted now"
        rm -rf /etc/modprobe.d/CIS.conf
fi

#ensure mounting of cramfs is disabled

if [[ $(modprobe -n -v cramfs) != "install /bin/true" ]]; then
  echo $(date -u) "Removing unwanted filesystem cramfs"
  echo -e "install cramfs /bin/true" >> /etc/modprobe.d/CIS.conf
  modprobe -n -v cramfs
fi

#ensure mounting of freevxfs is disabled
if [[ $(modprobe -n -v freevxfs) != "install /bin/true" ]]; then
  echo $(date -u) "Removing unwanted filesystem freevxfs"
  echo -e "install freevxfs /bin/true" >> /etc/modprobe.d/CIS.conf
  modprobe -n -v freevxfs
fi

#ensure mounting of jffs2 is disabled
if [[ $(modprobe -n -v jffs2) != "install /bin/true" ]]; then
  echo $(date -u) "Removing unwanted filesystem jffs2"
  echo -e "install jffs2 /bin/true" >> /etc/modprobe.d/CIS.conf
  modprobe -n -v jffs2
fi

#ensure mounting of hfsplus is disabled
if [[ $(modprobe -n -v hfsplus) != "install /bin/true" ]]; then
  echo $(date -u) "Removing unwanted filesystem hfsplus"
  echo -e "install hfsplus /bin/true" >> /etc/modprobe.d/CIS.conf
  modprobe -n -v hfsplus
fi

#ensure mounting of squashfs is disabled
if [[ $(modprobe -n -v squashfs) != "install /bin/true" ]]; then
  echo $(date -u) "Removing unwanted filesystem squashfs"
  echo -e "install squashfs /bin/true" >> /etc/modprobe.d/CIS.conf
  modprobe -n -v squashfs
fi

#ensure mounting of udf is disabled
if [[ $(modprobe -n -v udf) != "install /bin/true" ]]; then
  echo $(date -u) "Removing unwanted filesystem udf"
  echo -e "install udf /bin/true" >> /etc/modprobe.d/CIS.conf
  modprobe -n -v udf
fi

#ensure mounting of vfat is disabled
if [[ $(modprobe -n -v vfat) != "install /bin/true" ]]; then
  echo $(date -u) "Removing unwanted filesystem vfat"
  echo -e "install vfat /bin/true" >> /etc/modprobe.d/CIS.conf
  modprobe -n -v vfat
fi

#create separate partition for /tmp
mount | grep /tmp
status=$?
if [ $status != 0 ]; then
        echo $(date -u) "Tmp will be unmasked and mounted"
        systemctl unmask tmp.mount
        systemctl enable tmp.mount
        systemctl daemon-reexec
        if grep -Fxq "Where=/tmp" /etc/systemd/system/local-fs.target.wants/tmp.mount
        then
                 echo $(date -u) "Tmp is already being mounted"
				 sed -i '/^Options/ s/$/ ,nodev,nosuid/' /etc/systemd/system/local-fs.target.wants/tmp.mount
        else
                echo -e "[Mount]
What=tmpfs
Where=/tmp
Type=tmpfs
Options=mode=1777,strictatime,nodev,nosuid" >> /etc/systemd/system/local-fs.target.wants/tmp.mount
        fi
fi

echo $(date -u) "Configuring Software Updates Policy"

#Ensuring configuration of package managers
yum repolist

#Ensuring gpgcheck is activated globally
grep ^gpgcheck /etc/yum.conf
grep ^gpgcheck /etc/yum.repos.d/*

#Ensuring gpg keys are configured correctly
rpm -q gpg-pubkey --qf '%{name}-%{version}-%{release} --> %{summary}\n'

#Disable rhnsd Daemon 
chkconfig --list rhnsd | grep -c -w "on"
flag=$?
if [ $flag != 0 ]; then
	chkconfig rhnsd off
fi

echo $(date -u) "Checking for FileSystem Integrity"

#Ensuring AIDE is being installed
rpm -q aide
fl=$?
if [ $fl != 0 ]; then
	yum install aide -y
	aide --init
	mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
fi

#Ensure FileSystem is being checked regularly
crontab -u root -l | grep aide
grep -r aide /etc/cron.* /etc/crontab
flag=$?
if [ $flag != 0 ]; then
	 echo  "0 3 * * * /usr/sbin/aide --check" | tee -a /var/spool/cron/root
fi

echo $(date -u) "Secure Boot Settings"

#Ensure permission on Bootloader File
stat /boot/grub2/grub.cfg | grep 600
flag=$?
if [ $flag != 0 ]; then
	chown root:root /boot/grub2/grub.cfg
	chmod og-rwx /boot/grub2/grub.cfg
fi

#Disable inetd Services
echo $(date -u) "Disabling the inetd services"
chkconfig --list | grep "chargen-dgram"
if [ $? -ne 0 ]; then
	echo $(date -u) "No such services are running"
else
	chkconfig chargen-dgram off
	chkconfig chargen-stream off
	echo $(date -u) "Disabled inetd services"
fi

#Disable daytime services
echo $(date -u) "Disable daytime services"
chkconfig --list | grep "daytime-dgram"
if [ $? -ne 0 ]; then
	echo $(date -u) "No such services are running"
else
	chkconfig daytime-dgram off
	chkconfig daytime-stream off
	echo $(date -u) "Disabled daytime services"
fi
	
#Disable discard services
echo $(date -u) "Disable discard services"
chkconfig --list | grep "discard-dgram"
if [ $? -ne 0 ]; then
	echo $(date -u) "No such services are running"
else
	chkconfig discard-dgram off
	chkconfig discard-stream off
	echo $(date -u) "Disabled discard services"
fi

#Disable echo services
echo $(date -u) "Disable echo services"
chkconfig --list | grep "echo-dgram"
if [ $? -ne 0 ]; then
	echo $(date -u) "No such services are running"
else
	chkconfig echo-dgram off
	chkconfig echo-stream off
	echo $(date -u) "Disabled echo services"
fi

#Disable time services
echo $(date -u) "Disable time services"
chkconfig --list | grep "time-dgram"
if [ $? -ne 0 ]; then
	echo $(date -u) "No such services are running"
else
	chkconfig time-dgram off
	chkconfig time-stream off
	echo $(date -u) "Disabled time services"
fi

#Disable tftp services
echo $(date -u) "Disable tftp services"
chkconfig --list | grep "tftp"
if [ $? -ne 0 ]; then
	echo $(date -u) "No such services are running"
else
	chkconfig tftp off
	echo $(date -u) "Disabled tftp services"
fi

#Check for the presence of ntp or chrony
echo $(date -u) "Check for the presence of ntp or chrony"
if [[ -n `rpm -q ntp ` ]]; then
    echo $(date -u) "NTP is already being installed on the server"
elif [ -n `rpm -q chrony` ]; then
    echo $(date -u) "Chrony is already installed in the server"
else
    echo $(date -u) "Installing chrony"
    yum install -y chrony
fi

#Configure ntp server
echo $(date -u) "Configure ntp server"
if [[ -n `grep "^server" /etc/chrony.conf` ]]; then
    echo $(date -u) "NTP is already configured"
fi

#Ensure X Window S/m is not installed
echo $(date -u) "Removing x window s/m if present"
if [ `rpm -qa xorg-x11*` ]; then
    yum remove xorg-x11* -y
    echo $(date -u) "Removing X Window s/m"
fi

#Remove Yellow pages if present
echo $(date -u) "Remove Yellow pages if present"
if [[ -n `rpm -q ypbind` ]]; then
	echo $(date -u) "Yellow pages are found and they will be removed"
	yum remove ypbind -y
fi

#Remove rsh if present
echo $(date -u) "Remove rsh if present"
if [[ -n `rpm -q rsh` ]]; then
	echo $(date -u) "Rsh is present and it will be removed"
	yum remove rsh -y
fi

# Ensure IP forwarding is disabled 
echo $(date -u) " Ensure IP forwarding is disabled"
if [[ `sysctl net.ipv4.ip_forward | grep 0` ]]; then
	echo -e "net.ipv4.ip_forward = 0" >> /etc/sysctl.conf
	echo $(date -u) "Disabled IP forwarding"
	sysctl -w net.ipv4.ip_forward=0
	sysctl -w net.ipv4.route.flush=1
fi

# Ensure packet redirect sending is disabled
echo $(date -u) "Ensure packet redirect sending is disabled"
if [[ `sysctl net.ipv4.conf.all.send_redirects | grep 0` ]]; then
	echo -e "net.ipv4.conf.all.send_redirects = 0" >> /etc/sysctl.conf
fi

if [[ `sysctl net.ipv4.conf.default.send_redirects | grep 0` ]]; then
	echo -e "net.ipv4.conf.default.send_redirects = 0" >> /etc/sysctl.conf
	sysctl -w net.ipv4.conf.all.send_redirects=0
	sysctl -w net.ipv4.conf.default.send_redirects=0
	sysctl -w net.ipv4.route.flush=1
	echo $(date -u) "Packet redirecting is disabled"
fi

# Ensure source routed packets are not accepted
echo $(date -u) "Ensure source routed packets are not accepted"
if [[ `sysctl net.ipv4.conf.all.accept_source_route | grep 0` ]]; then
	echo -e "net.ipv4.conf.all.accept_source_route = 0" >> /etc/sysctl.conf
fi

if [[ `sysctl net.ipv4.conf.default.accept_source_route | grep 0` ]]; then
	echo -e "net.ipv4.conf.default.accept_source_route = 0" >> /etc/sysctl.conf
	sysctl -w net.ipv4.conf.all.accept_source_route=0
	sysctl -w net.ipv4.conf.default.accept_source_route=0
	sysctl -w net.ipv4.route.flush=1
	echo $(date -u) "Disabled accepting of routed packets"
fi

#  Ensure ICMP redirects are not accepted
echo $(date -u) " Ensure ICMP redirects are not accepted"
if [[ `sysctl net.ipv4.conf.all.accept_redirects | grep 0` ]]; then
	echo -e "net.ipv4.conf.all.accept_redirects = 0" >> /etc/sysctl.conf
fi

if [[ `sysctl net.ipv4.conf.default.accept_redirects | grep 0` ]]; then
	echo -e "net.ipv4.conf.default.accept_redirects = 0" >> /etc/sysctl.conf
	sysctl -w net.ipv4.conf.all.accept_redirects=0
	sysctl -w net.ipv4.conf.default.accept_redirects=0
	sysctl -w net.ipv4.route.flush=1
	echo $(date -u) "Disabled accepting of routed packets"
fi

# Ensure suspicious packets are logged 
echo $(date -u) " Ensure suspicious packets are logged "
if [[ ` sysctl net.ipv4.conf.all.log_martians | grep 1` ]]; then
	echo -e "net.ipv4.conf.all.log_martians = 1" >> /etc/sysctl.conf
fi

if [[ ` sysctl net.ipv4.conf.default.log_martians | grep 1` ]]; then
	echo -e "net.ipv4.conf.default.log_martians = 1" >> /etc/sysctl.conf
	sysctl -w net.ipv4.conf.all.log_martians=1
	sysctl -w net.ipv4.conf.default.log_martians=1
	sysctl -w net.ipv4.route.flush=1
	echo $(date -u) "Disabled for suspicious packets to login"
fi

#Ensure broadcast icmps are ignored
echo $(date -u) "Ensure broadcast icmps are ignored"
if [[ `sysctl net.ipv4.icmp_echo_ignore_broadcasts | grep 1` ]]; then
	echo -e "net.ipv4.icmp_echo_ignore_broadcasts = 1" >> /etc/sysctl.conf
	sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
	sysctl -w net.ipv4.route.flush=1
fi

#Ensure bogus ICMP responses are ignored 
echo $(date -u) "Ensure bogus ICMP responses are ignored "
if [[ `sysctl net.ipv4.icmp_ignore_bogus_error_responses | grep 1` ]]; then
	echo -e "net.ipv4.icmp_ignore_bogus_error_responses = 1" >> /etc/sysctl.conf
	sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
	sysctl -w net.ipv4.route.flush=1
fi

#Ensure Reverse Path Filtering is enabled
echo $(date -u) "Ensure Reverse Path Filtering is enabled"
if [[ `sysctl net.ipv4.conf.default.rp_filter | grep 1` ]]; then
	echo -e "net.ipv4.conf.default.rp_filter = 1" >> /etc/sysctl.conf
fi
if [[ `sysctl net.ipv4.conf.all.rp_filter | grep 1` ]]; then
	echo -e "net.ipv4.conf.all.rp_filter = 1" >> /etc/sysctl.conf
	sysctl -w net.ipv4.conf.all.rp_filter=1
	sysctl -w net.ipv4.conf.default.rp_filter=1
	sysctl -w net.ipv4.route.flush=1
fi

# Ensure TCP SYN Cookies is enabled 
echo $(date -u) "Ensure TCP SYN Cookies is enabled"
if [[ `sysctl net.ipv4.tcp_syncookies | grep 1` ]]; then
	echo -e "net.ipv4.tcp_syncookies = 1" >> /etc/sysctl.conf
	sysctl -w net.ipv4.tcp_syncookies=1
	sysctl -w net.ipv4.route.flush=1
fi

# Ensure TCP Wrappers is installed
echo $(date -u)  "Ensure TCP Wrappers is installed"
if [[ `rpm -q tcp_wrappers` ]]; then
	yum install tcp_wrappers
	echo $(date -u) "TCP wrapper is now installed in the system"
fi
if [[ -n ` rpm -q tcp_wrappers-libs` ]]; then
	echo $(date -u) "Libs.so is configured with TCP wrapper"
fi

# Set proper permissions on /etc/hosts.allow
echo $(date -u) "Set proper permissions on /etc/hosts.allow"
if [[ `stat /etc/hosts.allow | grep 0644` ]]; then
	echo $(date -u) "changing the owner of the file and setting the permission for root only"
	chown root:root /etc/hosts.allow
	chmod 644 /etc/hosts.allow
fi

# Set proper permissions on /etc/hosts.deny
echo $(date -u) "Set proper permissions on /etc/hosts.deny"
if [[ `stat /etc/hosts.deny | grep 0644` ]]; then
	echo $(date -u) "changing the owner of the file and setting the permission for root only"
	chown root:root /etc/hosts.deny
	chmod 644 /etc/hosts.deny
fi

echo $(date -u) "Disabling uncommon protocols"
#Ensure DCCP is disabled
echo $(date -u) "Ensure DCCP is disabled"
if [[ $(modprobe -n -v dccp) != "install /bin/true" ]]; then
	echo -e "install dccp /bin/true" >> /etc/modprobe.d/CIS.conf
	modprobe -n -v dccp
fi

#Ensure sctp is disabled
echo $(date -u) "Ensure sctp is disabled"
if [[ $(modprobe -n -v sctp) != "install /bin/true" ]]; then
	echo -e "install sctp /bin/true" >> /etc/modprobe.d/CIS.conf
	modprobe -n -v sctp
fi

#Ensure rds is disabled
echo $(date -u) "Ensure rds is disabled"
if [[ $(modprobe -n -v rds) != "install /bin/true" ]]; then
	echo -e "install rds /bin/true" >> /etc/modprobe.d/CIS.conf
	modprobe -n -v rds
fi

#Ensure tipc is disabled
echo $(date -u) "Ensure tipc is disabled"
if [[ $(modprobe -n -v tipc) != "install /bin/true" ]]; then
	echo -e "install tipc /bin/true" >> /etc/modprobe.d/CIS.conf
	modprobe -n -v tipc
fi

#Ensuring Firewall Configuration
echo $(date -u) "Ensuring proper Firewall configuration"
if [[ -n `rpm -q iptables` ]]; then
	echo $(date -u) "Iptables is not found and will be installed now"
	yum install iptables
fi

#Ensure audit log size is being set
echo $(date -u) "Ensure audit log size is being set"
service auditd reload
if [[ `grep max_log_file /etc/audit/auditd.conf` ]]; then
	echo -e "max_log_file = 10" >> /etc/audit/auditd.conf
	echo $(date -u) "Audit log file is set upto 10MB"
fi

#Ensure system is suspended when audit logs are full
echo $(date -u) "Ensure system is suspended when audit logs are full"
if [[ ` grep "space_left_action = email" /etc/audit/auditd.conf` ]]; then
	sed -i 's/^space_left_action .*$/space_left_action = email/' /etc/audit/auditd.conf
	echo $(date -u) "Setting space_left_action to email"
fi
if [[ `grep "action_mail_acct = root" /etc/audit/auditd.conf` ]]; then
	sed -i 's/^action_mail_acct .*$/action_mail_acct = root/' /etc/audit/auditd.conf
	echo $(date -u) "Setting action_mail_acct to root"
fi
if [[ `grep "admin_space_left_action = syslog" /etc/audit/auditd.conf` ]]; then
	sed -i 's/^admin_space_left_action .*$/admin_space_left_action = SYSLOG/' /etc/audit/auditd.conf
	echo $(date -u) "Setting admin_space_left_action to syslog"
fi
if [[ ` grep "max_log_file_action = ROTATE" /etc/audit/auditd.conf` ]]; then
	sed -i 's/^max_log_file_action .*$/max_log_file_action = ROTATE/' /etc/audit/auditd.conf
	echo $(date -u) "Setting max_log_file_action to rotate"
fi
echo $(date -u) "Ensuring auditing service is being enabled"
if [[ `systemctl is-enabled auditd` ]]; then
	systemctl enable auditd
	echo $(date -u) "Enabling auditd service"
fi

#Ensure events that modify date and time information are collected
echo $(date -u) "Ensure events that modify date and time information are collected"
if [[ `grep time-change /etc/audit/audit.rules` ]]; then
	echo -e "-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
-w /etc/localtime -p wa -k time-change" >> /etc/audit/audit.rules
fi

#Ensure events that modify user/group information are collected 
echo $(date -u) "Ensure events that modify user/group information are collected"
if [[ `grep identity /etc/audit/audit.rules` ]]; then
	echo -e "-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity" >> /etc/audit/audit.rules
fi

# Ensure events that modify the system's network environment are collected
echo $(date -u) " Ensure events that modify the system's network environment are collected"
if [[ `grep system-locale /etc/audit/audit.rules` ]]; then
	echo -e "-a always,exit -F arch=b64 -S sethostname -S setdomainname -k system-locale
-a always,exit -F arch=b32 -S sethostname -S setdomainname -k system-locale
-w /etc/issue -p wa -k system-locale
-w /etc/issue.net -p wa -k system-locale
-w /etc/hosts -p wa -k system-locale
-w /etc/sysconfig/network -p wa -k system-locale"  >> /etc/audit/audit.rules
fi

#Ensure events that modify the system's Mandatory Access Controls are collected 
echo $(date -u) "Ensure events that modify the system's Mandatory Access Controls are collected"
if [[ `grep MAC-policy /etc/audit/audit.rules` ]]; then
	echo -e "-w /etc/selinux/ -p wa -k MAC-policy" >> /etc/audit/audit.rules
fi 

# Ensure login and logout events are collected
echo $(date -u)  "Ensure login and logout events are collected"
if [[ `grep logins /etc/audit/audit.rules` ]]; then
	echo -e "-w /var/log/lastlog -p wa -k logins
-w /var/run/faillock/ -p wa -k logins" >> /etc/audit/audit.rules
fi

#Ensure session initiation information is collected
echo $(date -u) "Ensure session initiation information is collected"
if [[ `grep session /etc/audit/audit.rules` ]]; then
	echo -e "-w /var/run/utmp -p wa -k session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session" >> /etc/audit/audit.rules
fi

# Ensure discretionary access control permission modification events are collected
echo $(date -u) "Ensure discretionary access control permission modification events are collected"
if [[ `grep perm_mod /etc/audit/audit.rules` ]]; then
	echo -e "-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b64 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod
-a always,exit -F arch=b32 -S setxattr -S lsetxattr -S fsetxattr -S removexattr -S lremovexattr -S fremovexattr -F auid>=1000 -F auid!=4294967295 -k perm_mod" >> /etc/audit/audit.rules
fi

#Ensure unsuccessful unauthorized file access attempts are collected
echo $(date -u) "Ensure unsuccessful unauthorized file access attempts are collected"
if [[ `grep access /etc/audit/audit.rules` ]]; then
	echo -e "-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EACCES -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b64 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access
-a always,exit -F arch=b32 -S creat -S open -S openat -S truncate -S ftruncate -F exit=-EPERM -F auid>=1000 -F auid!=4294967295 -k access" >> /etc/audit/audit.rules
fi

#Ensure successful file system mounts are collected
echo $(date -u) "Ensure successful file system mounts are collected"
if [[ `grep mounts /etc/audit/audit.rules` ]]; then 
	echo -e "-a always,exit -F arch=b64 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts
-a always,exit -F arch=b32 -S mount -F auid>=1000 -F auid!=4294967295 -k mounts" >> /etc/audit/audit.rules
fi

# Ensure file deletion events by users are collected
echo $(date -u) " Ensure file deletion events by users are collected"
if [[ `grep delete /etc/audit/audit.rules` ]]; then 
	echo -e "-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=4294967295 -k delete" >> /etc/audit/audit.rules
fi

# Ensure changes to system administration scope
echo $(date -u) " Ensure changes to system administration scope"
if [[ `grep scope /etc/audit/audit.rules` ]]; then 
	echo -e "-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d -p wa -k scope" >> /etc/audit/audit.rules
fi

# Ensure system administrator actions (sudolog) are collected 
echo $(date -u) " Ensure system administrator actions (sudolog) are collected"
if [[ `grep actions /etc/audit/audit.rules` ]]; then 
	echo -e "-w /var/log/sudo.log -p wa -k actions" >> /etc/audit/audit.rules
fi

#Ensure the audit configuration is immutable 
echo $(date -u) "Ensure the audit configuration is immutable"
if [[ ` grep "^\s*[^#]" /etc/audit/audit.rules | tail -1` ]]; then 
	echo -e "-e 2" >> /etc/audit/audit.rules
fi

#Set proper permission on log files
find /var/log -type f -exec chmod g-wx,o-rwx {} +
service auditd reload
#Ensure Cron daemon is enabled
echo $(date -u) "Ensure Cron daemon is enabled"
if [[ ` systemctl is-enabled crond` ]]; then
	 systemctl enable crond
fi

#Ensure permissions on /etc/crontab are configured
echo $(date -u) "Ensure permissions on /etc/crontab are configured"
if [[ `stat /etc/crontab | grep 0600` ]]; then
	chown root:root /etc/crontab
	chmod og-rwx /etc/crontab
fi

#Ensure permissions on /etc/cron.hourly are configured
echo $(date -u) "Ensure permissions on /etc/cron.hourly are configured"
if [[ `stat /etc/cron.hourly | grep 0600` ]]; then
	chown root:root /etc/cron.hourly
	chmod og-rwx /etc/cron.hourly
fi

#Ensure permissions on /etc/cron.daily are configured
echo $(date -u) "Ensure permissions on /etc/cron.daily are configured"
if [[ `stat /etc/cron.daily | grep 0600` ]]; then
	chown root:root /etc/cron.daily
	chmod og-rwx /etc/cron.daily
fi

#Ensure permissions on /etc/cron.weekly are configured
echo $(date -u) "Ensure permissions on /etc/cron.weekly are configured"
if [[ `stat /etc/cron.weekly | grep 0600` ]]; then
	chown root:root /etc/cron.weekly
	chmod og-rwx /etc/cron.weekly
fi

#Ensure permissions on /etc/cron.monthly are configured
echo $(date -u) "Ensure permissions on /etc/cron.monthly are configured"
if [[ `stat /etc/cron.monthly | grep 0600` ]]; then
	chown root:root /etc/cron.monthly
	chmod og-rwx /etc/cron.monthly
fi

#Ensure permissions on /etc/cron.d are configured
echo $(date -u) "Ensure permissions on /etc/cron.d are configured"
if [[ `stat /etc/cron.d | grep 0600` ]]; then
	chown root:root /etc/cron.d
	chmod og-rwx /etc/cron.d
fi

# Ensure at/cron is restricted to authorized users
echo $(date -u) " Ensure at/cron is restricted to authorized users"
if [[ -n `stat /etc/cron.deny` ]]; then
	echo $(date -u) "/etc/cron.deny exists and will be removed"
	rm -rf /etc/cron.deny
fi
if [[ -n `stat /etc/at.deny` ]]; then
	echo $(date -u) "/etc/at.deny exists and will be removed"
	rm -rf /etc/at.deny
fi
if [[ `stat /etc/cron.allow | grep 0600` ]]; then
	chown root:root /etc/cron.allow
	chmod og-rwx /etc/cron.allow
fi

# SSH Server Configuration
echo $(date -u) "SSH Server Configuration Begins"

#Ensure permissions on /etc/ssh/sshd_config are configured
echo $(date -u) "Ensure permissions on /etc/ssh/sshd_config are configured"
if [[ `stat /etc/ssh/sshd_config | grep 600` ]]; then
	chown root:root /etc/ssh/sshd_config
	chmod og-rwx /etc/ssh/sshd_config
fi

# Ensure SSH Protocol is set to 2
echo $(date -u) "Ensure SSH Protocol is set to 2"
if [[ `grep "^Protocol 2" /etc/ssh/sshd_config` ]]; then
	echo -e "Protocol 2" >> /etc/ssh/sshd_config 
fi

#Ensure SSH LogLevel is set to INFO
echo $(date -u) "Ensure SSH LogLevel is set to INFO"
if [[ `grep "^LogLevel INFO" /etc/ssh/sshd_config` ]]; then
	echo -e "LogLevel INFO" >> /etc/ssh/sshd_config 
fi

#Ensure SSH X11 forwarding is disabled
echo $(date -u) "Ensure SSH X11 forwarding is disabled"
if [[ `grep "^X11Forwarding No" /etc/ssh/sshd_config` ]]; then
	sed -i 's/^X11Forwarding .*$/X11Forwarding No/' /etc/ssh/sshd_config
fi

# Ensure SSH MaxAuthTries is set to 4 or less 
echo $(date -u) " Ensure SSH MaxAuthTries is set to 4 or less "
if [[ `grep "^MaxAuthTries" /etc/ssh/sshd_config` ]]; then
	echo -e "MaxAuthTries 4" >> /etc/ssh/sshd_config 
fi

#Ensure SSH HostbasedAuthentication is disabled
echo $(date -u) "Ensure SSH HostbasedAuthentication is disabled"
if [[ `grep "^HostbasedAuthentication" /etc/ssh/sshd_config` ]]; then
	echo -e "HostbasedAuthentication No" >> /etc/ssh/sshd_config 
fi

#Ensure SSH root login is disabled
echo $(date -u) "Ensure SSH root login is disabled"
if [[ `grep "^PermitRootLogin" /etc/ssh/sshd_config` ]]; then
	echo -e "PermitRootLogin No" >> /etc/ssh/sshd_config 
fi

#Ensure SSH PermitUserEnvironment is disabled
echo $(date -u) "Ensure SSH PermitUserEnvironment is disabled"
if [[ ` grep PermitUserEnvironment /etc/ssh/sshd_config` ]]; then
	echo -e "PermitUserEnvironment no" >> /etc/ssh/sshd_config 
fi

#Ensure SSH Idle Timeout Interval is configured
echo $(date -u) "Ensure SSH Idle Timeout Interval is configured"
if [[ `grep "^ClientAliveInterval" /etc/ssh/sshd_config` ]]; then
	echo -e "ClientAliveInterval 300" >> /etc/ssh/sshd_config 
fi
if [[ `grep "^ClientAliveCountMax" /etc/ssh/sshd_config` ]]; then
	echo -e "ClientAliveCountMax 1" >> /etc/ssh/sshd_config 
fi

#Ensure SSH LoginGraceTime is set to one minute or less
echo $(date -u) "Ensure SSH LoginGraceTime is set to one minute or less"
if [[ `grep "^LoginGraceTime" /etc/ssh/sshd_config` ]]; then
	echo -e "LoginGraceTime 60" >> /etc/ssh/sshd_config 
fi

#Ensure SSH access is limited 
echo $(date -u) "Ensure SSH access is limited "
if [[ ` grep "^AllowUsers" /etc/ssh/sshd_config` ]]; then
	echo -e "AllowUsers ec2-user" >> /etc/ssh/sshd_config 
fi

#Ensure SSH warning banner is configured 
echo $(date =u) "Ensure SSH warning banner is configured"
if [[ 'grep "^Banner" /etc/ssh/sshd_config' ]]; then
	echo -e "Banner /etc/issue.net" >> /etc/ssh/sshd_config 
fi

# Configure PAM
echo $(date -u) "Configuring PAM"

#Set minimum requirements for password
echo $(date -u) "Set password requirement to have one uppercase, one lowercase, one special char, digit"
if [[ `grep ^minlen /etc/security/pwquality.conf` ]]; then
	echo -e "minlen=9" >> /etc/security/pwquality.conf  
fi
if [[ `grep ^dcredit /etc/security/pwquality.conf` ]]; then
	echo -e "dcredit=1" >> /etc/security/pwquality.conf  
fi
if [[ `grep ^ucredit /etc/security/pwquality.conf` ]]; then
	echo -e "ucredit=1" >> /etc/security/pwquality.conf  
fi
if [[ `grep ^lcredit /etc/security/pwquality.conf` ]]; then
	echo -e "lcredit=1" >> /etc/security/pwquality.conf  
fi
if [[ `grep ^ocredit /etc/security/pwquality.conf` ]]; then
	echo -e "ocredit=1" >> /etc/security/pwquality.conf  
fi

# Ensure password expiration exists
echo $(date -u) " Ensure password expiration exist"
if [[ `grep "PASS_MAX_DAYS 75" /etc/login.defs` ]]; then
	sed -i 's/^PASS_MAX_DAYS .*$/PASS_MAX_DAYS 75/' /etc/login.defs
fi






