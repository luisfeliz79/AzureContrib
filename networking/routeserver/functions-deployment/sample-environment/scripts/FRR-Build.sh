# first sudo su


#FRR configuration
#Enable IP forwarding:
sed -i -e '$a\net.ipv4.ip_forward = 1' /etc/sysctl.conf
# to apply the change
sysctl -p
# check the change
sysctl net.ipv4.ip_forward
#In nva1 install and check the FRR:

sudo apt update -y
sudo apt install frr -y
sudo systemctl enable frr
sudo systemctl start frr
systemctl status frr --no-pager


#Enable BGP daemon in FRR:




# enable bgp daemon
sed -i -e 's/^bgpd=no/bgpd=yes/' /etc/frr/daemons
# restart FRR
systemctl restart frr
systemctl status frr --no-pager
# check FRR status
#systemctl status frr
#In FFR to access to the command line interface run the shell command: vtysh
#The file /etc/frr/vtysh.conf provides configuration information for the vtysh command tool:
#service integrated-vtysh-config
#FFR configuration:

vtysh
