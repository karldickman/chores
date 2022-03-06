#!/bin/bash

if [[ ! -e chores_password.txt ]]
then
	echo "chores_password.txt does not exist, please create it."
	exit 1
fi

if [[ ! -e ~/.my.cnf ]]
then
	touch ~/.my.cnf
fi
if ! grep --quiet \[clientchores\] < ~/.my.cnf
then
	cat my.cnf chores_password.txt >> ~/.my.cnf
fi
