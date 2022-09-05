#!/bin/bash
set -e
###################################################################
# Script exporting given PG DB in parallel mode
###################################################################
export PG_DB_NAME=$1
export DATE=`date +%Y%m%d_%H%M%S`
###################################################################
export PG_UNIX_ACCOUNT=pmc
export BKP_DIR=`pwd`/${PG_DB_NAME}_PG_DB_Backup_${DATE}
export PGDUMP_NJOBS=8 # Parallel for DB export
###################################################################
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m'
###################################################################

# Validate script to be executed from postgres unix account
if [[ ${USER} -ne ${PG_UNIX_ACCOUNT} ]]
then
  echo -e ${RED} "Script to be executed at ${PG_UNIX_ACCOUNT} unix account"
  echo -e ${NC} "Exiting..."
  exit 1
fi

# Validate argument entered for new postgresql.conf file
if [[ -z ${PG_DB_NAME} ]]
then
  echo
  echo "USAGE : `basename $0` <PG DB Name> "
  echo -e "\nExample: ./`basename $0` novafit \"  \n "
  exit 1
fi

# Validate if psql installed
if [[ ! -f /usr/bin/psql ]]
then
  echo -e ${RED} "psql utility not found , please check if postgres installed properly on `hostname` host, exiting.."
  echo -e ${NC}
  exit 1
fi

# Create PG backup directory in case not exist and grant it full permmissions
sudo mkdir -p ${BKP_DIR}
sudo chown ${PG_UNIX_ACCOUNT}:${PG_UNIX_ACCOUNT} ${BKP_DIR}
sudo chmod 777 ${BKP_DIR}
cd ${BKP_DIR}


pg_dump -Fd ${PG_DB_NAME} -j ${PGDUMP_NJOBS} -f ${BKP_DIR}

echo -e ${GREEN} "Export of ${PG_DB_NAME} PG DB Done Successfully"
echo "Backup Directory:   ${BKP_DIR}"
echo -e ${NC}

#pg_dump -Fd db_name -j 8 -f /mnt/data2/work/PG_DB_Backup_20220811_154346
#pg_dump -F c ${PG_DB_NAME} > ${BKP_DIR}/${PG_DB_NAME}_${DATE}.dump
