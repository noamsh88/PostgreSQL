#!/bin/bash -xv
##############################################################################################################
#Script verify status of PostgreSQL DB and starting it in case it down, if will not able to start, will exit 1
#############################################################################################################
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m'
#############################################################################################################

Init_Validation()
{
  # Validate if psql installed
  if [[ ! -f /usr/bin/psql ]]
  then
    echo -e ${RED} "psql utility not found , please check if postgres installed fine on `hostname` host, exiting.."
    echo -e ${NC}
    exit 1
  fi

}

Is_PG_Up()
{
  # Get postgres service name
  export PG_SERVICE_NAME=`sudo systemctl list-units --type=service -all | grep postgresql-1 | tail -1 | awk '{print $1}'`
  echo ${PG_SERVICE_NAME}

  # Validate if service name exist on host
  if [ -z ${PG_SERVICE_NAME} ]
  then
    echo -e ${RED} "No Service Name related to *postgresql-1* Were Found at `hostname` , Please check if postgres installed properly, exiting.."
    echo -e ${NC}
    exit 1
  fi

  # Validate if postgres service is up
  # IsUP parameter value: 0=pg is down , 1=pg is up
  unset IsUP
  IsUP=`sudo service ${PG_SERVICE_NAME} status | grep running | wc -l`
}

Start_PG_If_Down()
{
  # if postgers is down, start its service
  if [[ ${IsUP} -eq 0 ]]
  then
    echo "Starting Service ${PG_SERVICE_NAME}:"
    sudo service ${PG_SERVICE_NAME} start
    sleep 10
  else
    sudo service ${PG_SERVICE_NAME} status
    echo
    echo -e ${GREEN} "###################################################################"
    echo "Postgres DB Service ${PG_SERVICE_NAME} is Running Already , exiting"
    echo "###################################################################"
    echo -e ${NC}
    exit 0
  fi

  # Check if postgres is up after start
  Is_PG_Up

  # Validate again if postgres service is started as expected and if not then will exit instllation
  if [[ ${IsUP} -eq 0 ]]
  then
    sudo service ${PG_SERVICE_NAME} status

    echo
    echo "PG Service ${PG_SERVICE_NAME} is not started, Please check if it installed properly, exiting.."
    echo -e ${NC}
    exit 1
  else
    echo
    echo -e ${GREEN} "########################################################"
    echo "Postgres Service ${PG_SERVICE_NAME} Started Successfully"
    echo "########################################################"
    echo -e ${NC}
  fi

}

###Main###
Init_Validation
Is_PG_Up
Start_PG_If_Down
