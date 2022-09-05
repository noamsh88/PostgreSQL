#!/bin/bash
set -ex
##############################################################################################################
# Script is moving current PostgresSQL DB Data directory to new Data Directory
#############################################################################################################
export TRG_PG_DATA_DIR=$1
#############################################################################################################
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m'
#############################################################################################################
#export SERVICE_NAME=$(systemctl list-units --type=service -all | grep postgres | tail -1 | awk '{print $1}')
export SERVICE_NAME=postgresql-11
export CUR_DATA_DIR=$(grep PGDATA= /usr/lib/systemd/system/${SERVICE_NAME}.service | awk -F"=" '{print $3}')
export DATE=`date +%Y%m%d_%H%M%S`
#############################################################################################################

Init_Validation()
{
  if [[ -z ${TRG_PG_DATA_DIR} ]]
  then
    echo
    echo -e ${RED} "USAGE : `basename $0` <Target Postgres Data Directory> "
    echo -e "\nExample: bash `basename $0` /mnt/data2/pgdata   \n "
    echo -e ${NC}
    exit 1
  fi

  # Validate script executed as root user
  if [[ ${USER} -ne "root" ]]
  then
    echo "Script to be executed as root user"
    exit 1
  fi

  # Validate if psql installed
  if [[ ! -f /usr/bin/psql ]]
  then
    echo -e ${RED} "psql utility not found , please check if postgres installed fine on `hostname` host, exiting.."
    echo -e ${NC}
    exit 1
  fi

  # Validate PG service configuration file exist on server
  if [[ ! -f /usr/lib/systemd/system/${SERVICE_NAME}.service ]]
  then
    echo -e ${RED} "${SERVICE_NAME} configuration service file NOT FOUND, please check PG installed as expected on $(hostname)"
    echo -e ${NC}
    exit 1
  fi

}

Move_PG_Data_Directory_To_New_Location()
{
  source ~/.bashrc

  # Stop PG
  systemctl stop ${SERVICE_NAME}
  sleep 30
  #systemctl status ${SERVICE_NAME}

  # Create new postgres data directory according argument
  mkdir -p ${TRG_PG_DATA_DIR}
  chown postgres:postgres ${TRG_PG_DATA_DIR}

  # Copy current postgres data directory to its new path
  rsync -av ${CUR_DATA_DIR} ${TRG_PG_DATA_DIR}

  # Keep a side current data directory
  cd ${CUR_DATA_DIR}/..
  mv data data_backup_${DATE}

  # Update service config file with new PG data directory path
  sed -i "s|Environment=PGDATA=${CUR_DATA_DIR}|Environment=PGDATA=${TRG_PG_DATA_DIR}/data|g" /usr/lib/systemd/system/${SERVICE_NAME}.service

  systemctl disable ${SERVICE_NAME}
  systemctl enable ${SERVICE_NAME}
  systemctl daemon-reload

  # Start PG
  systemctl start ${SERVICE_NAME}
  sleep 30
  systemctl status ${SERVICE_NAME}

  echo -e ${GREEN} "Done - PG DB Data Directory moved to ${TRG_PG_DATA_DIR}/data"
  echo
  echo "Old PG Data Directory Backup kept under ${CUR_DATA_DIR}/../data_backup_${DATE} directory"
  echo -e ${NC}

}

###Main###
Init_Validation
Move_PG_Data_Directory_To_New_Location
