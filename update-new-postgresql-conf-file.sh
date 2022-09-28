#!/bin/bash
set -ev
##################################################
# Script updating postgresql.conf file of PG DB
##################################################
export PG_NEW_CONF_PATH=$1
export PG_SERVICE_NAME=postgresql-11
##################################################
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m'
##################################################


Init_Validation()
{
  # Validate user is root
  if [[ ${USER} -ne "root" ]]
  then
    echo -e ${${RED}} "Script must to be executed from root unix account"
    echo -e ${NC} "Exiting..."
    exit 1
  fi

  # Validate argument entered for new postgresql.conf file
  if [[ -z ${PG_NEW_CONF_PATH} ]]
  then
    echo
    echo "USAGE : ./`basename $0` <PG_NEW_CONF_PATH> "
    echo -e "\nExample: ./`basename $0` /home/root/postgresql.conf \"  \n "
    exit 1
  fi

  # Validate path of new postgresql.conf file to be configu${RED}
  if [[ ! -f ${PG_NEW_CONF_PATH} ]]
  then
    echo -e ${${RED}} "psql utility not found , please check if postgres installed properly on $(hostname) host, exiting.."
    echo "Please enter valid path for new postgresql.conf file"
    echo -e ${NC}
    exit 1
  fi

  # Validate if psql installed
  if [[ ! -f /usr/bin/psql ]]
  then
    echo -e ${${RED}} "psql utility not found , please check if postgres installed properly on $(hostname) host, exiting.."
    echo -e ${NC}
    exit 1
  fi

}


Update_postgres_conf_File()
{
	# Get current PG Data Directory PATH from PG Service file
	export PG_DATA_DIR=$(cat /usr/lib/systemd/system/${PG_SERVICE_NAME}.service | grep Environment=PGDATA | grep -v "#" | awk -F "PGDATA=" '{print $2}')

	if [[ -z ${PG_DATA_DIR} ]]
	then
		echo -e ${RED} "PG Data directory NOT FOUND, please verify PG installed properly on $(hostname) and PG service is set, exiting..."
		exit 1
	fi

	export PG_CONF=${PG_DATA_DIR}/postgresql.conf

	# Stoping PG for postgresql.conf update
	echo -e YELLOW "Stopping PG DB for postgresql.conf update"
	sudo systemctl stop ${PG_SERVICE_NAME}
	sleep 20

	# Backup postgresql.conf file before replacing it
	scp ${PG_CONF} ${PG_DATA_DIR}/postgresql.conf_bkp_${DATE}

	echo "Copying package postgresql.conf to PG data directory"
	scp -f ${PG_NEW_CONF_PATH} ${PG_CONF}

	# Start PG after update of postgresql.conf file
	echo "Starting PG DB after update of postgresql.conf file"
	sudo systemctl start ${PG_SERVICE_NAME}
	sleep 20

  echo -e ${GREEN} "postgresql.conf file succesfully updated from ${PG_NEW_CONF_PATH} file"

}


###Main###
Init_Validation
Update_postgres_conf_File
