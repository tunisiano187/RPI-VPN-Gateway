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

apt-get -y -qq install pptp-linux

echo -e "${INFO}#######################${NC}"
echo -e "${INFO}# Configuring the VPN #${NC}"
echo -e "${INFO}#######################${NC}"

read -r -p "What is the name of the vpn ?" remotevpnname
read -r -p "What is the server IP or URL ? " remotevpn
read -r -p "What is your VPN username ? " remotevpnuser
read -r -sp "What is your VPN password ? " remotevpnpassword
echo ""
read -r -p "\nWhat is the remote network's address (ex:192.168.1.0/24)" remotevpnnet

echo -e "${INFO}Setting up the VPN informations${NC}"
echo "${remotevpnuser} ${remotevpnname} ${remotevpnpassword} *" >> /etc/ppp/chap-secrets
echo "pty \"pptp ${remotevpn} --nolaunchpppd\"" > /etc/ppp/peers/${remotevpnname}
echo "name ${remotevpnuser}" >> /etc/ppp/peers/${remotevpnname}
echo "remotename ${remotevpnname}" >> /etc/ppp/peers/${remotevpnname}
echo "require-mppe-128" >> /etc/ppp/peers/${remotevpnname}
echo "file /etc/ppp/options.pptp" >> /etc/ppp/peers/${remotevpnname}
echo "ipparam ${remotevpnname}" >> /etc/ppp/peers/${remotevpnname}
echo "usepeerdns" >> /etc/ppp/peers/${remotevpnname}
cp ./config-files/99vpnroute /etc/ppp/ip-up.d/99vpnroute
sed -i "s/workvpn/${remotevpnname}/g" /etc/ppp/ip-up.d/99vpnroute
sed -i "s~192.168.1.0/24~${remotevpnnet}~g" /etc/ppp/ip-up.d/99vpnroute
chmod a+x /etc/ppp/ip-up.d/99vpnroute

echo "#!/bin/sh" > /etc/network/if-up.d/ppp
echo "# This file was installed with the RPI-VPN-Gateway script" >> /etc/network/if-up.d/ppp
echo "# For more info see https://github.com/tunisiano187/RPI-VPN-Gateway" >> /etc/network/if-up.d/ppp
echo "" >> /etc/network/if-up.d/ppp
echo "pon ${remotevpnname}" >> /etc/network/if-up.d/ppp
chmod a+x /etc/network/if-up.d/ppp

echo '* *   * * *   root  /usr/local/bin/vpn' > /etc/cron.d/pppforce
echo "#!/bin/sh" > /usr/local/bin/vpn
command='$(/sbin/ifconfig | /bin/grep ppp)'
echo "if ! [[ $command ]]; then /usr/bin/pon ${remotevpnname}; fi" >> /usr/local/bin/vpn
chmod a+x /usr/local/bin/vpn

echo -e "${INFO}================================================================${NC}"
echo -e "${INFO}=================== Configuration complete! ====================${NC}"
echo -e "${INFO}================================================================${NC}"

echo -e "${INFO}+++++++++++++++++  REBOOTING in 10 SECONDS  ++++++++++++++++++++${INFO}"
echo -e "${INFO}++++++++++++++++++ PRESS CTRL-C to cancel ++++++++++++++++++++++${INFO}"

sleep 10
reboot

exit 0
