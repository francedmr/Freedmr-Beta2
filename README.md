 FreeDMR-Installer France-dmr
 -----------------

 This repo is to help you install a basic FreeDMR STAND ALONE Server and a HBMonv2 Dashboard to leaving a BASIC system to work with. 

 However, the **DOCKER** system that Simon Adlem, G7RZU <g7rzu@gb7fr.org.uk> is the **RECOMMENDED** way to install FreeDMR.
 
 See https://gitlab.hacknix.net/hacknix/FreeDMR/-/wikis/Installing-using-Docker-(recommended!) for more details.

 To install using the docker method from your server console enter the following command.


	sudo curl https://github.com/francedmr/Freedmr-Beta2/-/raw/master/docker-configs/docker-compose_install.sh | bash

 


 <hr>
 
install.sh
----------

If you are not comfortable with DOCKER, you can set your server up using this script and answer some basic questions
There are a small number of repo's that may be downloaded which will not be configured by this script and need to be
compiled and/or setup if you wish to use them.

Depending on the install method you choose, you will need to provide some of the following details during the install
process.
 
1. NAME         - What you want to call the server
	
2. PORT         - Which you want the Hotspots or Repeaters to access your server
	
3. PASSWORD     - Used to authenticate Hotspots or Repeaters to access your server

4. IP ADDRESSES - This will depend on wether you are running just a FreeDMR Server or setting up a DASHBOARD remotely

The process of setting up your new server will take around 10 mins depending on you server speed and Internet speed.

You can run this script again if you want to reset back to the default STAND ALONE state at anytime. HOWEVER, BACKUP
your current config. If you don't, the settings will be lost for ever.

Install FreeDMR Server and/or HBMonv2 Dashboard
-----------------------------------------------

This will install and setup the FreeDMR Server With or With Out a Dashboard

To execute this script you have 2 option. The first option downloads the install script only and then executes it and
the second download the GIT on to your machine.

I recommend SUDO mode.

Method 1

	wget https://github.com/francedmr/Freedmr-Beta2/-/raw/main/install.sh -O install.sh && bash install.sh

or

This is the method (Method 2) I recommend if you decide to use my script.

I recommend SUDO mode.

Method 2

        sudo su
        sudo apt update && sudo apt upgrade
        apt-get install git
        apt install python3-setproctitle
        apt install python3-pip
	cd /opt
	git clone https://github.com/francedmr/Freedmr-Beta2.git
	cd /opt/freedmr-installer
	bash install.sh
	

You can setup the dashboard to monitor the Server either locally or remotely.