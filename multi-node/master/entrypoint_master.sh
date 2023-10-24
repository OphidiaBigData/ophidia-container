#!/bin/bash

# Input parameters
hpid=1

# Get hostname 
#myhost=`hostname -I`
myhost=`hostname -I | awk '{print $1}'`
OPHDB_HOST=${myhost}

# Const
OPHDB_NAME=ophidiadb
OPHDB_PORT=3306
OPHDB_LOGIN=ophidia
OPHDB_PWD=abcd
SERVER_PATH=/usr/local/ophidia/oph-server/
FRAMEWORK_PATH=/usr/local/ophidia/oph-cluster/oph-analytics-framework/

# docker run ARGs
OPH_COMPONENT_MEM_LIMIT="$((${MEMORY:-2048}/2))"
[ -z "$DEBUG" ] && DEBUG="" || DEBUG="-d"

# start mysql
mysqld --user=mysql & &> /dev/null
while [ ! -S /var/lib/mysql/mysql.sock ]; do sleep 1; done

MYSQL_PWD="abcd" mysql -u root -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"

su - ophidia <<EOF
    HOSTNAME=`hostname -I | awk '{print $1}'`
    export OPH_USER="oph-test"
    export OPH_SERVER_PORT="11732"
    export OPH_SERVER_HOST=$HOSTNAME
    export OPH_PASSWD="abcd"
    export HDF5_USE_FILE_LOCKING=FALSE

    # Replace hostname in configuration files
    echo "Replace host ${myhost} in configuration files"
    sed -i "/OPHDB_HOST/c\OPHDB_HOST=${myhost}" $SERVER_PATH/etc/ophidiadb.conf
    sed -i "/HOST/c\HOST=${myhost}" $SERVER_PATH/etc/server.conf
    sed -i "/OPHDB_HOST/c\OPHDB_HOST=${myhost}" $FRAMEWORK_PATH/etc/oph_configuration
    sed -i "/DIMDB_HOST/c\DIMDB_HOST=${myhost}" $FRAMEWORK_PATH/etc/oph_configuration
    sed -i "/SOAP_HOST/c\SOAP_HOST=${myhost}" $FRAMEWORK_PATH/etc/oph_soap_configuration
    sed -i "s/MEMORY=.*/MEMORY=${OPH_COMPONENT_MEM_LIMIT}/g" $FRAMEWORK_PATH/etc/oph_configuration
    sed -i "s/OPH_MAX_HOSTS=1/OPH_MAX_HOSTS=100/g" $SERVER_PATH/authz/users/oph-test/user.dat

    # start oph_server
    $SERVER_PATH/bin/oph_server $DEBUG &>/dev/null &
    wait
EOF
#Save hostname in user file
#> $HOME/.ophidia/server.run
#echo "$myhost" >> $HOME/.ophidia/server.run