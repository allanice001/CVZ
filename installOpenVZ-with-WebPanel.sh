#!/bin/bash

clear
echo 'Going to install OpenVZ for you..'
echo 'installing wget..'
yum install -y wget
echo 'now adding openvz Repo'
cd /etc/yum.repos.d
wget -P /etc/yum.repos.d/ http://ftp.openvz.org/openvz.repo
rpm --import http://ftp.openvz.org/RPM-GPG-Key-OpenVZ
echo 'Installing OpenVZ Kernel'
yum install -y vzkernel.x86_64
echo 'Installing additional tools'
yum install -y vzctl vzquota ploop
echo 'Changing around some config files..'
sed -i 's/kernel.sysrq = 0/kernel.sysrq = 1/g' /etc/sysctl.conf
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
echo 'net.ipv4.conf.default.proxy_arp = 0' >> /etc/sysctl.conf
echo 'net.ipv4.conf.all.rp_filter = 1' >> /etc/sysctl.conf
echo 'net.ipv4.conf.default.send_redirects = 1' >> /etc/sysctl.conf
echo 'net.ipv4.conf.all.send_redirects = 0' >> /etc/sysctl.conf
echo 'net.ipv4.icmp_echo_ignore_broadcasts=1' >> /etc/sysctl.conf
echo 'net.ipv4.conf.default.forwarding=1' >> /etc/sysctl.conf
echo 'Done with that, purging your sys configs'
sysctl -p
sed -i 's/NEIGHBOUR_DEVS=detect/NEIGHBOUR_DEVS=all/g' /etc/vz/vz.conf
sed -i 's/SELINUX=enabled/SELINUX=disabled/g' /etc/sysconfig/selinux
echo 'Now downloading CentOS6 x86_64 template....'
cd /vz/template/cache
wget http://download.openvz.org/template/precreated/centos-6-x86_64.tar.gz
/bin/cp /etc/rc.local /tmp/rc.local
cat > /etc/rc.local << EOF
#!/bin/bash
wget -O - https://raw.githubusercontent.com/sibprogrammer/owp/master/installer/ai.sh | sh
modprobe vzcpt
modprobe nf_conntrack_ftp
modprobe ip_nat_ftp
/bin/cp -f /tmp/rc.local /etc/rc.local
EOF
# BARE MINIMUM OpenVZ iptables config - CENTOS 6.4
cat > /etc/sysconfig/iptables << EOF
*nat
:PREROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o eth+ -j MASQUERADE
COMMIT
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -p icmp -m icmp --icmp-type echo-request -j REJECT --reject-with icmp-host-prohibited
-A INPUT -p icmp -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
-A INPUT -m state --state NEW -m tcp -p tcp --dport 3000 -j ACCEPT
-A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
-A FORWARD -p icmp -m icmp --icmp-type echo-request -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -p icmp -j ACCEPT
-A FORWARD -i lo -j ACCEPT
-A FORWARD -o eth+ -j ACCEPT
-A INPUT -j REJECT --reject-with icmp-host-prohibited
-A FORWARD -j REJECT --reject-with icmp-host-prohibited
COMMIT
EOF
reboot
echo ' - - - - - - - - - - - - - - - - - - - - - - '
echo ' The server will reboot now and install OpenVZ Web panel'
echo ' '
echo 'When the server boots, it will run the OpenVZ Web panel installation which can take up to 10 minutes'
echo 'This script is executed by backing up/replacing /etc/rc.local with a new file containing the installation script.'
echo 'Once complete, the original /etc/rc.local file is replaced'
echo ' - - - - - - - - - - - - - - - - - - - - - - '
