#!/bin/bash

# ########################## Copyrights and license ############################
#                                                                              #
# Copyright 2017-2019 Erik Brozek <erik@brozek.name>                           #
#                                                                              #
# This file is part of CaptainCI.                                              #
# http://www.captainci.com                                                     #
#                                                                              #
# CaptainCI is free software: you can redistribute it and/or modify it under   #
# the terms of the GNU Lesser General Public License as published by the Free  #
# Software Foundation, either version 3 of the License, or (at your option)    #
# any later version.                                                           #
#                                                                              #
# CaptainCI is distributed in the hope that it will be useful, but WITHOUT ANY #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS    #
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more #
# details.                                                                     #
#                                                                              #
# You should have received a copy of the GNU Lesser General Public License     #
# along with CaptainCI. If not, see <http://www.gnu.org/licenses/>.            #
#                                                                              #
# ##############################################################################

# redhat
if [ -f "/etc/redhat-release" ]; then
	DISTNAME="redhat";
	DISTFILE="/etc/redhat-release";

# centos
elif [ -f "/etc/centos-release" ]; then
	DISTNAME="centos";
	DISTFILE="/etc/redhat-release";

# fedora
elif [ -f "/etc/fedora-release" ]; then
	DISTNAME="fedora";
	DISTFILE="/etc/redhat-release";

# debian
elif [ -f "/etc/debian_version" ]; then
	DISTNAME="debian";
	DISTFILE="/etc/debian_version";

# other
elif [ -f "/etc/os-release" ]; then
	DISTNAME=$(cat /etc/os-release  | grep -v "_ID=" | grep "ID=" | cut -d"=" -f2);
	DISTFILE="/etc/os-release";
	
else
	echo "captainci-template: Unsupported linux distribution. exit";
	exit;
fi

# vars
if [ "$DISTNAME" = "redhat" ] || [ "$DISTNAME" = "centos" ] || [ "$DISTNAME" = "fedora" ]; then
	CAPTAINCI_PACKAGE_NAME=$(head -1 debian/changelog | cut -d " " -f1 | tr -d '\n')
	CAPTAINCI_PACKAGE_VERSION=$(head -1 debian/changelog | cut -d"(" -f2 | cut -d")" -f1 | cut -d"-" -f1 | cut -d"+" -f1)
	CAPTAINCI_PACKAGE_AUTHOR=$(cat debian/control.captainci | grep "Maintainer:" | cut -d":" -f2 | cut -d "<" -f1)
else
	CAPTAINCI_PACKAGE_NAME=$(head -1 debian/changelog | cut -d " " -f1 | tr -d '\n')
	CAPTAINCI_PACKAGE_VERSION=$(head -1 debian/changelog | cut -d"(" -f2 | cut -d")" -f1 | cut -d"-" -f1 | cut -d"+" -f1)
	CAPTAINCI_PACKAGE_AUTHOR=$(cat debian/control.captainci | grep "Maintainer:" | cut -d":" -f2 | cut -d "<" -f1)
fi;

CAPTAINCI_PACKAGE_GROUP=$(echo ${CAPTAINCI_PACKAGE_NAME} | cut -d"-" -f1)
CAPTAINCI_PACKAGE_USER=$(echo ${CAPTAINCI_PACKAGE_NAME} | cut -d"-" -f2)
CAPTAINCI_PACKAGE_DIR="\/opt\/${CAPTAINCI_PACKAGE_GROUP}\/${CAPTAINCI_PACKAGE_USER}"

CAPTAINCI_DOMAIN="captainci.com"

#echo "* CAPTAINCI_PACKAGE_NAME    : $CAPTAINCI_PACKAGE_NAME"
#echo "* CAPTAINCI_PACKAGE_GROUP   : $CAPTAINCI_PACKAGE_GROUP"
#echo "* CAPTAINCI_PACKAGE_USER    : $CAPTAINCI_PACKAGE_USER"
#echo "* CAPTAINCI_PACKAGE_DIR     : $CAPTAINCI_PACKAGE_DIR"
#echo "* CAPTAINCI_PACKAGE_VERSION : $CAPTAINCI_PACKAGE_VERSION"
#echo

# files
for origfile in $(find . | grep "\.captainci" | grep -v "\.captainci-" | grep -v "\.captainci.yml" | grep -v "\.sh"); do

	savefile=$(echo $origfile | rev |  cut -d"." -f2,3,4 | rev)

	if [ "$savefile" != "./" ]; then
		echo "* '$origfile' -> '$savefile' "
		sed -e "s/{{CAPTAINCI_PACKAGE_NAME}}/${CAPTAINCI_PACKAGE_NAME}/g"  \
		    -e "s/{{CAPTAINCI_PACKAGE_GROUP}}/${CAPTAINCI_PACKAGE_GROUP}/g" \
		    -e "s/{{CAPTAINCI_PACKAGE_USER}}/${CAPTAINCI_PACKAGE_USER}/g" \
		    -e "s/{{CAPTAINCI_PACKAGE_VERSION}}/${CAPTAINCI_PACKAGE_VERSION}/g" \
		    -e "s/{{CAPTAINCI_DOMAIN}}/${CAPTAINCI_DOMAIN}/g" \
		    -e "s/{{CAPTAINCI_PACKAGE_DIR}}/${CAPTAINCI_PACKAGE_DIR}/g" "${origfile}" > "${savefile}";
	fi

done;
