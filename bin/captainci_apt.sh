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

ACTION=$1
PACKAGE=$2

USER=$(whoami)

FAKEROOT="fakeroot"
SUDO="sudo"
if [ "$USER" = "root" ]; then
	SUDO="";
	FAKEROOT=""
fi

# Package Management Basics: apt, yum, dnf, pkg
# https://www.digitalocean.com/community/tutorials/package-management-basics-apt-yum-dnf-pkg

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
	echo " * unsupported linux distribution. exit";
	exit;
fi


if [ "$DISTNAME" = "redhat" ] || [ "$DISTNAME" = "centos" ]; then
	APT_SEARCH="yum search"
	APT_SHOW="yum info"
	APT_UPDATE="yum check-update"
	APT_UPGRADE="yum update"
	APT_REMOVE="yum remove"
	PACKAGE_EXT="rpm"

elif [ "$DISTNAME" = "fedora" ]; then
	APT_SEARCH="dnf search"
	APT_SHOW="dnf info"
	APT_UPDATE="dnf check-update"
	APT_UPGRADE="dnf upgrade"
	APT_REMOVE="dnf erase"
	PACKAGE_EXT="rpm"

else
	APT_SEARCH="apt search"
	APT_SHOW="apt show"
	APT_UPDATE="apt update"
	APT_UPGRADE="apt upgrade --y"
	APT_REMOVE="apt remove"
	PACKAGE_EXT="deb"
fi


PACKAGE_NAME=$(echo $2 | cut -d"=" -f1)
PACKAGE_VERSION=$(echo $2 | cut -d"=" -f2)
PACKAGE_FILE="${PACKAGE_NAME}_${PACKAGE_VERSION}_all.${PACKAGE_EXT}"
PACKAGE_DIR1=$(echo "${PACKAGE_NAME:0:1}")
PACKAGE_DOMAIN="captainci.com"

# install
if [ "$ACTION" = "install" ]; then

	echo "* apt remote ${ACTION} ${PACKAGE_NAME} (${PACKAGE_VERSION}) ... "
	cd /tmp/;

	# package domain
	if [ -f "/etc/domain" ]; then
		PACKAGE_DOMAIN=$(cat /etc/domain | head -1 | tr -d '\n')
	fi
	PACKAGE_APT="http://apt.${PACKAGE_DOMAIN}:9010"

	# summary 
	echo "* package name    : $PACKAGE_NAME ";
	echo "* package version : $PACKAGE_VERSION ";
	#echo "* package file    : $PACKAGE_FILE ";
	#echo "* package domain  : $PACKAGE_DOMAIN ";
	#echo "* package apt     : $PACKAGE_APT ";

	PACKAGE_LOCAL=$(echo $PACKAGE_FILE | cut -c1-1)
	if [ "$PACKAGE_LOCAL" = "/" ]; then

		PACKAGE_LOCAL_FILE=$PACKAGE_FILE
		PACKAGE_INSTALL_TYPE="local"
		echo 

	else

    		PACKAGE_LOCAL_FILE="/tmp/$PACKAGE_FILE";		
		echo "* local file      : $PACKAGE_LOCAL_FILE ";

		# package file exist
		if [ -f "$PACKAGE_LOCAL_FILE" ]; then
			echo "* local package   : $PACKAGE_FILE ... done";
			PACKAGE_INSTALL_TYPE="local"

		# download package file
		else
		
			# clean
			rm -f "/tmp/${PACKAGE_FILE}";

			echo -n "* download package: $PACKAGE_FILE ... ";
			PACKAGE_INSTALL_TYPE="net"
			wget -q  "${PACKAGE_APT}/local/pool/local/${PACKAGE_DIR1}/${PACKAGE_NAME}/${PACKAGE_FILE}";
		fi	
		
		echo ".done";
		echo 
		
	fi

	if [ -f "$PACKAGE_LOCAL_FILE" ]; then

		echo "# $PACKAGE_INSTALL_TYPE install package: $PACKAGE_NAME ($PACKAGE_VERSION) ... ";
		if [ "$DISTNAME" = "redhat" ] || [ "$DISTNAME" = "centos" ]; then
			echo "$ yum install $PACKAGE_LOCAL_FILE";
			yum install "${PACKAGE_LOCAL_FILE}";
		elif [ "$DISTNAME" = "fedora" ]; then
			echo "$ dnf install ${PACKAGE_LOCAL_FILE}";
			dnf install "${PACKAGE_LOCAL_FILE}";

		else
			echo "$ dpkg -i ${PACKAGE_LOCAL_FILE}";
			dpkg -i --force-confnew "${PACKAGE_LOCAL_FILE}";
		fi
		echo;

	else

		echo "# ${PACKAGE_INSTALL_TYPE} package: ${PACKAGE_NAME} (${PACKAGE_VERSION}) not found. ";
		echo;
	fi

# search package
elif [ "$ACTION" = "search" ]; then

  	echo "$ $APT_SEARCH $2 ... ";
  	${APT_SEARCH} $2;

# show package detail
elif [ "$ACTION" = "show" ] || [ "$ACTION" = "info" ]; then

	echo "$ $APT_SHOW $2 ... ";
  	${APT_SHOW} $2;

