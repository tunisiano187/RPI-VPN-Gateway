#!/bin/bash
# Raspberry Pi VPN Gateway Installation Script

NC='\033[0m' # Normal Color
INFO='\033[0;32m' # Green Color
ERROR='\033[0;31m' # Red Color

echo -e "${INFO}Checking if the script is running as root${NC}"
echo -e "${INFO}-----------------------------------------${NC}"
if [ "$EUID" -ne 0 ]
  then 
  echo -e "${ERROR}Please run this script as root${NC}"
  exit 1
fi

clear

echo -e "${INFO}======================================================${NC}"
echo -e "${INFO}======== Setting up Raspberry Pi VPN Gateway =========${NC}"
echo -e "${INFO}======================================================${NC}"

read -r -p "This script will make changes to your system which may break some applications and may require you to reimage your SD card. Are you sure that you wish to continue? [y/N] " confirm

if ! [[ $confirm =~ ^([yY][eE][sS]|[yY])$ ]]
then
	echo -e "${ERROR}Expecting y, so quitting${NC}"
	exit 1
fi

clear
echo -e "${INFO}Updating package lists${NC}"

apt-get -y -qq update

echo -e "${INFO}Installing dependencies${NC}"

apt-get -y -qq install udhcpd pptp-linux

echo -e "${INFO}#######################${NC}"
echo -e "${INFO}# Configuring the VPN #${NC}"
echo -e "${INFO}#######################${NC}"

read -r -p "What is the name of the vpn ?" remotevpnname
read -r -p "What is the server IP or URL ? " remotevpn
read -r -p "What is your VPN username ? " remotevpnuser
read -r -sp "What is your VPN password ? " remotevpnpassword
read -r -p "What is the remote network's address (ex:192.168.1.0/24)" remotevpnnet

echo -e "${INFO}Setting up the VPN informations${NC}"
echo "${remotevpnuser} ${remotevpnname} ${remotevpnpassword} *" >> /etc/ppp/chap-secrets
echo "pty \"pptp ${remotevpn} --nolaunchpppd\"" > /etc/ppp/peers/${remotename}
echo "name ${remotevpnuser}" >> /etc/ppp/peers/${remotename}
echo "remotename ${remotevpnname}" >> /etc/ppp/peers/${remotename}
echo "require-mppe-128" >> /etc/ppp/peers/${remotename}
echo "file /etc/ppp/options.pptp" >> /etc/ppp/peers/${remotename}
echo "ipparam ${remotevpnname}" >> /etc/ppp/peers/${remotename}
cp ./config-files/99vpnroute /etc/ppp/ip-up.d/99vpnroute
sed -i "s/workvpn/${remotevpnname}/g" /etc/ppp/ip-up.d/99vpnroute
sed -i "s~192.168.1.0/24~${remotevpnnet}~g" /etc/ppp/ip-up.d/99vpnroute
chmod +x /etc/ppp/ip-up.d/99vpnroute
echo "#!/bin/sh" > /etc/network/if-up.d/ppp
echo "# This file was installed with the RPI-VPN-Gateway script" >> /etc/network/if-up.d/ppp
echo "# For more info see https://github.com/unixabg/RPI-VPN-Gateway" >> /etc/network/if-up.d/ppp
echo "" >> /etc/network/if-up.d/ppp
echo "pon ${remotevpnname}" >> /etc/network/if-up.d/ppp


echo -e "${INFO}###########################################${NC}"
echo -e "${INFO}# copying configs to relevant directories #${NC}"
echo -e "${INFO}###########################################${NC}"

echo -e "${INFO}Configuring DHCP${NC}"
echo -e "${INFO}----------------${NC}"
read -r -p "Do you want to use remote DNS servers? [y/N] " remotednsresponse

if [[ $remotednsresponse =~ ^([nN])$ ]]
then
	read -r -p "Do you wish to be protected by Cloudflare's kids DNS servers? [y/N] " unblockusdnsresponse
	if [[ $unblockusdnsresponse =~ ^([yY][eE][sS]|[oO])$ ]]
	then
		cp ./config-files/udhcpd_cloudflare_kids.conf /etc/udhcpd.conf
	else
		read -r -p "Do you wish to be protected by Cloudflare's malware protection DNS servers? [y/N] " opendnsresponse
		if [[ $opendnsresponse =~ ^([yY][eE][sS]|[oO])$ ]]
		then
			cp ./config-files/udhcpd_cloudflare_malware.conf /etc/udhcpd.conf
		else
			echo -e "${INFO}No other DNS servers available to choose from. Reverting to Cloudflare's default DNS.${NC}"
			echo -e "${INFO}-------------------------------------------------------------------------------------${NC}"
			cp ./config-files/udhcpd_cloudflare.conf /etc/udhcpd.conf
		fi
	fi
fi

echo -e "${INFO}Searching for the network allowing us to go to the internet.${NC}"
echo -e "${INFO}------------------------------------------------------------${NC}"
_LAN=$(route -n | grep "UG " | tail -n1 | sed 's/[[:space:]]\{1,\}/ /g' | cut -d ' ' -f2 | cut -d '.' -f3)
#_INTERFACE = 
echo -e "${INFO}#########################################${NC}"
echo -e "${INFO}# Updating local network to 192.168.${_ROUTER}.1 #${NC}"
echo -e "${INFO}#########################################${NC}"

sed -i "s/ROUTER/${_ROUTER}/g" /etc/udhcpd.conf
#sed -i "s/DNS/${_DNS}/g" /etc/udhcpd.conf
# Copy in the config file to enable udhcpd
cp ./config-files/udhcpd /etc/default
# Copy in the systemd udhcpd.service file
cp ./config-files/udhcpd.service /lib/systemd/system/
# Tell systemd to enable the udhcpd.service
systemctl enable udhcpd.service

echo -e "${INFO}Configuring interfaces${NC}"
if [ -n "${_ROUTER}" ]; then
	sed -e "s/ROUTER/${_ROUTER}/g" ./config-files/interfaces-template > /etc/network/interfaces
else
	cp ./config-files/interfaces /etc/network
fi

echo -e "${INFO}Configuring NAT${NC}"
cp ./config-files/sysctl.conf /etc

echo -e "${INFO}Configuring iptables${NC}"
cp ./config-files/iptables.ipv4.nat /etc

touch /var/lib/misc/udhcpd.leases

echo -e "${INFO}Initialising DHCP server${NC}"
#service udhcpd start
#update-rc.d udhcpd enable

echo -e "${INFO}================================================================${NC}"
echo -e "${INFO}=================== Configuration complete! ====================${NC}"
echo -e "${INFO}================================================================${NC}"

echo -e "${INFO}+++++++++++++++++  REBOOTING in 10 SECONDS  ++++++++++++++++++++${INFO}"
echo -e "${INFO}++++++++++++++++++ PRESS CTRL-C to cancel ++++++++++++++++++++++${INFO}"

sleep 10
reboot

exit 0