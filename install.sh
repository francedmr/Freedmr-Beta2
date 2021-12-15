#!/bin/bash

###############################################################################
#
#		Copyright (C) 2021 Adrian Craig (Ozzie), M0GLJ <oz-dmr@oz-dmr.uk>
#		FreeDMR Installer Script
#
#		Copyright (C) 2020 Simon Adlem, G7RZU <g7rzu@gb7fr.org.uk>
#		FreeDMR Server System
#
#		This program is free software; you can redistribute it and/or modify
#		it under the terms of the GNU General Public License as published by
#   	the Free Software Foundation; either version 3 of the License, or
#   	(at your option) any later version.
#
#   	This program is distributed in the hope that it will be useful,
#   	but WITHOUT ANY WARRANTY; without even the implied warranty of
#   	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   	GNU General Public License for more details.
#
#   	You should have received a copy of the GNU General Public License
#   	along with this program; if not, write to the Free Software Foundation,
#   	Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
#
#		https://www.gnu.org/licenses/licenses.en.html
#
#       Developed on Debian 11 - X86_64
#
###############################################################################

# Check for SUDO access as ROOT

if [ "$EUID" -ne 0 ]
  then echo "Please enter root (sudo mode) before running this script"
  echo
  echo
  exit
fi

# Set version numbers

version="1.05"

# Change Log

# v1.05		Passworn Length Checking for NORMAL INSTALL - 8 Characters Minimum
# v1.04		Fix Some Bugs
# v1.03		Change Logo Setup
# v1.02		Fix Some Bugs
# v1.01		Add IPv6 Support for Docker Components
# v1.00		Creation of FreeDMR-Installer Script

###################
##               ##
## Set Functions ##
##               ##
###################

function splash () {
clear
echo -e "\x1b[31m        ______            _________  _________     _____          _        _ _            ";
echo -e "\x1b[32m        |  ___|           |  _  \  \/  || ___ \   |_   _|        | |      | | |           ";
echo -e "\x1b[33m        | |_ _ __ ___  ___| | | | .  . || |_/ /     | | _ __  ___| |_ __ _| | | ___ _ __  ";
echo -e "\x1b[34m        |  _| '__/ _ \/ _ \ | | | |\/| ||    /      | || '_ \/ __| __/ _\` | | |/ _ \ '__|";
echo -e "\x1b[35m        | | | | |  __/  __/ |/ /| |  | || |\ \     _| || | | \__ \ || (_| | | |  __/ |    ";
echo -e "\x1b[36m        \_| |_|  \___|\___|___/ \_|  |_/\_| \_|    \___/_| |_|___/\__\__,_|_|_|\___|_|    ";
echo
echo -e "\x1b[37m                        This script Copyright OZ-DMR Networks © 2021                      ";
echo -e "\x1b[38m                      This script Copyright FRANCE-DMR Networks © 2021                    ";
echo -e "\x1b[39m                         This script Copyright FR86FB  Fred © 2021                        ";
echo
echo "                                          Version $version";
echo
}