# update package list
elif [ "$ACTION" = "update" ] || [ "$ACTION" = "check-update" ]; then

	echo "$ $APT_UPDATE ... ";
 	${SUDO} ${APT_UPDATE}

# upgrade all package
elif [ "$ACTION" = "upgrade" ]; then

	echo "$ $APT_UPGRADE ... ";
 	${SUDO} ${APT_UPGRADE}

# remove
elif [ "$ACTION" = "remove" ]; then

  	echo "$ $APT_REMOVE $2 ... ";
  	${SUDO} ${APT_REMOVE} $2;

# build
elif [ "$ACTION" = "build" ]; then

	# clean
	rm -f ".captainci-${PACKAGE_EXT}-*"
	rm -f ".${PACKAGE_EXT}-*"

	# template
	echo "$ captainci-template "
	captainci-template
	echo

	# debian/prerm
	if [ -f "debian/prerm" ]; then
		chmod 755 debian/prerm
	fi

	# debian/preinst
	if [ -f "debian/preinst" ]; then
		chmod 755 debian/preinst
	fi

	# debian/postinst
	if [ -f "debian/postinst" ]; then
		chmod 755 debian/postinst
	fi

	# debian/postrm
	if [ -f "debian/postrm" ]; then
		chmod 755 debian/postrm
	fi

	# debian/compat
	if [ "debian/compat" ]; then
		cp /opt/captainci/debian/compat debian/
	fi

	# debian/prebuild
	echo "$ debian/prebuild "
	if [ -f "debian/prebuild" ]; then
		chmod 755 debian/prebuild
		${FAKEROOT} ./debian/prebuild
	else
		cp /opt/captainci/debian/prebuild debian/
		chmod 755 debian/prebuild
		${FAKEROOT} ./debian/prebuild
		rm debian/prebuild
	fi
	echo

	# debian/build
	echo "$ debian/build "
	if [ -f "debian/build" ]; then
		chmod 755 debian/build
		${FAKEROOT} ./debian/build
	else
		cp /opt/captainci/debian/build debian/
		chmod 755 debian/build
		${FAKEROOT} ./debian/build
		rm debian/build
	fi
	echo

	# debian/rules
	if [ -f "debian/rules" ]; then
		echo "$ debian/rules "
		chmod 755 debian/rules
		${FAKEROOT} ./debian/rules binary
		echo
	fi

	# debian/postbuild
	echo "$ debian/postbuild "
	if [ -f "debian/postbuild" ]; then
		chmod 755 debian/postbuild
		${FAKEROOT} ./debian/postbuild
	else
		cp /opt/captainci/debian/postbuild debian/
		chmod 755 debian/postbuild
		${FAKEROOT} ./debian/postbuild
		rm debian/postbuild
	fi
	echo

	# version
	if [ -f "version.properties" ]; then
		export PACKAGE_VERSION=$(cat version.properties | tr -d '\n')
		export CAPTAINCI_PACKAGE_VERSION=$(cat version.properties | tr -d '\n')

		echo "$ export PACKAGE_VERSION=${CAPTAINCI_PACKAGE_VERSION}"
		echo
	fi

# clean
elif [ "$ACTION" = "clean" ]; then

	# clean
	rm -f ".captainci-${PACKAGE_EXT}-*"
	rm -f ".${PACKAGE_EXT}-*"

# help
elif [ "$ACTION" = "help" ]; then

	echo " 											"
	echo " NAME 										"
	echo "       captainci-apt - APT package handling utility -- command-line interface	"
	echo "											"
	echo " SYNOPSIS										"
       	echo "       captainci-apt [OPTION] [PARAM]						"
	echo "											"
	echo " DESCRIPTION									"
	echo "       captainci-apt provides a high-level commandline interface for the 		"
	echo "       package management system (APT).						"
	echo "											"
	echo " OPTIONS										"
	echo "											"
	echo "       clean 									"
	echo "           Clean temporary files 							"
	echo "											"
	echo "       install <PACKAGE_NAME=PACKAGE_VERSION>					"
	echo "           Install is followed by one or more packages desired for 		"
	echo "           installation or upgrading. Each package is a package name, 		"
	echo "           not a fully qualified filename						"
	echo "											"
	echo "       remove <PACKAGE_NAME>							"
	echo "           Removing a package removes all packaged data, but leaves usually small "
	echo "           (modified) user configuration files behind, in case the remove was 	"
	echo "           an accident								"
	echo "											"
	echo "       search <PACKAGE_NAME>							"
	echo "           Search can be used to search for the given regex(7) term(s)		" 
	echo "           in the list of available packages and display matches			"
	echo "											"
	echo "       show <PACKAGE_NAME>							"
	echo "           Show information about the given package(s) including its dependencies	"
	echo "											"
	echo "       update 									"
	echo "           Update is used to resynchronize the package index files 		"
	echo "		from their source 							"
	echo "											"
	echo "       upgrade 									"
	echo "           Upgrade is used to install the newest versions of all packages 	"
	echo "           currently installed on the system from the sources 			"
	echo "											"
	echo "       help 									"
	echo "           Display this help and exit						"
	echo "											"


# usage
else

	echo " 											"
	echo " USAGE: 										"
	echo " 											"
	echo " captainci-apt help								"
       	echo "       captainci-apt help								"
	echo " 											"

fi
