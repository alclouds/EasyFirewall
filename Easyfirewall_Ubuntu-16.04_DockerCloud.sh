#!/bin/bash


## https://www.digitalocean.com/community/tutorials/how-to-implement-a-basic-firewall-template-with-iptables-on-ubuntu-14-04

# Install IPTables Persistent Package 
apt-get install -y iptables-persistent
# Add netfilter-persistent Startup
invoke-rc.d netfilter-persistent save
# Stop netfilter-persistent Service
service netfilter-persistent stop

#backup current rules file.
mv -f /etc/iptables/rules.v4 /etc/iptables/rules.v4.easy.bak
mv -f /etc/iptables/rules.v6 /etc/iptables/rules.v6.easy.bak

# flush all of rules.
service netfilter-persistent flush

#Create Protocol-Specific Chains
iptables -N UDP
iptables -N TCP
iptables -N ICMP

##add the exception for SSH traffic
iptables -A TCP -p tcp --dport 22 -j ACCEPT
##add the exception for SSH 
iptables -A TCP -p tcp --dport 2222 -j ACCEPT

##  TCP port for docker cloud.
iptables -A TCP -p tcp --dport 2375 -j ACCEPT
iptables -A TCP -p tcp --dport 6783 -j ACCEPT


##allow ICMP Type 8 (ping, ICMP traceroute)
iptables -A ICMP -p icmp --icmp-type 8 -j ACCEPT


## UDP port for docker cloud.
iptables -A UDP -p udp --dport 6783 -j ACCEPT

## enable UDP traceroute rejections to get sent out
iptables -A UDP -p udp --dport 33434:33523 -j REJECT

#Create General Purpose Accept and Deny Rules
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#allow all traffic originating on the local loopback interface.
iptables -A INPUT -i lo -j ACCEPT

# deny all invalid packets.
iptables -A INPUT -m conntrack --ctstate INVALID -j DROP

#Creating the Jump Rules to the Protocol-Specific Chains
iptables -A INPUT -p udp -m conntrack --ctstate NEW -j UDP
iptables -A INPUT -p tcp --syn -m conntrack --ctstate NEW -j TCP
iptables -A INPUT -p icmp -m conntrack --ctstate NEW -j ICMP

#Reject All Remaining Traffic
iptables -A INPUT -p udp -j REJECT --reject-with icmp-port-unreachable
iptables -A INPUT -p tcp -j REJECT --reject-with tcp-reset
iptables -A INPUT -j REJECT --reject-with icmp-proto-unreachable

#Adjusting Default Policies
iptables -P INPUT DROP
iptables -P FORWARD DROP

#IPv6 policy of dropping all traffic
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

##service iptables-persistent save
service netfilter-persistent save

#test rules
iptables-restore -t /etc/iptables/rules.v4 && ip6tables-restore -t /etc/iptables/rules.v6 







