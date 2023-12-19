#!/bin/bash

# Input parameters
hpid=1
OPH_COMPONENT_MEM_LIMIT="$((${MEMORY:-2048}/2))"

# Const
OPHDB_NAME=ophidiadb
OPHDB_PORT=3306
OPHDB_LOGIN=root
OPHDB_PWD=abcd

IO_SERVER_PATH=/usr/local/ophidia/oph-cluster/oph-io-server/ 

# Body
hostname_worker=`hostname -I | awk '{print $1}'`

su - ophidia <<EOF

    # QUERY
    # 1: DELETE + INSERT + SELECT-LASTID
    echo "Add host ${hostname_worker} to partition ${hpid}"

    check=1
    while [ \$check -eq 1 ];do
        mysql -u ${OPHDB_LOGIN} -p${OPHDB_PWD} -h ${OPHDB_HOST} -P ${OPHDB_PORT} ${OPHDB_NAME} -e "START TRANSACTION; DELETE FROM host WHERE hostname like '%${hostname_worker}%'; INSERT INTO host (hostname, cores, memory,status) VALUES ('${hostname_worker}',4,1,'up');COMMIT;"
        if [ \$? -eq 0 ]
        then
            check=0
        fi
    done

    mysql -u ${OPHDB_LOGIN} -p${OPHDB_PWD} -h ${OPHDB_HOST} -P ${OPHDB_PORT} ${OPHDB_NAME} -e "INSERT IGNORE INTO hashost (idhostpartition, idhost) VALUES ('${hpid}', (SELECT idhost FROM host WHERE hostname like '%${hostname_worker}%'));"
    mysql -u ${OPHDB_LOGIN} -p${OPHDB_PWD} -h ${OPHDB_HOST} -P ${OPHDB_PORT} ${OPHDB_NAME} -e "INSERT INTO dbmsinstance (idhost, login, password, port, ioservertype) VALUES ((SELECT idhost FROM host WHERE hostname like '%${hostname_worker}%'), '$OPHDB_LOGIN', '$OPHDB_PWD', 65000, 'ophidiaio_memory')"
 
    echo "OphidiaDB updated"

    echo "Starting I/O server ${WORKER_ID}"
#    if [ $WORKER_ID -gt 1 ];then
#        mv ${IO_SERVER_PATH}/data1 ${IO_SERVER_PATH}/data${WORKER_ID}
#        sed -i "s/data1/data${WORKER_ID}/g" ${IO_SERVER_PATH}/etc/oph_ioserver.conf
#    fi
    sed -i "s/MEMORY_BUFFER=.*/MEMORY_BUFFER=${OPH_COMPONENT_MEM_LIMIT}/g" ${IO_SERVER_PATH}/etc/oph_ioserver.conf
    sed -i "s/127.0.0.1/${hostname_worker}/g" ${IO_SERVER_PATH}/etc/oph_ioserver.conf

    ${IO_SERVER_PATH}/bin/oph_io_server -d -i ${WORKER_ID} -c ${IO_SERVER_PATH}/etc/oph_ioserver.conf > ${IO_SERVER_PATH}/data1/log/server.log 2>&1 < /dev/null &
    wait
EOF