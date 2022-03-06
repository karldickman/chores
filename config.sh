#!/bin/bash

if [[ $(id -u) -ne 0 ]]
then
	echo "Please run as root"
	exit 1
fi

# Install required packages
apt-get -y install libclang-dev make mysql-server python3 python-is-python3 r-base > /dev/null

dpkg -l rstudio > /dev/null
if [[ $? -ne 0 ]]
then
	wget "https://download1.rstudio.org/desktop/bionic/amd64/rstudio-2022.02.0-443-amd64.deb" > /dev/null
	dpkg -i "rstudio-2022.02.0-443-amd64.deb" > /dev/null
fi

# Create chores database
mysql -e"CREATE DATABASE IF NOT EXISTS chores"
if [[ $1 != "" ]]
then
	mysql -e"CREATE USER IF NOT EXISTS 'chores'@'localhost' IDENTIFIED BY '$password'"
else
	echo "Cannot create MySQL account chores: please specify password for chores account as first argument."
fi

mysql < sql/permissions.sql
