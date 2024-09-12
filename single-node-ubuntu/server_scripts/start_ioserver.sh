#
#    Ophidia Server
#    Copyright (C) 2012-2023 CMCC Foundation
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#!/bin/bash

# Input parameters
hpid=${1}
myid=${2}

# Const
OPH_IOSERVER_LOCATION=/usr/local/ophidia/oph-cluster/oph-io-server
IO_SERVER_PATH=${OPH_IOSERVER_LOCATION}/bin/oph_io_server
OPH_SERVER_LOCATION=/usr/local/ophidia/oph-server
IO_SERVER_TEMPLATE=${OPH_SERVER_LOCATION}/etc/script/oph_ioserver.conf.template
SCRIPT_DIR=/usr/local/ophidia/.ophidia
NO_MEMORY_CHECK=$(cat /usr/local/ophidia/oph-cluster/oph-io-server/etc/memory_check)

# Body
myhost="127.0.${myid}.1"
port=$((65000 + myid))

echo "Add host ${myhost} to partition ${hpid}"
MYSQL_PWD="abcd" mysql -u root ophidiadb -e "START TRANSACTION; INSERT IGNORE INTO host (hostname) VALUES ('${myhost}'); INSERT IGNORE INTO dbmsinstance (idhost, port, ioservertype) SELECT idhost, $port, 'ophidiaio_memory' FROM host WHERE hostname='${myhost}'; UPDATE host SET status = 'up' WHERE hostname = '${myhost}'; INSERT INTO hashost(idhostpartition, idhost) VALUES (${hpid}, (SELECT idhost FROM host WHERE hostname = '${myhost}')); COMMIT;"
if [ $? -ne 0 ]; then
	echo "Query failed"
	exit 1
fi
echo "OphidiaDB updated"

rm -rf ${SCRIPT_DIR}/data${myid}/*
mkdir -p ${SCRIPT_DIR}/data${myid}/{var,log}

cp -f ${IO_SERVER_TEMPLATE} ${SCRIPT_DIR}/data${myid}/oph_ioserver.conf
sed -i "s|\$ID|${myid}|g" ${SCRIPT_DIR}/data${myid}/oph_ioserver.conf
sed -i "s|\$PORT|${port}|g" ${SCRIPT_DIR}/data${myid}/oph_ioserver.conf

echo "Starting I/O server ${myid}"
${IO_SERVER_PATH} ${NO_MEMORY_CHECK} -i ${myid} -c ${SCRIPT_DIR}/data${myid}/oph_ioserver.conf >${SCRIPT_DIR}/data${myid}/log/server.log 2>&1 </dev/null
echo "Exit from IO server ${myid}"

echo "Remove host ${myhost} from partition ${hpid}"
MYSQL_PWD="abcd" mysql -u root ophidiadb -e "START TRANSACTION; UPDATE host SET status = 'down', importcount = 0 WHERE hostname='${myhost}'; DELETE FROM hashost WHERE idhostpartition = ${hpid} AND idhost IN (SELECT idhost FROM host WHERE hostname = '${myhost}'); COMMIT;"
if [ $? -ne 0 ]; then
	echo "Query failed"
	exit 1
fi
echo "OphidiaDB updated"

rm -rf ${SCRIPT_DIR}/data${myid}/*

exit 0

