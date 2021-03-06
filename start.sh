# Raspberry Pi VPN Gateway Start Script

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

echo -e "${INFO}Updating package lists${NC}"
echo -e "${INFO}----------------------${NC}"

apt-get -y -qq update

echo -e "${INFO}Installing dependencies${NC}"
echo -e "${INFO}-----------------------${NC}"

apt-get -y -qq install git

rm -rf /tmp/RPI-VPN-Gateway
git clone -q https://github.com/tunisiano187/RPI-VPN-Gateway.git /tmp/RPI-VPN-Gateway

cd /tmp/RPI-VPN-Gateway
sudo /tmp/RPI-VPN-Gateway/install.sh