function pre-install () {

# Pre-Install Setup

splash
echo Just doing some PRE-INSTALL setup ...
sleep 3

# Get Current IP addresses

intip="$(ip route get 1.1.1.1 | sed -n '/src/{s/.*src *\([^ ]*\).*/\1/p;q}')"
extip="$(curl  --silent ifconfig.me)"

# Set Parameters Defaults

s_id="0"
menu=""
serv_ip="127.0.0.1"
install="NOT SELECTED"
opb="62035-62085"
dockeropb="$opb:$opb"
uport="62031"
pword="passw0rd"
usepword="False"
dashboard="NOT SELECTED"
name="FreeDMR Server & HBMonv2 Dashboard Installer"

# Stop Services the Might be Running

if systemctl is-active --quiet docker.service; then
	systemctl stop docker.service && systemctl disable docker.service
fi

if systemctl is-active --quiet apache2.service; then
	systemctl stop apache2.service && systemctl disable apache2.service
fi

if systemctl is-active --quiet freedmr.service; then
	systemctl stop freedmr.service && systemctl disable freedmr.service
fi

if systemctl is-active --quiet hotspot_proxy.service; then
	systemctl stop hotspot_proxy.service && systemctl disable hotspot_proxy.service
fi

if systemctl is-active --quiet parrot.service; then
	systemctl stop parrot.service && systemctl disable parrot.service
fi

if systemctl is-active --quiet hbmon.service; then
	systemctl stop hbmon.service && systemctl disable hbmon.service
fi

systemctl daemon-reload

# Stop Containers the Might be Running

echo
echo Stopping Docker Containers that may Running
echo
docker kill $(docker ps -q)

# Removing Containers the Might be Exist

echo
echo Removing Docker Containers that exist
echo
docker rm $(docker ps -a -q)
docker rmi $(docker images -q)

# Install CURL GIT NET-TOOLS NMAP WGET WHOIS

if [ $(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get --assume-yes install curl;
fi

if [ $(dpkg-query -W -f='${Status}' git 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get --assume-yes install git;
fi

if [ $(dpkg-query -W -f='${Status}' net-tools 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get --assume-yes install net-tools;
fi

if [ $(dpkg-query -W -f='${Status}' nmap 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get --assume-yes install nmap;
fi

if [ $(dpkg-query -W -f='${Status}' wget 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get --assume-yes install wget;
fi

if [ $(dpkg-query -W -f='${Status}' whois 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  apt-get --assume-yes install whois;
fi
}

function welcome () {

# Welcome Screen

splash
echo "Welcome to the FreeDMR System installer. This script was written by Adrian (Ozzie) M0GLJ in an attempt to make the"
echo installation process loads easier for everyone. Please answer the questions as best you can. You will be able to
echo change them later by editing the config files that are install during this proccess. We also recommend installing 
echo FAIL2BAN to help secure your server.
echo
echo There are 4 Types of install that are available with this installer.
echo
echo -e "       • \x1b[33mDOCKER\x1b[37m    - FreeDMR Server and Dashboard"
echo -e "                                                 (Built into Docker Containers)"
echo
echo -e "       • \x1b[33mHYBRID\x1b[37m    - FreeDMR Server and Dashboard"
echo -e "                                                 (FreeDMR Server Built inside a Docker Container & HBMon Dashboard outside)"
echo
echo -e "       • \x1b[33mNORMAL\x1b[37m    - FreeDMR Server and Dashboard"
echo -e "                                                 (NO DOCKER Containers)"
echo
echo -e "       • \x1b[33mBRIDGE\x1b[37m    - FreeDMR BRIDGE Server and Dashboard Server"
echo -e "                                                 (Used for SPECIALISED BRIDGING) (NO DOCKER Containers)"
echo
echo -e "       • \x1b[33mDASHBOARD\x1b[37m - Dashboard Server ONLY"
echo -e "                                                 (NO DOCKER Containers)"
echo
echo -e "The \x1b[33mDOCKER\x1b[37m system is the recomended method to install the FreeDMR System, but it's your choice as to how you install."
echo 
echo -e "For more information about the \x1b[33mDOCKER\x1b[37m install, take a look at \x1b[33mhttps://gitlab.hacknix.net/hacknix/FreeDMR/-/wikis/home \x1b[37m"
echo 
read -p "                               Press any key to proceed with the install" -n1 -s
}

function setup () {
splash
echo
echo You can choose to install a DASHBOARD after you make your selection from the list below
echo
echo Please select which method you wish to use for this install ?
echo
echo
echo -e "                        D - \x1b[33mDOCKER\x1b[37m             H - \x1b[33mHYBRID\x1b[37m"
echo
echo -e "                        N - \x1b[33mNORMAL\x1b[37m             B - \x1b[33mBRIDGE\x1b[37m"
echo
echo -e "                        R - \x1b[33mDASHBOARD ONLY\x1b[37m     X - \x1b[33mEXIT\x1b[37m"
echo
echo

read -p "Please select which INSTALL you would like ?  D / H / N / B / R / X  : " menu

menu=${menu^^}

# Select DOCKER Server

if [[ $menu = "D" ]] ;then
	freedmr="Docker"
	docker_config
fi

# Select HYBRID Server

if [[ $menu = "H" ]] ;then
	freedmr="HYBRID"
	hybrid_config
fi

# Select NORMAL Server

if [[ $menu = "N" ]] ;then
	freedmr="NORMAL"
	normal_config
fi

# Select BRIDGE Server

if [[ $menu = "B" ]] ;then
	freedmr="BRIDGE"
	bridge_config
fi

# Select Dashboard ONLY

if [[ $menu = "R" ]] ;then
	freedmr="NOT INSTALLING"
	dashboard_config
fi

# Exit Script

if [[ $menu = "X" ]] ;then
	clear
	splash
	echo
	echo Thank you for using at FreeDMR Installer
	echo
	echo
	exit 1
fi

# Restart Selection for Invalid Entry

	echo
	echo
	echo
	echo
	echo -e "                    \x1b[33mPlease make a selection form the list above\x1b[37m"
	sleep 2
	setup
}

function logo () {

curl https://github.com/francedmr/HBMonv2/blob/main/html/img/logo.png/-/raw/main/logo.png -o /var/www/html/img/logo.png

chown -R www-data:www-data /var/www/html
}

function docker_config () {
clear
splash
echo
echo FreeDMR DOCKER Install Config
echo
docker_install
}

function hybrid_config () {
clear
splash
echo
echo FreeDMR HYBRID Install Config
echo
hybrid_install
}

function normal_config () {

# Set USER Access PORT

clear
splash
echo "Which access PORT would you like to set for USER HOTSPOT/REPEATER access"
echo
echo -e "The Default is PORT \x1b[33m62031\x1b[37m and the Permitted PORTS are \x1b[33m55550-55580\x1b[37m or \x1b[33m62030-62031\x1b[37m"
echo
read -p "Please enter the PORT number you would like to use?: " uport

if [[ ${uport} -gt 55549 && ${uport} -lt 55581 ]] || [[ ${uport} -gt 62029 && ${uport} -lt 62032 ]]; then 
	echo
	echo -e "Setting USER PORT:     \x1b[33m$uport\x1b[37m"
	echo
	echo Updating Install Instructions ...
	sleep 3
else
	uport="62031"
	echo
	echo Port selected is outside the allowed range.
	echo
	echo -e "Setting USER PORT:     \x1b[33m$uport\x1b[37m"
	echo
	echo Updating Install Instructions ...
	sleep 3
fi

# Set Password

splash
echo
echo "Choose a PASSWORD you wish to DEFINE for USER MMDVM HOTSPOT's/REPEATER's to access this FreeDMR Server"
echo
echo -e "Just press ENTER to set the default password:     \x1b[33mpassw0rd\x1b[37m"
echo
read -p "Enter 'NONE' (UPPERCASE) to use without a password for USER ACCESS : " pword
pword=${pword:-passw0rd}
usepword="False"

if [[ $pword -ne "NONE" ]] && [[ $pword -ne "none" ]]; then
	if [ ${#pword} -le 7 ]; then 
		echo
		echo "Password length need to 8 Characters or more" ;
		echo
		sleep 2
		echo Restarting NORMAL Install
		echo
		sleep 3
		normal_config
	fi
fi

echo
echo -e "USER ACCESS PASSWORD SET TO:     \x1b[33m" $pword
echo
echo -e "\x1b[37mUpdating Install Instructions ..."

if [[ $pword == "NONE" ]] && [[ $pword == "none" ]]; then
	pword=""
	usepword="True"
fi

sleep 3
	
# Install DASHBOARD (YES or NO)

splash
echo
echo Would you like to install a DASHBOARD with your FreeDMR NORMAL install ?
echo

read -p "Please select which you would like ?  Y / N  : " install

install=${install^^}

if [[ $install = "Y" ]] ;then
	dashboard="YES"
	echo
	echo Updating Install Instructions ...
	sleep 3
	clear
	splash
	echo
	echo "                                  HBMonv2 DASHBOARD Install"
	echo
	echo
	read -p "What is the name of your SERVER / NETWORK: " name
	name="${name:=FreeDMR Server Installer brought to you by OZ-DMR Networks}"
	echo
	echo -e "Setting SERVER NAME FOR DASHBOARD:     \x1b[33m$name\x1b[37m"
	echo
	echo Updating Install Instructions ...
	sleep 3
	normal_install
fi

if [[ $install = "N" ]] ;then
	dashboard=""
	echo
	echo Updating Install Instructions ...
	sleep 3
	normal_install
fi
	echo
	echo
	echo -e "                    \x1b[33mPlease make a selection form the list above\x1b[37m"
	echo
	echo -e "                    \x1b[33mStarting Install Selection from the Begining\x1b[37m"
	sleep 2
	normal_config
}

function bridge_config () {
clear
splash
echo
echo FreeDMR BRIDGE Install Config

# Install DASHBOARD (YES or NO)

echo
echo Would you like to install a DASHBOARD with your FreeDMR NORMAL install ?
echo

read -p "Please select which you would like ?  Y / N  : " install

install=${install^^}

if [[ $install = "Y" ]] ;then
	dashboard="YES"
	echo
	echo Updating Install Instructions ...
	sleep 3
	clear
	splash
	echo
	echo "                                  HBMonv2 DASHBOARD Install"
	echo
	echo
	read -p "What is the name of your SERVER / NETWORK: " name
	name="${name:=FreeDMR Bridge Server Installer brought to you by OZ-DMR Networks}"
	echo
	echo -e "Setting SERVER NAME FOR DASHBOARD:     \x1b[33m$name\x1b[37m"
	echo
	echo Updating Install Instructions ...
	sleep 3
	bridge_install
fi

if [[ $install = "N" ]] ;then
	dashboard="NO"
	echo
	echo Updating Install Instructions ...
	sleep 3
	bridge_install
fi
	echo
	echo
	echo -e "                    \x1b[33mPlease make a selection form the list above\x1b[37m"
	echo
	echo -e "                    \x1b[33mStarting Install Selection from the Begining\x1b[37m"
	sleep 2
	bridge_config
}

function dashboard_config () {

dashboard="HBMonv2 Install"
uport="NOT USED"
pword="NOT USED"

clear
splash
echo
read -p "What is the name of your SERVER / NETWORK: " name
name="${name:=HBMonv2 Dashboard Installer brought to you by OZ-DMR Networks}"
echo
echo
echo -e "Setting SERVER NAME FOR DASHBOARD:     \x1b[33m$name\x1b[37m"
echo
echo Updating Install Instructions ...
sleep 3
splash
echo
echo "                                  HBMonv2 DASHBOARD ONLY Install"
echo
echo
echo Please ENTER an IP ADDRESS for the location of the FreeDMR SERVER. If the FreeDMR Server is located 
echo on the same machine, please enter 127.0.0.1
echo
echo If the FreeDMR Server is on another machine please enter the IP ADDRESS where the server is located. 
echo
echo
echo -e "                                  Default location is \x1b[33m127.0.0.1\x1b[37m"
echo
echo
read -p "Please ENTER an IP ADDRESS: " serv_ip
serv_ip="${serv_ip:=127.0.0.1}"
echo
echo -e "Setting SERVER location:     \x1b[33m$serv_ip\x1b[37m"
echo
echo Updating Install Instructions ...
sleep 3
dashboard_install
exit 1
}

function docker_install () {
clear
splash
echo
echo Installing FreeDMR DOCKER Server
echo
echo Would you like to install a DASHBOARD with your FreeDMR DOCKER install ?
echo

read -p "Please select which you would like ?  Y / N  : " install

install=${install^^}

echo
echo Updating Install Instructions ...
sleep 3
	
if [[ $install = "Y" ]] ;then
clear
splash
echo
echo "Installing FreeDMR DOCKER and HBmonitor Dashboard Server's"
echo
echo Installing Required Packages...
apt-get -y install docker.io && 
apt-get -y install docker-compose &&
apt-get -y  install conntrack &&

echo '{ "userland-proxy": false}' > /etc/docker/daemon.json &&

echo
echo Restart Docker ...
systemctl restart docker &&

echo
echo Creating Config Directory...
mkdir /etc/freedmr &&
chmod 755 /etc/freedmr &&

echo
echo Creating json directory...
mkdir -p /etc/freedmr/json &&

echo
echo Obtaining json Files...
cd /etc/freedmr/json &&
curl https://www.france-dmr.fr/static/local_subscriber_ids.json -o subscriber_ids.json && 
curl https://www.france-dmr.fr/static/talkgroup_ids.json -o talkgroup_ids.json &&
curl https://www.france-dmr.fr/static/rptrs.json -o peer_ids.json &&
chmod -R 777 /etc/freedmr/json &&

clear
splash
echo
echo Installing FreeDMR Configuration File ... 
cat << EOF > /etc/freedmr/freedmr.cfg
[GLOBAL]
PATH: ./
PING_TIME: 10
MAX_MISSED: 3
USE_ACL: True
REG_ACL: DENY:0-100000
SUB_ACL: DENY:0-100000
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
GEN_STAT_BRIDGES: True
ALLOW_NULL_PASSPHRASE: True
ANNOUNCEMENT_LANGUAGES: fr_FR
SERVER_ID: 0
DATA_GATEWAY: False

[REPORTS]
REPORT: True
REPORT_INTERVAL: 60
REPORT_PORT: 4321
REPORT_CLIENTS: *

[LOGGER]
LOG_FILE: freedmr.log
LOG_HANDLERS: file-timed
LOG_LEVEL: INFO
LOG_NAME: FreeDMR

[ALIASES]
TRY_DOWNLOAD: True
PATH: ./
PEER_FILE: peer_ids.json
SUBSCRIBER_FILE: subscriber_ids.json
TGID_FILE: talkgroup_ids.json
PEER_URL: https://www.france-dmr.fr/static/rptrs.json
SUBSCRIBER_URL: https://www.france-dmr.fr/static/local_subscriber_ids.json
TGID_URL: TGID_URL: https://www.france-dmr.fr/static/talkgroup_ids.json
STALE_DAYS: 7

[MYSQL]
USE_MYSQL: False
USER: hblink
PASS: mypassword
DB: hblink
SERVER: 127.0.0.1
PORT: 3306
TABLE: repeaters

[OBP-TEST]
MODE: OPENBRIDGE
ENABLED: False
IP:
PORT: 62044
NETWORK_ID: 1
PASSPHRASE: mypass
TARGET_IP: 
TARGET_PORT: 62044
USE_ACL: True
SUB_ACL: DENY:1
TGID_ACL: PERMIT:ALL
RELAX_CHECKS: True
ENHANCED_OBP: True

[SYSTEM]
MODE: MASTER
ENABLED: True
REPEAT: True
MAX_PEERS: 1
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54000
PASSPHRASE: passw0rd
GROUP_HANGTIME: 5
USE_ACL: True
REG_ACL: DENY:1
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
DEFAULT_UA_TIMER: 10
SINGLE_MODE: True
VOICE_IDENT: True
TS1_STATIC:
TS2_STATIC:
DEFAULT_REFLECTOR: 0
ANNOUNCEMENT_LANGUAGE: fr_FR
GENERATOR: 100

[D-APRS]
MODE: MASTER
ENABLED: True
REPEAT: True
MAX_PEERS: 1
EXPORT_AMBE: False
IP:
PORT: 52555
PASSPHRASE:
GROUP_HANGTIME: 0
USE_ACL: True
REG_ACL: DENY:1
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
DEFAULT_UA_TIMER: 10
SINGLE_MODE: False
VOICE_IDENT: False
TS1_STATIC:
TS2_STATIC:
DEFAULT_REFLECTOR: 0
GENERATOR: 0
ANNOUNCEMENT_LANGUAGE: fr_FR

[ECHO]
MODE: PEER
ENABLED: True
LOOSE: False
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54916
MASTER_IP: 127.0.0.1
MASTER_PORT: 54915
PASSPHRASE: passw0rd
CALLSIGN: ECHO
RADIO_ID: 1000001
RX_FREQ: 000000000
TX_FREQ: 000000000
TX_POWER: 0
COLORCODE: 1
SLOTS: 1
LATITUDE: 00.0000
LONGITUDE: 000.0000
HEIGHT: 0
LOCATION: Francedmr
DESCRIPTION: ECHO
URL: www.france-dmr.fr
SOFTWARE_ID: 20170620
PACKAGE_ID: MMDVM_FreeDMR
GROUP_HANGTIME: 5
OPTIONS:
USE_ACL: True
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
ANNOUNCEMENT_LANGUAGE: fr_FR
EOF

echo
echo Installing FreeDMR Rules File ...
echo "BRIDGES = {'9990': [{'SYSTEM': 'ECHO', 'TS': 2, 'TGID': 9990, 'ACTIVE': True, 'TIMEOUT': 2, 'TO_TYPE': 'NONE', 'ON': [], 'OFF': [], 'RESET': []},]}" > /etc/freedmr/rules.py &&

echo
echo Set Permission ...
chown -R 54000 /etc/freedmr &&

echo
echo Setup logging...
mkdir -p /var/log/freedmr &&
touch /var/log/freedmr/freedmr.log &&
chown -R 54000 /var/log/freedmr &&
mkdir -p /var/log/FreeDMRmonitor &&
touch /var/log/FreeDMRmonitor/lastheard.log &&
touch /var/log/FreeDMRmonitor/hbmon.log &&
chown -R 54001 /var/log/FreeDMRmonitor &&

cat << EOF > /etc/freedmr/docker-compose.yml
###############################################################################
# Copyright (C) 2020 Simon Adlem, G7RZU <g7rzu@gb7fr.org.uk>  
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software Foundation,
#   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
###############################################################################

version: '2.4'
services:
    freedmr:
        container_name: freedmr
        cpu_shares: 1024
        mem_reservation: 600m
        volumes:
            - '/etc/freedmr/freedmr.cfg:/opt/freedmr/freedmr.cfg'
            - '/var/log/freedmr/freedmr.log:/opt/freedmr/freedmr.log'
            - '/etc/freedmr/rules.py:/opt/freedmr/rules.py'
            #Write JSON files outside of container
            - '/etc/freedmr/json/talkgroup_ids.json:/opt/freedmr/talkgroup_ids.json'
            - '/etc/freedmr/json/subscriber_ids.json:/opt/freedmr/subscriber_ids.json'
            - '/etc/freedmr/json/peer_ids.json:/opt/freedmr/peer_ids.json'
        ports:
            - '62031:62031/udp'
            #Change the below to inlude ports used for your OBP(s)
            - '$dockeropb/udp'
        image: 'hacknix/freedmr:latest'
        restart: "unless-stopped"
        networks:
           app_net:
             ipv4_address: 172.16.238.10
        #Control parameters inside container
        environment:
            #IPV6 support 
            - FDPROXY_IPV6=0
            #Display connection stats in log
            - FDPROXY_STATS=1
            #Display conneting client info in log
            - FDPROXY_CLIENTINFO=1
            #Debug HBP session in log (lots of data!!)
            - FDPROXY_DEBUG=0
            #Override proxy external port
            #- FDPROXY_LISTENPORT=62031
        read_only: "true"

    ipv6nat:
        container_name: ipv6nat
        image: 'robbertkl/ipv6nat'
        volumes:
            - '/var/run/docker.sock:/var/run/docker.sock:ro'
            - '/lib/modules:/lib/modules:ro'
        privileged: "true"
        network_mode: "host"
        restart: "unless-stopped"

    freedmrmon:
        container_name: freedmrmon
        cpu_shares: 512
        depends_on:
            - freedmr
        volumes:
            #This should be kept to a manageable size from
            #cron or logrotate outisde of the container.
            - '/var/log/FreeDMRmonitor/lastheard.log:/opt/FreeDMRmonitor/log/lastheard.log'
            - '/var/log/FreeDMRmonitor/hbmon.log:/opt/FreeDMRmonitor/log/hbmon.log'
            #Write JSON files outside of container
            - '/etc/freedmr/json/talkgroup_ids.json:/opt/FreeDMRmonitor/talkgroup_ids.json'
            - '/etc/freedmr/json/subscriber_ids.json:/opt/FreeDMRmonitor/subscriber_ids.json'
            - '/etc/freedmr/json/peer_ids.json:/opt/FreeDMRmonitor/peer_ids.json'

        #Override config file
        #    - '/etc/freedmr/config.py:/opt/FreeDMRmonitor/config.py'
        ports:
            - '9000:9000/tcp'
        image: 'hacknix/freedmrmonitor:latest'
        restart: "unless-stopped"
        networks:
           app_net:
             ipv4_address: 172.16.238.20
     
    freedmrmonpache:
        container_name: freedmrmonapache
        cpu_shares: 512
        depends_on:
             - freedmrmon
        #Use to override html files
        #And images
        #volumes:
        #    - '/var/www/html/:/var/www/html/'
        #    - '/var/www/html/images/:/var/www/html/images/'
        ports:
            - '80:80/tcp'
        image: hacknix/freedmrmonitor-apache:latest
        restart: "unless-stopped"
        networks:
           app_net:
             ipv4_address: 172.16.238.30

networks:
  app_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.16.238.0/24
          gateway: 172.16.238.1
EOF

cat << EOF > /etc/cron.daily/lastheard
#!/bin/bash
mv /var/log/FreeDMRmonitor/lastheard.log /var/log/FreeDMRmonitor/lastheard.log.save
/usr/bin/tail -150 /var/log/FreeDMRmonitor/lastheard.log.save > /var/log/FreeDMRmonitor/lastheard.log
mv /var/log/FreeDMRmonitor/lastheard.log /var/log/FreeDMRmonitor/lastheard.log.save
/usr/bin/tail -150 /var/log/FreeDMRmonitor/lastheard.log.save > /var/log/FreeDMRmonitor/lastheard.log
EOF
chmod 755 /etc/cron.daily/lastheard

clear
splash
echo
echo Starting FreeDMR container...
docker-compose up -d
sleep 3
fi

if [[ $install = "N" ]] ;then
clear
splash
echo
echo Installing FreeDMR DOCKER Server
echo
echo Installing Required Packages...
apt-get -y install docker.io && 
apt-get -y install docker-compose &&
apt-get -y  install conntrack &&

echo '{ "userland-proxy": false}' > /etc/docker/daemon.json &&

echo
echo Restart Docker ...
systemctl restart docker &&

echo
echo Creating Config Directory...
mkdir /etc/freedmr &&
chmod 755 /etc/freedmr &&

echo
echo Creating json Directory...
mkdir -p /etc/freedmr/json &&

echo
echo Downloading json Files...
cd /etc/freedmr/json &&
curl https://www.france-dmr.fr/static/local_subscriber_ids.json -o subscriber_ids.json &&
curl https://www.france-dmr.fr/static/talkgroup_ids.json -o talkgroup_ids.json &&
curl https://www.france-dmr.fr/static/rptrs.json -o peer_ids.json &&
chmod -R 777 /etc/freedmr/json &&

clear
splash
echo
echo Installing FreeDMR Configuration File ... 
cat << EOF > /etc/freedmr/freedmr.cfg
[GLOBAL]
PATH: ./
PING_TIME: 10
MAX_MISSED: 3
USE_ACL: True
REG_ACL: DENY:0-100000
SUB_ACL: DENY:0-100000
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
GEN_STAT_BRIDGES: True
ALLOW_NULL_PASSPHRASE: True
ANNOUNCEMENT_LANGUAGES: fr_FR
SERVER_ID: 0
DATA_GATEWAY: False

[REPORTS]
REPORT: True
REPORT_INTERVAL: 60
REPORT_PORT: 4321
REPORT_CLIENTS: *

[LOGGER]
LOG_FILE: freedmr.log
LOG_HANDLERS: file-timed
LOG_LEVEL: INFO
LOG_NAME: FreeDMR

[ALIASES]
TRY_DOWNLOAD: True
PATH: ./
PEER_FILE: peer_ids.json
SUBSCRIBER_FILE: subscriber_ids.json
TGID_FILE: talkgroup_ids.json
PEER_URL: https://www.france-dmr.fr/static/rptrs.json
SUBSCRIBER_URL: https://www.france-dmr.fr/static/local_subscriber_ids.json
TGID_URL: TGID_URL: https://www.france-dmr.fr/static/talkgroup_ids.json
STALE_DAYS: 7

[MYSQL]
USE_MYSQL: False
USER: hblink
PASS: mypassword
DB: hblink
SERVER: 127.0.0.1
PORT: 3306
TABLE: repeaters

[OBP-TEST]
MODE: OPENBRIDGE
ENABLED: False
IP:
PORT: 62044
NETWORK_ID: 1
PASSPHRASE: mypass
TARGET_IP: 
TARGET_PORT: 62044
USE_ACL: True
SUB_ACL: DENY:1
TGID_ACL: PERMIT:ALL
RELAX_CHECKS: True
ENHANCED_OBP: True

[SYSTEM]
MODE: MASTER
ENABLED: True
REPEAT: True
MAX_PEERS: 1
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54000
PASSPHRASE: passw0rd
GROUP_HANGTIME: 5
USE_ACL: True
REG_ACL: DENY:1
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
DEFAULT_UA_TIMER: 10
SINGLE_MODE: True
VOICE_IDENT: True
TS1_STATIC:
TS2_STATIC:
DEFAULT_REFLECTOR: 0
ANNOUNCEMENT_LANGUAGE: fr_FR
GENERATOR: 100

[ECHO]
MODE: PEER
ENABLED: True
LOOSE: False
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54916
MASTER_IP: 127.0.0.1
MASTER_PORT: 54915
PASSPHRASE: passw0rd
CALLSIGN: ECHO
RADIO_ID: 1000001
RX_FREQ: 000000000
TX_FREQ: 000000000
TX_POWER: 0
COLORCODE: 1
SLOTS: 1
LATITUDE: 00.0000
LONGITUDE: 000.0000
HEIGHT: 0
LOCATION: Francedmr
DESCRIPTION: ECHO
URL: www.france-dmr.fr
SOFTWARE_ID: 20170620
PACKAGE_ID: MMDVM_FreeDMR
GROUP_HANGTIME: 5
OPTIONS:
USE_ACL: True
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
ANNOUNCEMENT_LANGUAGE: fr_FR
EOF

echo
echo Installing FreeDMR Rules File ...
echo "BRIDGES = {'9990': [{'SYSTEM': 'ECHO', 'TS': 2, 'TGID': 9990, 'ACTIVE': True, 'TIMEOUT': 2, 'TO_TYPE': 'NONE', 'ON': [], 'OFF': [], 'RESET': []},]}" > /etc/freedmr/rules.py &&

echo
echo Setting File Permission ...
chown -R 54000 /etc/freedmr &&

echo
echo Setup FreeDMR Logging...
mkdir -p /var/log/freedmr &&
touch /var/log/freedmr/freedmr.log &&
chown -R 54000 /var/log/freedmr &&

cat << EOF > /etc/freedmr/docker-compose.yml
###############################################################################
# Copyright (C) 2020 Simon Adlem, G7RZU <g7rzu@gb7fr.org.uk>  
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software Foundation,
#   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
###############################################################################

version: '2.4'
services:
    freedmr:
        container_name: freedmr
        cpu_shares: 1024
        mem_reservation: 600m
        volumes:
            - '/etc/freedmr/freedmr.cfg:/opt/freedmr/freedmr.cfg'
            - '/var/log/freedmr/freedmr.log:/opt/freedmr/freedmr.log'
            - '/etc/freedmr/rules.py:/opt/freedmr/rules.py'
            #Write JSON files outside of container
            - '/etc/freedmr/json/talkgroup_ids.json:/opt/freedmr/talkgroup_ids.json'
            - '/etc/freedmr/json/subscriber_ids.json:/opt/freedmr/subscriber_ids.json'
            - '/etc/freedmr/json/peer_ids.json:/opt/freedmr/peer_ids.json'
        ports:
            - '62031:62031/udp'
            #Change the below to inlude ports used for your OBP(s)
            - '$dockeropb/udp'
        image: 'hacknix/freedmr:latest
        restart: "unless-stopped"
        networks:
           app_net:
             ipv4_address: 172.16.238.10
        #Control parameters inside container
        environment:
            #IPV6 support 
            - FDPROXY_IPV6=0
            #Display connection stats in log
            - FDPROXY_STATS=1
            #Display conneting client info in log
            - FDPROXY_CLIENTINFO=1
            #Debug HBP session in log (lots of data!!)
            - FDPROXY_DEBUG=0
            #Override proxy external port
            #- FDPROXY_LISTENPORT=62031
        read_only: "true"

    ipv6nat:
        container_name: ipv6nat
        image: 'robbertkl/ipv6nat'
        volumes:
            - '/var/run/docker.sock:/var/run/docker.sock:ro'
            - '/lib/modules:/lib/modules:ro'
        privileged: "true"
        network_mode: "host"
        restart: "unless-stopped"

networks:
  app_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.16.238.0/24
          gateway: 172.16.238.1
EOF

clear
splash
echo
echo Starting FreeDMR container...
docker-compose up -d
sleep 3
fi
uport="62031"
report
}

function hybrid_install () {

clear
splash
echo
echo Installing FreeDMR DOCKER Server
echo
echo Installing Required Packages ...
apt-get -y install docker.io
apt-get -y install docker-compose
apt-get -y  install conntrack
apt-get install python3-pip

echo '{ "userland-proxy": false}' > /etc/docker/daemon.json

echo
echo Restart Docker ...
systemctl restart docker

echo
echo Creating Config Directory ...
mkdir /etc/freedmr
chmod 755 /etc/freedmr

echo
echo Creating json Directory ...
mkdir -p /etc/freedmr/json

echo
echo Downloading json Files ...
cd /etc/freedmr/json
curl https://www.france-dmr.fr/staticlocal_subscriber_ids.json -o subscriber_ids.json
curl https://www.france-dmr.fr/static/talkgroup_ids.json -o talkgroup_ids.json
curl https://www.france-dmr.fr/static/rptrs.json -o peer_ids.json
chmod -R 777 /etc/freedmr/json

echo
echo Installing FreeDMR Configuration File ... 
cat << EOF > /etc/freedmr/freedmr.cfg
[GLOBAL]
PATH: ./
PING_TIME: 10
MAX_MISSED: 3
USE_ACL: True
REG_ACL: DENY:0-100000
SUB_ACL: DENY:0-100000
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
GEN_STAT_BRIDGES: True
ALLOW_NULL_PASSPHRASE: True
ANNOUNCEMENT_LANGUAGES: fr_FR
SERVER_ID: 0
DATA_GATEWAY: False

[REPORTS]
REPORT: True
REPORT_INTERVAL: 60
REPORT_PORT: 4321
REPORT_CLIENTS: *

[LOGGER]
LOG_FILE: freedmr.log
LOG_HANDLERS: file-timed
LOG_LEVEL: INFO
LOG_NAME: FreeDMR

[ALIASES]
TRY_DOWNLOAD: True
PATH: ./
PEER_FILE: peer_ids.json
SUBSCRIBER_FILE: subscriber_ids.json
TGID_FILE: talkgroup_ids.json
PEER_URL: https://www.france-dmr.fr/static/rptrs.json
SUBSCRIBER_URL: https://www.france-dmr.fr/static/local_subscriber_ids.json
TGID_URL: TGID_URL: https://www.france-dmr.fr/static/talkgroup_ids.json
STALE_DAYS: 7

[MYSQL]
USE_MYSQL: False
USER: hblink
PASS: mypassword
DB: hblink
SERVER: 127.0.0.1
PORT: 3306
TABLE: repeaters

[OBP-TEST]
MODE: OPENBRIDGE
ENABLED: False
IP:
PORT: 62044
NETWORK_ID: 1
PASSPHRASE: mypass
TARGET_IP: 
TARGET_PORT: 62044
USE_ACL: True
SUB_ACL: DENY:1
TGID_ACL: PERMIT:ALL
RELAX_CHECKS: True
ENHANCED_OBP: True

[SYSTEM]
MODE: MASTER
ENABLED: True
REPEAT: True
MAX_PEERS: 1
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54000
PASSPHRASE: passw0rd
GROUP_HANGTIME: 5
USE_ACL: True
REG_ACL: DENY:1
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
DEFAULT_UA_TIMER: 10
SINGLE_MODE: True
VOICE_IDENT: True
TS1_STATIC:
TS2_STATIC:
DEFAULT_REFLECTOR: 0
ANNOUNCEMENT_LANGUAGE: fr_FR
GENERATOR: 100

[ECHO]
MODE: PEER
ENABLED: True
LOOSE: False
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54916
MASTER_IP: 127.0.0.1
MASTER_PORT: 54915
PASSPHRASE: passw0rd
CALLSIGN: ECHO
RADIO_ID: 1000001
RX_FREQ: 000000000
TX_FREQ: 000000000
TX_POWER: 0
COLORCODE: 1
SLOTS: 1
LATITUDE: 00.0000
LONGITUDE: 000.0000
HEIGHT: 0
LOCATION: Francedmr
DESCRIPTION: ECHO
URL: www.francedmr.fr
SOFTWARE_ID: 20170620
PACKAGE_ID: MMDVM_FreeDMR
GROUP_HANGTIME: 5
OPTIONS:
USE_ACL: True
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
ANNOUNCEMENT_LANGUAGE: fr_FR
EOF

echo
echo Installing FreeDMR Rules File ...
echo "BRIDGES = {'9990': [{'SYSTEM': 'ECHO', 'TS': 2, 'TGID': 9990, 'ACTIVE': True, 'TIMEOUT': 2, 'TO_TYPE': 'NONE', 'ON': [], 'OFF': [], 'RESET': []},]}" > /etc/freedmr/rules.py

echo
echo Set Permission ...
chown -R 54000 /etc/freedmr

echo
echo Setup logging ...
mkdir -p /var/log/freedmr
touch /var/log/freedmr/freedmr.log
chown -R 54000 /var/log/freedmr

cat << EOF > /etc/freedmr/docker-compose.yml
###############################################################################
# Copyright (C) 2020 Simon Adlem, G7RZU <g7rzu@gb7fr.org.uk>  
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software Foundation,
#   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
###############################################################################

version: '2.4'
services:
    freedmr:
        container_name: freedmr
        cpu_shares: 1024
        mem_reservation: 600m
        volumes:
            - '/etc/freedmr/freedmr.cfg:/opt/freedmr/freedmr.cfg'
            - '/var/log/freedmr/freedmr.log:/opt/freedmr/freedmr.log'
            - '/etc/freedmr/rules.py:/opt/freedmr/rules.py'
            #Write JSON files outside of container
            - '/etc/freedmr/json/talkgroup_ids.json:/opt/freedmr/talkgroup_ids.json'
            - '/etc/freedmr/json/subscriber_ids.json:/opt/freedmr/subscriber_ids.json'
            - '/etc/freedmr/json/peer_ids.json:/opt/freedmr/peer_ids.json'
        ports:
            - '62031:62031/udp'
            #Change the below to inlude ports used for your OBP(s)
            - '$dockeropb/udp'
        image: 'hacknix/freedmr:latest'
        restart: "unless-stopped"
        networks:
           app_net:
             ipv4_address: 172.16.238.10
        #Control parameters inside container
        environment:
            #IPV6 support 
            - FDPROXY_IPV6=0
            #Display connection stats in log
            - FDPROXY_STATS=1
            #Display conneting client info in log
            - FDPROXY_CLIENTINFO=1
            #Debug HBP session in log (lots of data!!)
            - FDPROXY_DEBUG=0
            #Override proxy external port
            #- FDPROXY_LISTENPORT=62031
        read_only: "true"

    ipv6nat:
        container_name: ipv6nat
        image: 'robbertkl/ipv6nat'
        volumes:
            - '/var/run/docker.sock:/var/run/docker.sock:ro'
            - '/lib/modules:/lib/modules:ro'
        privileged: "true"
        network_mode: "host"
        restart: "unless-stopped"

networks:
  app_net:
    driver: bridge
    ipam:
      driver: default
      config:
        - subnet: 172.16.238.0/24
          gateway: 172.16.238.1
EOF

echo
echo
echo Starting FreeDMR container ...
docker-compose up -d
sleep 3

echo
sudo apt install conntrack tcpdump net-tools zip php apache2 -y

echo
sudo apt autoremove

echo
cd /opt
sudo rm -fR /opt/HBMonv2
git clone https://github.com/francedmr/HBMonv2.git

echo
cd /opt/HBMonv2
bash install.sh

# HBMonv2 Config file

cat << EOF > /opt/HBMonv2/config.py
CONFIG_INC      = True                           # Include HBlink stats
HOMEBREW_INC    = True                           # Display Homebrew Peers status
LASTHEARD_INC   = True                           # Display lastheard table on main page
BRIDGES_INC     = False                          # Display Bridge status and button
EMPTY_MASTERS   = False                          # Display Enable (True) or DISABLE (False) empty masters in status
#
HBLINK_IP       = '172.16.238.10'                # HBlink's IP Address
HBLINK_PORT     = 4321                           # HBlink's TCP reporting socket
FREQUENCY       = 10                             # Frequency to push updates to web clients
CLIENT_TIMEOUT  = 0                              # Clients are timed out after this many seconds, 0 to disable

# Generally you don't need to use this but
# if you don't want to show in lastherad received traffic from OBP link put NETWORK ID 
# for example: "260210,260211,260212"
OPB_FILTER = ""

# Files and stuff for loading alias files for mapping numbers to names
PATH            = './'                           # MUST END IN '/'
PEER_FILE       = 'peer_ids.json'                # Will auto-download 
SUBSCRIBER_FILE = 'subscriber_ids.json'          # Will auto-download 
TGID_FILE       = 'talkgroup_ids.json'           # User provided
LOCAL_SUB_FILE  = 'local_subscriber_ids.json'    # User provided (optional, leave '' if you don't use it)
LOCAL_PEER_FILE = 'local_peer_ids.json'          # User provided (optional, leave '' if you don't use it)
LOCAL_TGID_FILE = 'local_talkgroup_ids.json'     # User provided (optional, leave '' if you don't use it)
FILE_RELOAD     = 1                              # Number of days before we reload DMR-MARC database files
PEER_URL        = 'https://www.france-dmr.fr/static/rptrs.json'
SUBSCRIBER_URL  = 'https://www.france-dmr.fr/static/users.json'

# Settings for log files
LOG_PATH        = '/var/log/freedmr/'            # MUST END IN '/'
LOG_NAME        = 'hbmon.log'
EOF

# Dashboard Config file

cat << EOF > /opt/HBMonv2/html/include/config.php
<?php

// Report all errors except E_NOTICE
error_reporting(E_ALL & ~E_NOTICE);

// Name of the monitored Dashboard
define("REPORT_NAME","$name");

// Height of Server Activity window: 45px; 1 row, 60px 2 rows, 80px 3 rows
define("HEIGHT_ACTIVITY","45px");

//
// Theme colors define
//
// Green 
//define("THEME_COLOR","background-color:#4a8f3c;color:white;");

// Blue 1
//define("THEME_COLOR","background-color:#2A659A;color:white;");

// Blue 2
//define("THEME_COLOR","background-color:#43A6DF;color:white;");

// Blue Gradient 1
define("THEME_COLOR","background-image: linear-gradient(to bottom, #337ab7 0%, #265a88 100%);color:white;");

// Blue Gradient 2
//define("THEME_COLOR","background-image: linear-gradient(to bottom, #3333cc 0%, #265a88 100%);color:white;");

// Red Gradient
//define("THEME_COLOR","background-image:linear-gradient(0deg, rgba(251,0,0,1) 0%, rgba(255,131,131,1) 50%, rgba(255,255,255,1) 100%);color:black;");

// Grey Gradient 
//define("THEME_COLOR","background-image: linear-gradient(to bottom, #3b3b3b 10%, #808080 100%);color:white;");

// Green Gradient 
//define("THEME_COLOR","background-image:linear-gradient(to bottom right,#d0e98d, #4e6b00);color:black;");
//

?>
EOF

# Move HTML files and restart Apache2

rm -fR /var/www/html && mkdir /var/www/html
cp -r /opt/HBMonv2/html /var/www/

# Setup OZ-DMR logo

logo

# Restart Apache2 Web Server

echo
systemctl restart apache2.service

# Setup Last Heard

cat << EOF > /etc/cron.daily/lastheard
#!/bin/bash
mv /var/log/freedmr/lastheard.log /opt/HBMonv2/log/lastheard.log.save
/usr/bin/tail -250 /opt/HBMonv2/log/lastheard.log.save > /opt/HBMonv2/log/lastheard.log
mv /var/log/freedmr/lastheard.log /opt/HBMonv2/log/lastheard.log.save
/usr/bin/tail -250 /opt/HBMonv2/log/lastheard.log.save > /opt/HBMonv2/log/lastheard.log
EOF

chmod +x /etc/cron.daily/lastheard

# Create System Unit Files

cd /opt/HBMonv2

# Remove OLD Symlink files and Create NEW symlinks for each system unit file for each service

if [ ! -f /etc/systemd/system/hbmon.service ]; then
	ln -s /opt/HBMonv2/utils/hbmon.service /etc/systemd/system/hbmon.service
fi

echo
sudo systemctl daemon-reload

# Enable & Start system unit files for each service

echo
systemctl enable hbmon.service && systemctl restart hbmon.service
report
uport="62031"
report
}

function normal_install () {

# Install Required APP Dependencies

cd /opt

if [[ dashboard="YES" ]]; then
	dashboard="and HBMonv2 DASHBOARD"
fi

splash
echo
echo "Installing FreeDMR Server $dashboard"

if [[ dashboard="and HBMonv2 DASHBOARD" ]]; then
	dashboard="YES"
fi

echo
echo "Updating the OS, Installing Required Packages and Removing File not Required ..."
echo
sudo apt install conntrack tcpdump net-tools zip -y
sudo apt install python3-pip

if [[ dashboard="YES" ]]; then
	sudo apt install php apache2 -y
fi

sudo apt autoremove

# Create directories, log & other files

sudo mkdir -p /etc/freedmr
sudo mkdir -p /var/log/freedmr
sudo touch /var/log/freedmr/freedmr.log

if [[ dashboard="YES" ]]; then
	sudo touch /var/log/freedmr/hbmon.log
fi

# Change to Install Directory

cd /opt

# Get FreeDMR GIT

cd /opt
sudo rm -fR /opt/FreeDMR
git clone https://github.com/francedmr/FreeDMR-Docker.git

# Get HBMonv2 GIT

if [[ dashboard="YES" ]]; then

	cd /opt
	sudo rm -fR /opt/HBMonv2
	git clone https://github.com/francedmr/HBMonv2.git
fi

# Get HBNet GIT

cd /opt
#sudo rm -fR /opt/FreeDMR
git clone https://github.com/m0glj/HBNet-GPS.git

echo
echo Creating FreeDMR Configuration File ... 
cat << EOF > /etc/freedmr/freedmr.cfg
[GLOBAL]
PATH: ./
PING_TIME: 10
MAX_MISSED: 3
USE_ACL: True
REG_ACL: DENY:0-100000
SUB_ACL: DENY:0-100000
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
GEN_STAT_BRIDGES: True
ALLOW_NULL_PASSPHRASE: $usepword
ANNOUNCEMENT_LANGUAGES: fr_FR
SERVER_ID: 0
DATA_GATEWAY: False

[REPORTS]
REPORT: True
REPORT_INTERVAL: 60
REPORT_PORT: 4321
REPORT_CLIENTS: *

[LOGGER]
LOG_FILE: freedmr.log
LOG_HANDLERS: file-timed
LOG_LEVEL: INFO
LOG_NAME: FreeDMR

[ALIASES]
TRY_DOWNLOAD: True
PATH: ./
PEER_FILE: peer_ids.json
SUBSCRIBER_FILE: subscriber_ids.json
TGID_FILE: talkgroup_ids.json
PEER_URL: https://www.france-dmr.fr/static/rptrs.json
SUBSCRIBER_URL: https://www.france-dmr.fr/static/local_subscriber_ids.json
TGID_URL: TGID_URL: https://www.france-dmr.fr/static/talkgroup_ids.json
STALE_DAYS: 7

[MYSQL]
USE_MYSQL: False
USER: hblink
PASS: mypassword
DB: hblink
SERVER: 127.0.0.1
PORT: 3306
TABLE: repeaters

[OBP-TEST]
MODE: OPENBRIDGE
ENABLED: False
IP:
PORT: 62044
NETWORK_ID: 1
PASSPHRASE: mypass
TARGET_IP: 
TARGET_PORT: 62044
USE_ACL: True
SUB_ACL: DENY:1
TGID_ACL: PERMIT:ALL
RELAX_CHECKS: True
ENHANCED_OBP: True

[SYSTEM]
MODE: MASTER
ENABLED: True
REPEAT: True
MAX_PEERS: 1
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54000
PASSPHRASE: $pword
GROUP_HANGTIME: 5
USE_ACL: True
REG_ACL: DENY:1
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
DEFAULT_UA_TIMER: 10
SINGLE_MODE: True
VOICE_IDENT: True
TS1_STATIC:
TS2_STATIC:
DEFAULT_REFLECTOR: 0
ANNOUNCEMENT_LANGUAGE: fr_FR
GENERATOR: 100

[ECHO]
MODE: PEER
ENABLED: True
LOOSE: False
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54916
MASTER_IP: 127.0.0.1
MASTER_PORT: 54915
PASSPHRASE: passw0rd
CALLSIGN: ECHO
RADIO_ID: 1000001
RX_FREQ: 000000000
TX_FREQ: 000000000
TX_POWER: 0
COLORCODE: 1
SLOTS: 1
LATITUDE: 00.0000
LONGITUDE: 000.0000
HEIGHT: 0
LOCATION: Francedmr
DESCRIPTION: ECHO
URL: www.france-dmr.fr
SOFTWARE_ID: 20170620
PACKAGE_ID: MMDVM_FreeDMR
GROUP_HANGTIME: 5
OPTIONS:
USE_ACL: True
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
ANNOUNCEMENT_LANGUAGE: fr_FR
EOF

echo
echo Installing FreeDMR Rules File ...
echo "BRIDGES = {'9990': [{'SYSTEM': 'ECHO', 'TS': 2, 'TGID': 9990, 'ACTIVE': True, 'TIMEOUT': 2, 'TO_TYPE': 'NONE', 'ON': [], 'OFF': [], 'RESET': []},]}" > /etc/freedmr/rules.py

# Configure the Hotspot_Proxy

cat << EOF > /opt/FreeDMR/hotspot_proxy_v2.py
###############################################################################
# Copyright (C) 2020 Simon Adlem, G7RZU <g7rzu@gb7fr.org.uk>  
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software Foundation,
#   Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
###############################################################################

from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor, task
from time import time
from dmr_utils3.utils import int_id
import random
import ipaddress
import os
from setproctitle import setproctitle

# Does anybody read this stuff? There's a PEP somewhere that says I should do this.
__author__     = 'Simon Adlem - G7RZU'
__copyright__  = 'Copyright (c) Simon Adlem, G7RZU 2020,2021'
__credits__    = 'Jon Lee, G4TSN; Norman Williams, M6NBP; Christian, OA4DOA'
__license__    = 'GNU GPLv3'
__maintainer__ = 'Simon Adlem G7RZU'
__email__      = 'simon@gb7fr.org.uk'

def IsIPv4Address(ip):
    try:
        ipaddress.IPv4Address(ip)
        return True
    except ValueError as errorCode:
        pass
        return False
    
def IsIPv6Address(ip):
    try:
        ipaddress.IPv6Address(ip)
        return True
    except ValueError as errorCode:
        pass

class Proxy(DatagramProtocol):

    def __init__(self,Master,ListenPort,connTrack,blackList,Timeout,Debug,ClientInfo,DestportStart,DestPortEnd):
        self.master = Master
        self.connTrack = connTrack
        self.peerTrack = {}
        self.timeout = Timeout
        self.debug = Debug
        self.clientinfo = ClientInfo
        self.blackList = blackList
        self.destPortStart = DestportStart
        self.destPortEnd = DestPortEnd
        self.numPorts = DestPortEnd - DestportStart
        
        
    def reaper(self,_peer_id):
        if self.debug:
            print("dead",_peer_id)
        if self.clientinfo and _peer_id != b'\x00m@\xd7':
            print(f"Client: ID:{str(int_id(_peer_id)).rjust(9)} IP:{self.peerTrack[_peer_id]['shost'].rjust(15)} Port:{self.peerTrack[_peer_id]['sport']} Removed.")
        self.transport.write(b'RPTCL'+_peer_id, (self.master,self.peerTrack[_peer_id]['dport']))
        self.connTrack[self.peerTrack[_peer_id]['dport']] = False
        del self.peerTrack[_peer_id]
        

    def datagramReceived(self, data, addr):
        
        # HomeBrew Protocol Commands
        DMRD    = b'DMRD'
        DMRA    = b'DMRA'
        MSTCL   = b'MSTCL'
        MSTNAK  = b'MSTNAK'
        MSTPONG = b'MSTPONG'
        MSTN    = b'MSTN'
        MSTP    = b'MSTP'
        MSTC    = b'MSTC'
        RPTL    = b'RPTL'
        RPTPING = b'RPTPING'
        RPTCL   = b'RPTCL'
        RPTL    = b'RPTL'
        RPTACK  = b'RPTACK'
        RPTK    = b'RPTK'
        RPTC    = b'RPTC'
        RPTP    = b'RPTP'
        RPTA    = b'RPTA'
        RPTO    = b'RPTO'
        
        _peer_id = False
        
        host,port = addr
        
        nowtime = time()
        
        Debug = self.debug
        
        #If the packet comes from the master
        if host == self.master:
            _command = data[:4]
            
            if _command == DMRD:
                _peer_id = data[11:15]
            elif  _command == RPTA:
                    if data[6:10] in self.peerTrack:
                        _peer_id = data[6:10]
                    else:
                        _peer_id = self.connTrack[port]
            elif _command == MSTN:
                    _peer_id = data[6:10]
            elif _command == MSTP:
                    _peer_id = data[7:11]
            elif _command == MSTC:
                    _peer_id = data[5:9]
                
            if self.debug:
                print(data)
            if _peer_id in self.peerTrack:
                self.transport.write(data,(self.peerTrack[_peer_id]['shost'],self.peerTrack[_peer_id]['sport']))
                # Remove the client after send a MSTN or MSTC packet
                if _command in (MSTN,MSTC):
                    # Give time to the client for a reply to prevent port reassignment 
                    self.peerTrack[_peer_id]['timer'].reset(15)
 
            return
            
                   
        else:
            _command = data[:4]
            
            if _command == DMRD:                # DMRData -- encapsulated DMR data frame
                _peer_id = data[11:15]
            elif _command == DMRA:              # DMRAlias -- Talker Alias information
                _peer_id = data[4:8]
            elif _command == RPTL:              # RPTLogin -- a repeater wants to login
                _peer_id = data[4:8]
            elif _command == RPTK:              # Repeater has answered our login challenge
                _peer_id = data[4:8]
            elif _command == RPTC:              # Repeater is sending it's configuraiton OR disconnecting
                if data[:5] == RPTCL:           # Disconnect command
                    _peer_id = data[5:9]
                else:
                    _peer_id = data[4:8]        # Configure Command
            elif _command == RPTO:              # options
                _peer_id = data[4:8]
            elif _command == RPTP:              # RPTPing -- peer is pinging us
                _peer_id = data[7:11]
            else:
                return
            
            if _peer_id in self.peerTrack:
                _dport = self.peerTrack[_peer_id]['dport']
                self.peerTrack[_peer_id]['sport'] = port
                self.peerTrack[_peer_id]['shost'] = host
                self.transport.write(data, (self.master,_dport))
                self.peerTrack[_peer_id]['timer'].reset(self.timeout)
                if self.debug:
                    print(data)
                return

            else:
                if int_id(_peer_id) in self.blackList:
                    return   
                # Make a list with the available ports
                _ports_avail = [port for port in self.connTrack if not self.connTrack[port]]
                if len(_ports_avail) > 0:
                    _dport = random.choice(_ports_avail)
                else:
                    return
                self.connTrack[_dport] = _peer_id
                self.peerTrack[_peer_id] = {}
                self.peerTrack[_peer_id]['dport'] = _dport
                self.peerTrack[_peer_id]['sport'] = port
                self.peerTrack[_peer_id]['shost'] = host
                self.peerTrack[_peer_id]['timer'] = reactor.callLater(self.timeout,self.reaper,_peer_id)
                self.transport.write(data, (self.master,_dport))

                if self.clientinfo and _peer_id != b'\x00m@\xd7':
                    print(f'New client: ID:{str(int_id(_peer_id)).rjust(9)} IP:{host.rjust(15)} Port:{port}, assigned to port:{_dport}.')
                if self.debug:
                    print(data)
                return

if __name__ == '__main__':

#*** CONFIG HERE ***
    
    Master = "127.0.0.1"
    ListenPort = $uport
    # '' = all IPv4, '::' = all IPv4 and IPv6 (Dual Stack)
    ListenIP = ''
    DestportStart = 54000
    DestPortEnd = 54100
    Timeout = 30
    Stats = False
    Debug = False
    ClientInfo = False
    BlackList = [1234567]
    
#*******************
    
    #Set process title early
    setproctitle(__file__)
    
    #If IPv6 is enabled by enivornment variable...
    if ListenIP == '' and 'FDPROXY_IPV6' in os.environ and bool(os.environ['FDPROXY_IPV6']):
        ListenIP = '::'
        
    #Override static config from Environment
    if 'FDPROXY_STATS' in os.environ:
        Stats = bool(os.environ['FDPROXY_STATS'])
    if 'FDPROXY_DEBUG' in os.environ:
        Debug = bool(os.environ['FDPROXY_DEBUG'])
    if 'FDPROXY_CLIENTINFO' in os.environ:
        ClientInfo = bool(os.environ['FDPROXY_CLIENTINFO'])
    if 'FDPROXY_LISTENPORT' in os.environ:
        ListenPort = os.environ['FDPROXY_LISTENPORT']
        
    
    CONNTRACK = {}

    for port in range(DestportStart,DestPortEnd+1,1):
        CONNTRACK[port] = False
    
    #If we are listening IPv6 and Master is an IPv4 IPv4Address
    #IPv6ify the address. 
    if ListenIP == '::' and IsIPv4Address(Master):
        Master = '::ffff:' + Master

    reactor.listenUDP(ListenPort,Proxy(Master,ListenPort,CONNTRACK,BlackList,Timeout,Debug,ClientInfo,DestportStart,DestPortEnd),interface=ListenIP)

    def loopingErrHandle(failure):
        print('(GLOBAL) STOPPING REACTOR TO AVOID MEMORY LEAK: Unhandled error innowtimed loop.\n {}'.format(failure))
        reactor.stop()
        
    def stats():        
        count = 0
        nowtime = time()
        for port in CONNTRACK:
            if CONNTRACK[port]:
                count = count+1
                
        totalPorts = DestPortEnd - DestportStart
        freePorts = totalPorts - count
        
        print("{} ports out of {} in use ({} free)".format(count,totalPorts,freePorts))
        
    if Stats == True:
        stats_task = task.LoopingCall(stats)
        statsa = stats_task.start(30)
        statsa.addErrback(loopingErrHandle)

    reactor.run()
    
EOF

# Parrot Config file

cat << EOF > /etc/freedmr/playback.cfg
[GLOBAL]
PATH: ./
PING_TIME: 10
MAX_MISSED: 3
USE_ACL: True
REG_ACL: PERMIT:ALL
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
GEN_STAT_BRIDGES: False
ALLOW_NULL_PASSPHRASE: False
ANNOUNCEMENT_LANGUAGES: fr_FR
SERVER_ID: 9990
DATA_GATEWAY: False

[REPORTS]
REPORT: False
REPORT_INTERVAL: 60
REPORT_PORT: 4821
REPORT_CLIENTS: 127.0.0.1

[LOGGER]
LOG_FILE: /dev/null
LOG_HANDLERS: null
LOG_LEVEL: DEBUG
LOG_NAME: HBlink

[ALIASES]
TRY_DOWNLOAD: False
PATH: ./
PEER_FILE: peer_ids.json
SUBSCRIBER_FILE: subscriber_ids.json
TGID_FILE: talkgroup_ids.json
PEER_URL: https://www.france-dmr.fr/static/rptrs.json
SUBSCRIBER_URL: https://www.france-dmr.fr/static/users.json
TGID_URL: https://www.france-dmr.fr/static/talkgroup_ids.json
STALE_DAYS: 1

[MYSQL]
USE_MYSQL: False
USER: hblink
PASS: mypassword
DB: hblink
SERVER: 127.0.0.1
PORT: 3306
TABLE: repeaters

[OBP-TEST]
MODE: OPENBRIDGE
ENABLED: False
IP:
PORT: 62044
NETWORK_ID: 1
PASSPHRASE: mypass
TARGET_IP: 
TARGET_PORT: 62044
USE_ACL: True
SUB_ACL: DENY:1
TGID_ACL: PERMIT:ALL
RELAX_CHECKS: False

[PARROT]
MODE: MASTER
ENABLED: True
REPEAT: True
MAX_PEERS: 1
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54915
PASSPHRASE: passw0rd
GROUP_HANGTIME: 5
USE_ACL: True
REG_ACL: DENY:1
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
DEFAULT_UA_TIMER: 10
SINGLE_MODE: True
VOICE_IDENT: False
TS1_STATIC:
TS2_STATIC: 
DEFAULT_REFLECTOR: 0
GENERATOR: 1
ANNOUNCEMENT_LANGUAGE: fr_FR
EOF

if [[ dashboard="YES" ]]; then

# HBMonv2 Config file

if test -f "/opt/HBMonv2/config_SAMPLE.py"; then
    rm /opt/HBMonv2/config_SAMPLE.py
fi

cat << EOF > /opt/HBMonv2/config.py
CONFIG_INC      = True                           # Include HBlink stats
HOMEBREW_INC    = True                           # Display Homebrew Peers status
LASTHEARD_INC   = True                           # Display lastheard table on main page
BRIDGES_INC     = False                          # Display Bridge status and button
EMPTY_MASTERS   = False                          # Display Enable (True) or DISABLE (False) empty masters in status
#
HBLINK_IP       = '$serv_ip'                     # HBlink's IP Address
HBLINK_PORT     = 4321                           # HBlink's TCP reporting socket
FREQUENCY       = 10                             # Frequency to push updates to web clients
CLIENT_TIMEOUT  = 0                              # Clients are timed out after this many seconds, 0 to disable

# Generally you don't need to use this but
# if you don't want to show in lastherad received traffic from OBP link put NETWORK ID 
# for example: "260210,260211,260212"
OPB_FILTER = ""

# Files and stuff for loading alias files for mapping numbers to names
PATH            = './'                           # MUST END IN '/'
PEER_FILE       = 'peer_ids.json'                # Will auto-download 
SUBSCRIBER_FILE = 'subscriber_ids.json'          # Will auto-download 
TGID_FILE       = 'talkgroup_ids.json'           # User provided
LOCAL_SUB_FILE  = 'local_subscriber_ids.json'    # User provided (optional, leave '' if you don't use it)
LOCAL_PEER_FILE = 'local_peer_ids.json'          # User provided (optional, leave '' if you don't use it)
LOCAL_TGID_FILE = 'local_talkgroup_ids.json'     # User provided (optional, leave '' if you don't use it)
FILE_RELOAD     = 1                              # Number of days before we reload DMR-MARC database files
PEER_URL        = 'https://www.france-dmr.fr/static/rptrs.json'
SUBSCRIBER_URL  = 'https://www.france-dmr.fr/static/users.json'

# Settings for log files
LOG_PATH        = '/var/log/freedmr/'            # MUST END IN '/'
LOG_NAME        = 'hbmon.log'
EOF

# Dashboard Config file

cat << EOF > /opt/HBMonv2/html/include/config.php
<?php

// Report all errors except E_NOTICE
error_reporting(E_ALL & ~E_NOTICE);

// Name of the monitored Dashboard
define("REPORT_NAME","$name");

// Height of Server Activity window: 45px; 1 row, 60px 2 rows, 80px 3 rows
define("HEIGHT_ACTIVITY","45px");

//
// Theme colors define
//
// Green 
//define("THEME_COLOR","background-color:#4a8f3c;color:white;");

// Blue 1
//define("THEME_COLOR","background-color:#2A659A;color:white;");

// Blue 2
//define("THEME_COLOR","background-color:#43A6DF;color:white;");

// Blue Gradient 1
define("THEME_COLOR","background-image: linear-gradient(to bottom, #337ab7 0%, #265a88 100%);color:white;");

// Blue Gradient 2
//define("THEME_COLOR","background-image: linear-gradient(to bottom, #3333cc 0%, #265a88 100%);color:white;");

// Red Gradient
//define("THEME_COLOR","background-image:linear-gradient(0deg, rgba(251,0,0,1) 0%, rgba(255,131,131,1) 50%, rgba(255,255,255,1) 100%);color:black;");

// Grey Gradient 
//define("THEME_COLOR","background-image: linear-gradient(to bottom, #3b3b3b 10%, #808080 100%);color:white;");

// Green Gradient 
//define("THEME_COLOR","background-image:linear-gradient(to bottom right,#d0e98d, #4e6b00);color:black;");
//

?>
EOF

# Move HTML files and restart Apache2

rm -fR /var/www/html && mkdir /var/www/html
cp -r /opt/HBMonv2/html /var/www/

# Setup OZ-DMR logo

logo

# Restart Apache2 Web Server

systemctl restart apache2.service

# Setup Last Heard

cat << EOF > /etc/cron.daily/lastheard
#!/bin/bash
mv /var/log/freedmr/lastheard.log /opt/HBMonv2/log/lastheard.log.save
/usr/bin/tail -250 /opt/HBMonv2/log/lastheard.log.save > /opt/HBMonv2/log/lastheard.log
mv /var/log/freedmr/lastheard.log /opt/HBMonv2/log/lastheard.log.save
/usr/bin/tail -250 /opt/HBMonv2/log/lastheard.log.save > /opt/HBMonv2/log/lastheard.log
EOF

chmod +x /etc/cron.daily/lastheard

fi

# Create System Unit Files

cat << EOF > /opt/FreeDMR/systemd-scripts/freedmr.service
[Unit]
Description=FreeDMR Server Service
After=multi-user.target

[Service]
StandardOutput=null
WorkingDirectory=/opt/FreeDMR
ExecStart=/usr/bin/python3 bridge_master.py -c /etc/freedmr/freedmr.cfg -r /etc/freedmr/rules.py
RestartSec=3
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /opt/FreeDMR/systemd-scripts/hotspot_proxy.service
[Unit]
Description= FreeDMR Hotspot Service 
After=syslog.target network.target

[Service]
WorkingDirectory=/opt/FreeDMR
ExecStart=/usr/bin/python3 hotspot_proxy_v2.py

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /opt/FreeDMR/systemd-scripts/parrot.service
[Unit]
Description=FreeDMR Parrot Service
After=multi-user.target

[Service]
WorkingDirectory=/opt/FreeDMR
ExecStart=/usr/bin/python3 /opt/FreeDMR/playback.py -c /etc/freedmr/playback.cfg

[Install]
WantedBy=multi-user.target
EOF

cd /opt/FreeDMR
bash install.sh
	
if [[ dashboard="YES" ]]; then
	cd /opt/HBMonv2
	bash install.sh
fi

# Remove OLD Symlink files and Create NEW symlinks for each system unit file for each service

[ -f /etc/systemd/system/freedmr.service ] && sudo rm /etc/systemd/system/freedmr.service
[ -f /etc/systemd/system/hotspot_proxy.service ] && sudo rm /etc/systemd/system/hotspot_proxy.service
[ -f /etc/systemd/system/parrot.service ] && sudo rm /etc/systemd/system/parrot.service
[ -f /etc/systemd/system/hbmon.service ] && sudo rm /etc/systemd/system/hbmon.service

if [ ! -f /etc/systemd/system/freedmr.service ]; then
	ln -s /opt/FreeDMR/systemd-scripts/freedmr.service /etc/systemd/system/freedmr.service
fi

if [ ! -f /etc/systemd/system/hotspot_proxy.service ]; then
	ln -s /opt/FreeDMR/systemd-scripts/hotspot_proxy.service /etc/systemd/system/hotspot_proxy.service
fi

if [ ! -f /etc/systemd/system/parrot.service ]; then
	ln -s /opt/FreeDMR/systemd-scripts/parrot.service /etc/systemd/system/parrot.service
fi

if [[ dashboard="YES" ]]; then
	if [ ! -f /etc/systemd/system/hbmon.service ]; then
		ln -s /opt/HBMonv2/utils/hbmon.service /etc/systemd/system/hbmon.service
	fi
fi

sudo systemctl daemon-reload

# Enable & Start system unit files for each service

systemctl enable freedmr.service && systemctl restart freedmr.service
systemctl enable hotspot_proxy.service && systemctl restart hotspot_proxy.service
systemctl enable parrot.service && systemctl restart parrot.service

if [[ dashboard="YES" ]]; then
systemctl enable hbmon.service && systemctl restart hbmon.service
fi
report
}

function bridge_install () {
clear
echo
echo FreeDMR BRIDGE Install 
echo
# Install Required APP Dependencies

cd /opt

if [[ dashboard="YES" ]]; then
	dashboard="and HBMonv2 DASHBOARD Server"
else
	dashboard=""
fi

splash
echo
echo "Installing FreeDMR BRIDGE Server $dashboard"
echo
echo "Updating the OS, Installing Required Packages and Removing Files not Required ..."
echo
sudo apt install conntrack tcpdump net-tools zip -y
sudo apt install python3-pip
sudo apt autoremove

if [[ dashboard="and HBMonv2 DASHBOARD Server" ]]; then
	dashboard="YES"
fi

if [[ dashboard="YES" ]]; then
	sudo apt install php apache2 -y
	sudo apt autoremove
fi

# Create directories, log & other files

sudo mkdir -p /etc/freedmr
sudo mkdir -p /var/log/freedmr
sudo touch /var/log/freedmr/freedmr.log

if [[ dashboard="YES" ]]; then
	sudo touch /var/log/freedmr/hbmon.log
fi

# Change to Install Directory

cd /opt

# Get FreeDMR GIT

cd /opt
sudo rm -fR /opt/FreeDMR
git clone https://github.com/francedmr/FreeDMR-Docker.git

# Get HBMonv2 GIT

if [[ dashboard="YES" ]]; then

	cd /opt
	sudo rm -fR /opt/HBMonv2
	git clone https://github.com/francedmr/HBMonv2.git
fi

echo
echo Creating FreeDMR Configuration File ... 
cat << EOF > /etc/freedmr/freedmr.cfg
[GLOBAL]
PATH: ./
PING_TIME: 10
MAX_MISSED: 3
USE_ACL: True
REG_ACL: DENY:0-100000
SUB_ACL: DENY:0-100000
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
GEN_STAT_BRIDGES: True
ALLOW_NULL_PASSPHRASE: $usepword
ANNOUNCEMENT_LANGUAGES: fr_FR
SERVER_ID: 0
DATA_GATEWAY: False

[REPORTS]
REPORT: True
REPORT_INTERVAL: 60
REPORT_PORT: 4321
REPORT_CLIENTS: *

[LOGGER]
LOG_FILE: freedmr.log
LOG_HANDLERS: file-timed
LOG_LEVEL: INFO
LOG_NAME: FreeDMR

[ALIASES]
TRY_DOWNLOAD: False
PATH: ./
PEER_FILE: peer_ids.json
SUBSCRIBER_FILE: subscriber_ids.json
TGID_FILE: talkgroup_ids.json
PEER_URL: https://www.france-dmr.fr/static/rptrs.json
SUBSCRIBER_URL: https://www.france-dmr.fr/static/local_subscriber_ids.json
TGID_URL: TGID_URL: https://www.france-dmr.fr/static/talkgroup_ids.json
STALE_DAYS: 7

[MYSQL]
USE_MYSQL: False
USER: hblink
PASS: mypassword
DB: hblink
SERVER: 127.0.0.1
PORT: 3306
TABLE: repeaters

[OBP-TEST]
MODE: OPENBRIDGE
ENABLED: False
IP:
PORT: 62044
NETWORK_ID: 1
PASSPHRASE: mypass
TARGET_IP: 
TARGET_PORT: 62044
USE_ACL: True
SUB_ACL: DENY:1
TGID_ACL: PERMIT:ALL
RELAX_CHECKS: True
ENHANCED_OBP: True

[SYSTEM]
MODE: MASTER
ENABLED: True
REPEAT: True
MAX_PEERS: 10
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54000
PASSPHRASE: passw0rd
GROUP_HANGTIME: 5
USE_ACL: True
REG_ACL: DENY:1
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
DEFAULT_UA_TIMER: 10
SINGLE_MODE: True
VOICE_IDENT: True
TS1_STATIC:
TS2_STATIC:
DEFAULT_REFLECTOR: 0
ANNOUNCEMENT_LANGUAGE: fr_FR
GENERATOR: 100

[ECHO]
MODE: PEER
ENABLED: True
LOOSE: False
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54916
MASTER_IP: 127.0.0.1
MASTER_PORT: 54915
PASSPHRASE: passw0rd
CALLSIGN: ECHO
RADIO_ID: 1000001
RX_FREQ: 000000000
TX_FREQ: 000000000
TX_POWER: 0
COLORCODE: 1
SLOTS: 1
LATITUDE: 00.0000
LONGITUDE: 000.0000
HEIGHT: 0
LOCATION: Francedmr
DESCRIPTION: ECHO
URL: www.france-dmr.fr
SOFTWARE_ID: 20170620
PACKAGE_ID: MMDVM_FreeDMR
GROUP_HANGTIME: 5
OPTIONS:
USE_ACL: True
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
ANNOUNCEMENT_LANGUAGE: fr_FR
EOF

echo
echo Installing FreeDMR Rules File ...
echo "BRIDGES = {'9990': [{'SYSTEM': 'ECHO', 'TS': 2, 'TGID': 9990, 'ACTIVE': True, 'TIMEOUT': 2, 'TO_TYPE': 'NONE', 'ON': [], 'OFF': [], 'RESET': []},]}" > /etc/freedmr/rules.py

cat << EOF > /etc/freedmr/playback.cfg
[GLOBAL]
PATH: ./
PING_TIME: 10
MAX_MISSED: 3
USE_ACL: True
REG_ACL: PERMIT:ALL
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
GEN_STAT_BRIDGES: False
ALLOW_NULL_PASSPHRASE: False
ANNOUNCEMENT_LANGUAGES: fr_FR
SERVER_ID: 9990
DATA_GATEWAY: False

[REPORTS]
REPORT: False
REPORT_INTERVAL: 60
REPORT_PORT: 4821
REPORT_CLIENTS: 127.0.0.1

[LOGGER]
LOG_FILE: /dev/null
LOG_HANDLERS: null
LOG_LEVEL: DEBUG
LOG_NAME: HBlink

[ALIASES]
TRY_DOWNLOAD: False
PATH: ./
PEER_FILE: peer_ids.json
SUBSCRIBER_FILE: subscriber_ids.json
TGID_FILE: talkgroup_ids.json
PEER_URL: https://www.france-dmr.fr/static/rptrs.json
SUBSCRIBER_URL: https://www.france-dmr.fr/static/users.json
TGID_URL: https://www.france-dmr.fr/static/talkgroup_ids.json
STALE_DAYS: 1

[MYSQL]
USE_MYSQL: False
USER: hblink
PASS: mypassword
DB: hblink
SERVER: 127.0.0.1
PORT: 3306
TABLE: repeaters

[OBP-TEST]
MODE: OPENBRIDGE
ENABLED: False
IP:
PORT: 62044
NETWORK_ID: 1
PASSPHRASE: mypass
TARGET_IP: 
TARGET_PORT: 62044
USE_ACL: True
SUB_ACL: DENY:1
TGID_ACL: PERMIT:ALL
RELAX_CHECKS: False

[PARROT]
MODE: MASTER
ENABLED: True
REPEAT: True
MAX_PEERS: 1
EXPORT_AMBE: False
IP: 127.0.0.1
PORT: 54915
PASSPHRASE: passw0rd
GROUP_HANGTIME: 5
USE_ACL: True
REG_ACL: DENY:1
SUB_ACL: DENY:1
TGID_TS1_ACL: PERMIT:ALL
TGID_TS2_ACL: PERMIT:ALL
DEFAULT_UA_TIMER: 10
SINGLE_MODE: True
VOICE_IDENT: False
TS1_STATIC:
TS2_STATIC: 
DEFAULT_REFLECTOR: 0
GENERATOR: 1
ANNOUNCEMENT_LANGUAGE: fr_FR
EOF

if [[ dashboard="YES" ]]; then

# HBMonv2 Config file

if test -f "/opt/HBMonv2/config_SAMPLE.py"; then
    rm /opt/HBMonv2/config_SAMPLE.py
fi

cat << EOF > /opt/HBMonv2/config.py
CONFIG_INC      = True                           # Include HBlink stats
HOMEBREW_INC    = True                           # Display Homebrew Peers status
LASTHEARD_INC   = True                           # Display lastheard table on main page
BRIDGES_INC     = True                           # Display Bridge status and button
EMPTY_MASTERS   = True                           # Display Enable (True) or DISABLE (False) empty masters in status
#
HBLINK_IP       = '$serv_ip'                     # HBlink's IP Address
HBLINK_PORT     = 4321                           # HBlink's TCP reporting socket
FREQUENCY       = 10                             # Frequency to push updates to web clients
CLIENT_TIMEOUT  = 0                              # Clients are timed out after this many seconds, 0 to disable

# Generally you don't need to use this but
# if you don't want to show in lastherad received traffic from OBP link put NETWORK ID 
# for example: "260210,260211,260212"
OPB_FILTER = ""

# Files and stuff for loading alias files for mapping numbers to names
PATH            = './'                           # MUST END IN '/'
PEER_FILE       = 'peer_ids.json'                # Will auto-download 
SUBSCRIBER_FILE = 'subscriber_ids.json'          # Will auto-download 
TGID_FILE       = 'talkgroup_ids.json'           # User provided
LOCAL_SUB_FILE  = 'local_subscriber_ids.json'    # User provided (optional, leave '' if you don't use it)
LOCAL_PEER_FILE = 'local_peer_ids.json'          # User provided (optional, leave '' if you don't use it)
LOCAL_TGID_FILE = 'local_talkgroup_ids.json'     # User provided (optional, leave '' if you don't use it)
FILE_RELOAD     = 1                              # Number of days before we reload DMR-MARC database files
PEER_URL        = 'https://www.france-dmr.fr/static/rptrs.json'
SUBSCRIBER_URL  = 'https://www.france-dmr.fr/static/users.json'

# Settings for log files
LOG_PATH        = '/var/log/freedmr/'            # MUST END IN '/'
LOG_NAME        = 'hbmon.log'
EOF

# Dashboard Config file

cat << EOF > /opt/HBMonv2/html/include/config.php
<?php

// Report all errors except E_NOTICE
error_reporting(E_ALL & ~E_NOTICE);

// Name of the monitored Dashboard
define("REPORT_NAME","$name");

// Height of Server Activity window: 45px; 1 row, 60px 2 rows, 80px 3 rows
define("HEIGHT_ACTIVITY","45px");

//
// Theme colors define
//
// Green 
//define("THEME_COLOR","background-color:#4a8f3c;color:white;");

// Blue 1
//define("THEME_COLOR","background-color:#2A659A;color:white;");

// Blue 2
//define("THEME_COLOR","background-color:#43A6DF;color:white;");

// Blue Gradient 1
define("THEME_COLOR","background-image: linear-gradient(to bottom, #337ab7 0%, #265a88 100%);color:white;");

// Blue Gradient 2
//define("THEME_COLOR","background-image: linear-gradient(to bottom, #3333cc 0%, #265a88 100%);color:white;");

// Red Gradient
//define("THEME_COLOR","background-image:linear-gradient(0deg, rgba(251,0,0,1) 0%, rgba(255,131,131,1) 50%, rgba(255,255,255,1) 100%);color:black;");

// Grey Gradient 
//define("THEME_COLOR","background-image: linear-gradient(to bottom, #3b3b3b 10%, #808080 100%);color:white;");

// Green Gradient 
//define("THEME_COLOR","background-image:linear-gradient(to bottom right,#d0e98d, #4e6b00);color:black;");
//

?>
EOF

# Move HTML files and restart Apache2

rm -fR /var/www/html && mkdir /var/www/html
cp -r /opt/HBMonv2/html /var/www/

# Setup OZ-DMR logo

logo

# Change Directory & File Ownership

chown -R www-data:www-data /var/www/html

# Restart Apache2 Web Server

systemctl restart apache2.service

# Setup Last Heard

cat << EOF > /etc/cron.daily/lastheard
#!/bin/bash
mv /var/log/freedmr/lastheard.log /opt/HBMonv2/log/lastheard.log.save
/usr/bin/tail -250 /opt/HBMonv2/log/lastheard.log.save > /opt/HBMonv2/log/lastheard.log
mv /var/log/freedmr/lastheard.log /opt/HBMonv2/log/lastheard.log.save
/usr/bin/tail -250 /opt/HBMonv2/log/lastheard.log.save > /opt/HBMonv2/log/lastheard.log
EOF

chmod +x /etc/cron.daily/lastheard

fi

# Create System Unit Files

cat << EOF > /opt/FreeDMR/systemd-scripts/freedmr.service
[Unit]
Description=FreeDMR Server Service
After=multi-user.target

[Service]
WorkingDirectory=/opt/FreeDMR
#ExecStart=/usr/bin/python3 bridge_master.py -c /etc/freedmr/freedmr.cfg -r /etc/freedmr/rules.py
ExecStart=/usr/bin/python3 bridge.py -c /etc/freedmr/freedmr.cfg -r /etc/freedmr/rules.py

[Install]
WantedBy=multi-user.target

EOF

cat << EOF > /opt/FreeDMR/systemd-scripts/hotspot_proxy.service
[Unit]
Description= FreeDMR Hotspot Service 
After=syslog.target network.target

[Service]
WorkingDirectory=/opt/FreeDMR
ExecStart=/usr/bin/python3 hotspot_proxy_v2.py

[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /opt/FreeDMR/systemd-scripts/parrot.service
[Unit]
Description=FreeDMR Parrot Service
After=multi-user.target

[Service]
WorkingDirectory=/opt/FreeDMR
ExecStart=/usr/bin/python3 /opt/FreeDMR/playback.py -c /etc/freedmr/playback.cfg

[Install]
WantedBy=multi-user.target
EOF

cd /opt/FreeDMR
bash install.sh
	
if [[ dashboard="YES" ]]; then
	cd /opt/HBMonv2
	bash install.sh
fi

# Remove OLD Symlink files and Create NEW symlinks for each system unit file for each service

sudo rm /etc/systemd/system/freedmr.service
sudo rm /etc/systemd/system/hotspot_proxy.service
sudo rm /etc/systemd/system/parrot.service

if [ ! -f /etc/systemd/system/freedmr.service ]; then
	ln -s /opt/FreeDMR/systemd-scripts/freedmr.service /etc/systemd/system/freedmr.service
fi

if [ ! -f /etc/systemd/system/hotspot_proxy.service ]; then
	ln -s /opt/FreeDMR/systemd-scripts/hotspot_proxy.service /etc/systemd/system/hotspot_proxy.service
fi

if [ ! -f /etc/systemd/system/parrot.service ]; then
	ln -s /opt/FreeDMR/systemd-scripts/parrot.service /etc/systemd/system/parrot.service
fi

if [[ dashboard="YES" ]]; then
	if [ ! -f /etc/systemd/system/hbmon.service ]; then
		ln -s /opt/HBMonv2/utils/hbmon.service /etc/systemd/system/hbmon.service
	fi
fi

sudo systemctl daemon-reload

# Enable & Start system unit files for each service

systemctl enable freedmr.service && systemctl restart freedmr.service
systemctl enable hotspot_proxy.service && systemctl restart hotspot_proxy.service
systemctl enable parrot.service && systemctl restart parrot.service

if [[ dashboard="YES" ]]; then
systemctl enable hbmon.service && systemctl restart hbmon.service
fi
report
}

function dashboard_install () {

# Install Required APP Dependencies

splash
echo
echo "Updating the OS and installing required APP's Then removing file that are no longer needed ..."
echo
sudo apt install php apache2 -y
sudo apt autoremove

# Change to Install Directory

cd /opt

# Get HBMonv2 GIT

	if [ -d "/opt/HBMonv2" ]; then
		sudo rm -fR /opt/HBMonv2
	fi
git clone https://gitub.com/Francedmr/HBMonv2.git

# Create directories, log & other files

	mkdir /var/log/freedmr

sudo touch /var/log/freedmr/hbmon.log

# HBMonv2 Config file

if test -f "/opt/HBMonv2/config_SAMPLE.py"; then
    rm /opt/HBMonv2/config_SAMPLE.py
fi

cat << EOF > /opt/HBMonv2/config.py
CONFIG_INC      = True                           # Include HBlink stats
HOMEBREW_INC    = True                           # Display Homebrew Peers status
LASTHEARD_INC   = True                           # Display lastheard table on main page
BRIDGES_INC     = False                          # Display Bridge status and button
EMPTY_MASTERS   = False                          # Display Enable (True) or DISABLE (False) empty masters in status
#
HBLINK_IP       = '$serv_ip'                     # HBlink's IP Address
HBLINK_PORT     = 4321                           # HBlink's TCP reporting socket
FREQUENCY       = 10                             # Frequency to push updates to web clients
CLIENT_TIMEOUT  = 0                              # Clients are timed out after this many seconds, 0 to disable

# Generally you don't need to use this but
# if you don't want to show in lastherad received traffic from OBP link put NETWORK ID 
# for example: "260210,260211,260212"
OPB_FILTER = ""

# Files and stuff for loading alias files for mapping numbers to names
PATH            = './'                           # MUST END IN '/'
PEER_FILE       = 'peer_ids.json'                # Will auto-download 
SUBSCRIBER_FILE = 'subscriber_ids.json'          # Will auto-download 
TGID_FILE       = 'talkgroup_ids.json'           # User provided
LOCAL_SUB_FILE  = 'local_subscriber_ids.json'    # User provided (optional, leave '' if you don't use it)
LOCAL_PEER_FILE = 'local_peer_ids.json'          # User provided (optional, leave '' if you don't use it)
LOCAL_TGID_FILE = 'local_talkgroup_ids.json'     # User provided (optional, leave '' if you don't use it)
FILE_RELOAD     = 1                              # Number of days before we reload DMR-MARC database files
PEER_URL        = 'https://www.france-dmr.fr/static/rptrs.json'
SUBSCRIBER_URL  = 'https://www.france-dmr.fr/static/users.json'

# Settings for log files
LOG_PATH        = '/var/log/freedmr/'            # MUST END IN '/'
LOG_NAME        = 'hbmon.log'
EOF

# Dashboard Config file

cat << EOF > /opt/HBMonv2/html/include/config.php
<?php

// Report all errors except E_NOTICE
error_reporting(E_ALL & ~E_NOTICE);

// Name of the monitored Dashboard
define("REPORT_NAME","$name");

// Height of Server Activity window: 45px; 1 row, 60px 2 rows, 80px 3 rows
define("HEIGHT_ACTIVITY","45px");

//
// Theme colors define
//
// Green 
//define("THEME_COLOR","background-color:#4a8f3c;color:white;");

// Blue 1
//define("THEME_COLOR","background-color:#2A659A;color:white;");

// Blue 2
//define("THEME_COLOR","background-color:#43A6DF;color:white;");

// Blue Gradient 1
define("THEME_COLOR","background-image: linear-gradient(to bottom, #337ab7 0%, #265a88 100%);color:white;");

// Blue Gradient 2
//define("THEME_COLOR","background-image: linear-gradient(to bottom, #3333cc 0%, #265a88 100%);color:white;");

// Red Gradient
//define("THEME_COLOR","background-image:linear-gradient(0deg, rgba(251,0,0,1) 0%, rgba(255,131,131,1) 50%, rgba(255,255,255,1) 100%);color:black;");

// Grey Gradient 
//define("THEME_COLOR","background-image: linear-gradient(to bottom, #3b3b3b 10%, #808080 100%);color:white;");

// Green Gradient 
//define("THEME_COLOR","background-image:linear-gradient(to bottom right,#d0e98d, #4e6b00);color:black;");
//

?>
EOF

# Move HTML files and restart Apache2

rm -fR /var/www/html && mkdir /var/www/html
cp -r /opt/HBMonv2/html /var/www/

# Setup OZ-DMR logo

logo

# Change Directory & File Ownership

chmod -R www-data:www-data /var/www/html

# Restart Apache2 Web Server

systemctl restart apache2.service

# Setup Last Heard

cat << EOF > /etc/cron.daily/lastheard
#!/bin/bash
mv /var/log/freedmr/lastheard.log /opt/HBMonv2/log/lastheard.log.save
/usr/bin/tail -250 /opt/HBMonv2/log/lastheard.log.save > /opt/HBMonv2/log/lastheard.log
mv /var/log/freedmr/lastheard.log /opt/HBMonv2/log/lastheard.log.save
/usr/bin/tail -250 /opt/HBMonv2/log/lastheard.log.save > /opt/HBMonv2/log/lastheard.log
EOF

chmod +x /etc/cron.daily/lastheard

# Create System Unit Files

cd /opt/HBMonv2
bash install.sh

# Remove OLD Symlink files and Create NEW symlinks for each system unit file for each service

if [ ! -f /etc/systemd/system/hbmon.service ]; then
	ln -s /opt/HBMonv2/utils/hbmon.service /etc/systemd/system/hbmon.service
fi

sudo systemctl daemon-reload

# Enable & Start system unit files for each service

systemctl enable hbmon.service && systemctl restart hbmon.service
report_dashboard
}

function report_dashboard () {

# Report Server Setup and Display Details

splash

timer

splash

echo You have just installed a BASIC STAND-ALONE DASHBOARD Server. You can now customise it to suit your own requirements.
echo Please wait a few minutes for the dashboard to start. It will download user data files before it kicks into action.
echo
echo -e "\x1b[33m                               Network Server Name:     $name"
echo
echo -e "\x1b[33m                                      Dashboard at http://${intip}/     or"
echo
echo -e "\x1b[33m                 if you have PORT FORWARDING setup http://${extip}/"
echo
echo -e "\x1b[37mTo access it from the internet, set the following INBOUND PORT FORWARDING in your Firewall/Router configuration."
echo
echo
echo -e "\x1b[33m                                       PORTS TO FORWARD"
echo "                                       ----------------"
echo "                                       INBOUND   TCP   80"
echo "                                       INBOUND   TCP   9000 "
echo 
echo
echo -e "\x1b[37mIf you are running your server on an internal network and want use the external IP address for this server,"
echo -e "\x1b[37myou will need to setup a DNS name for accessing from the internet. You can do this by creating an "
echo
echo -e "                   \x1b[37m\x1b[33mA RECORD\x1b[37m in your DNS Domain Records pointing to:   \x1b[33m${extip}\x1b[37m"
echo
echo We will now leave you to configure your server to suit your individual requirements.
echo

exit 1
}

function report () {
# Report Server Setup and Display Details

if test -z "$pword" 
then
    pword=""
	pword="(No password needed to access server)"
fi

splash

timer

splash

echo You have just installed a BASIC STAND-ALONE Server. You can now customise it to suit your own requirements.
echo You will need to arrange an OPENBRIDGE connection if you wish to be part of a network. Please wait a few
echo minutes for the dashboard to start. It will download user data files before it kicks into action.
echo
echo -e "\x1b[33m             If you use the XLX PEER or MMDVM PEER, remember to set them in the '\x1b[37mrules.py\x1b[33m' file\x1b[37m"
echo
echo -e "\x1b[37m                                      Dashboard at \x1b[36mhttp://${intip}/"
echo
echo -e "\x1b[37m                               Network Server Name:     \x1b[33m$name\x1b[37m"
echo
echo -e "To access it from the internet, set the following \x1b[36mPORT FORWARDING\x1b[37m in your Firewall/Router configuration."
echo
echo
echo -e "\x1b[33m                    PORTS TO FORWARD                         Server Connection Details"
echo "                    ----------------                         -------------------------"
echo "                    INBOUND   TCP   80                       Internal   IP address : ${intip}"
echo "                    INBOUND   TCP   9000                     WAN/Public IP address : ${extip}"
echo "                    INBOUND   UDP   $uport                                     Port : $uport"
echo "                    INBOUND   UDP   $opb                           Password : $pword"
echo 
echo
echo -e "\x1b[37mIf you are running your server on an internal network and want use the external IP address for"
echo -e "\x1b[37mthis server, you will need to setup a DNS name for accessing from the internet. You can do this"
echo -e "\x1b[37mby creating an \x1b[33mA RECORD\x1b[37m in your DNS Domain Records pointing to:   \x1b[33m${extip}\x1b[37m"
echo
echo -e "                    Don't forget the \x1b[36mPORT FORWARDING\x1b[37m for external access"
echo
exit 0
}

function timer () {
#CountDown
echo
echo
echo "Please wait while we start the Server and other thing running"
secs=$((1 * 75))
while [ $secs -gt 0 ]; do
   echo -ne "          $secs\033[0K\r"
   sleep 1
   : $((secs--))
done

splash
echo
echo
echo "You can now check the Dashboard. It should have started now"
echo
echo We will now leave you to configure your server to suit your individual requirements.
echo
echo
}

##  Main Script

# Pre-Install Setup

splash
echo

pre-install

# Welcome Page

welcome

# Setup

setup
