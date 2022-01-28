#!/bin/bash

OPH_COMPONENT_MEM_LIMIT="$((${MEMORY:-2048}/2))"
[ -z "$DEBUG" ] && DEBUG="" || DEBUG="-d"

mysqld --user=mysql & &> /dev/null
while [ ! -S /var/lib/mysql/mysql.sock ]; do sleep 1; done
MYSQL_PWD="abcd" mysql -u root -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"

HOSTNAME=`hostname -I`
sed -i "s/#ServerName.*/ServerName ${HOSTNAME}/g" /etc/httpd/conf/httpd.conf
/usr/sbin/apachectl -DBACKGROUND

su - ophidia <<EOF

sed -i "s/MEMORY_BUFFER=.*/MEMORY_BUFFER=${OPH_COMPONENT_MEM_LIMIT}/g" /usr/local/ophidia/oph-cluster/oph-io-server/etc/oph_ioserver.conf
sed -i "s/MEMORY=.*/MEMORY=${OPH_COMPONENT_MEM_LIMIT}/g" /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_configuration

cd /home/ophidia/
export OPH_USER="oph-test"
export OPH_SERVER_PORT="11732"
export OPH_SERVER_HOST="127.0.0.1"
export OPH_PASSWD="abcd"

export HDF5_USE_FILE_LOCKING=FALSE

/usr/local/ophidia/oph-cluster/oph-io-server/bin/oph_io_server -d -i 1 > /dev/null 2>&1 &
/usr/local/ophidia/oph-server/bin/oph_server $DEBUG &>/dev/null &
wait
EOF

