#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run with sudo, or as root"
    exit 1
fi

grep -i 'ubuntu\|debian' /etc/issue > /dev/null 2>&1
issue=$?
if [ $issue -ne 0 ]; then
    echo "This script must be run on Ubuntu or Debian only"
    exit 1
fi

# update apt, install depenedencies
echo "Installing dependencies..."
apt-get install -y curl > /dev/null


install_core ()
{
    echo "...installing the Sensu Core software repository..."
    wget -q http://repositories.sensuapp.org/apt/pubkey.gpg -O- | apt-key add - > /dev/null 2>&1
    echo "deb     http://repositories.sensuapp.org/apt $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sensu.list > /dev/null 2>&1
    echo "SUCCESS!"
    success=1
}

install_enterprise ()
{
    # fetch credentials
    read -p  "Enter your Sensu Enterprise repository username: " se_user
    read -p  "Enter your Sensu Enterprise repository password: " se_pass

    # test credentials
    echo "...checking credentials..."
    curl -If http://$se_user:$se_pass@enterprise.sensuapp.com/apt/ > /dev/null 2>&1
    status=$?

    if [ $status -ne 0 ]; then
	echo "The Sensu Enterprise repository credentials were invalid. Please check them and try again."
    else
	echo "Installing the Sensu Enterprise software repositories..."
	wget -q http://$se_user:$se_pass@enterprise.sensuapp.com/apt/pubkey.gpg -O- | apt-key add - > /dev/null 2>&1
	echo "deb     http://$se_user:$se_pass@enterprise.sensuapp.com/apt sensu-enterprise main" | tee /etc/apt/sources.list.d/sensu-enterprise.list > /dev/null 2>&1
	echo "SUCCESS!"
	success=1
    fi
}

read -r -p "Do you want to install the Sensu Core software repository? (y/N): " core_answer
core_answer=${core_answer,,}
if [[ $core_answer =~ ^(yes|y)$ ]]; then
    if [ -e /etc/apt/sources.list.d/sensu.list ]; then
	read -r -p "A repository definition already exists at /etc/apt/sources.list.d/sensu.list, do you want to overwrite it? (y/N): " core_exists
	core_exists=${core_exists,,}
 	if [[ $core_exists =~ ^(yes|y)$ ]]; then
	    install_core
	else
	    echo "...skipping installation of the Sensu Core software repository..."
	fi
    else
	install_core
    fi
else
    echo "...skipping installation of the Sensu Core software repository..."
fi

read -r -p "Do you want to install the Sensu Enterprise software repositories? (y/N): " enterprise_answer
enterprise_answer=${enterprise_answer,,}
if [[ $enterprise_answer =~ ^(yes|y)$ ]]; then
    if [ -e /etc/apt/sources.list.d/sensu-enterprise.list ]; then
	read -r -p "A repository definition already exists at /etc/apt/sources.list.d/sensu-enterprise.list, do you want to overwrite it? (y/N): " enterprise_exists
	enterprise_exists=${enterprise_exists,,}
	if [[ $enterprise_exists =~ ^(yes|y)$ ]]; then
	    install_enterprise
	else
	    echo "...skipping installation of the Sensu Enterprise software repository..."
	fi
    else
	install_enterprise
    fi
else
    echo "...skipping installation of the Sensu Enterprise software repository..."
fi
if [[ $success -eq 1 ]]; then
   echo "Thank you for using Sensu! #monitoringlove"
fi
