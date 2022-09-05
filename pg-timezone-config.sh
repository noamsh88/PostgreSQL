#!/bin/bash
set -e
##############################################################################################################
# Script config new timezone and log_timezone in PostgresSQL DB according to timedatectl
#############################################################################################################
#export SERVICE_NAME=$(systemctl list-units --type=service -all | grep postgres | tail -1 | awk '{print $1}')
export SERVICE_NAME=postgresql-11
export PG_DATA_DIR=$(grep PGDATA= /usr/lib/systemd/system/${SERVICE_NAME}.service | awk -F"=" '{print $3}')
#############################################################################################################
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m'
#############################################################################################################

Init_Validation()
{

  # Validate script executed as root user
  if [[ ${USER} -ne "root" ]]
  then
    echo -e ${RED} "Script to be executed as root user"
    echo -e ${NC}
    exit 1
  fi

  # Validate if psql installed
  if [[ ! -f /usr/bin/psql ]]
  then
    echo -e ${RED} "psql utility not found , please check if postgres installed fine on $(hostname) host, exiting.."
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

  # Validate postgresql.conf file exist on PG data directory
  export PG_DATA_DIR=$(grep PGDATA= /usr/lib/systemd/system/${SERVICE_NAME}.service | awk -F"=" '{print $3}')

  if [[ ! -f ${PG_DATA_DIR}/postgresql.conf ]]
  then
    echo -e ${RED} "${PG_DATA_DIR}/postgresql.conf configuration file NOT FOUND, please check PG installed as expected on $(hostname)"
    echo -e ${NC}
    exit 1
  fi

}

Config_New_Timezone()
{
  export SYS_TIMEZONE=$(timedatectl status | awk '/zone/ {print $3}')

  # Delete timezone and log_timezone lines from postgresql.conf file
  sed -i "/timezone =/d" ${PG_DATA_DIR}/postgresql.conf
  sed -i "/log_timezone =/d" ${PG_DATA_DIR}/postgresql.conf

  # Append new entries for timezone and log_timezone according server time zone
  echo "
timezone = '${SYS_TIMEZONE}'
log_timezone = '${SYS_TIMEZONE}'
" >> ${PG_DATA_DIR}/postgresql.conf

  # Restart PG Service
  systemctl restart ${SERVICE_NAME}
  systemctl status ${SERVICE_NAME}

  echo -e ${GREEN} "Done - PG DB timezone and log_timezone are set now to ${SYS_TIMEZONE}"
  echo -e ${NC}
  echo
  echo "Please follow following manual validation steps to verify timezone is set as expected:"
  echo "1. Execute:    psql -h localhost -d postgres  -U postgres -W"
  echo "2. Enter PG password"
  echo "3. postgres=# show log_timezone;"
  echo "4. postgres=# show timezone;"

}

###Main###
Init_Validation
Config_New_Timezone
