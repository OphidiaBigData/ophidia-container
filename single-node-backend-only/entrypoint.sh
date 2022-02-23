#!/bin/bash

CONTAINERIZER=${TECH:-'docker'}
if [ $CONTAINERIZER == "docker" ]
then
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

elif [ $CONTAINERIZER == "udocker" ]
then
	OPH_COMPONENT_MEM_LIMIT="$((${MEMORY:-2048}/2))"
	[ -z "$DEBUG" ] && DEBUG="" || DEBUG="-d"

	chmod 777 /var/lib/mysql
	chmod 777 /var/run/mysqld
	rm -rf /var/lib/mysql/mysql.sock.lock
	rm -rf /var/lib/mysql/mysql.sock
	rm -rf /var/run/mysqld/*
	echo "port = 3309" >> /etc/my.cnf
	sed -i "s/OPHDB_PORT=.*/OPHDB_PORT=3309/" /usr/local/ophidia/oph-server/etc/ophidiadb.conf
	sed -i "s/OPHDB_PORT=.*/OPHDB_PORT=3309/" /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_configuration
	sed -i "s/DIMDB_PORT=.*/DIMDB_PORT=3309/" /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_configuration
	echo "bind-address = 0.0.0.0" >> /etc/my.cnf
	sed -i "s/socket=.*/socket=\/var\/run\/mysqld\/mysql.sock/" /etc/my.cnf

	mysqld --user=mysql & &> /dev/null
	while [ ! -S /var/run/mysqld/mysql.sock ]; do sleep 1; done
	MYSQL_PWD="abcd" mysql -u root -S /var/run/mysqld/mysql.sock -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"

	#HOSTNAME=`hostname -I`
	#sed -i "s/#ServerName.*/ServerName ${HOSTNAME}/g" /etc/httpd/conf/httpd.conf
	#/usr/sbin/apachectl -DBACKGROUND

	su - ophidia <<EOF

	sed -i "s/MEMORY_BUFFER=.*/MEMORY_BUFFER=${OPH_COMPONENT_MEM_LIMIT}/g" /usr/local/ophidia/oph-cluster/oph-io-server/etc/oph_ioserver.conf
	sed -i "s/MEMORY=.*/MEMORY=${OPH_COMPONENT_MEM_LIMIT}/g" /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_configuration

	cd /usr/local/ophidia/
	HOSTNAME=`hostname -I | awk '{print $1}'`
	export OPH_USER="oph-test"
	export OPH_SERVER_PORT="11732"
	export OPH_SERVER_HOST=$HOSTNAME
	export OPH_PASSWD="abcd"

	export HDF5_USE_FILE_LOCKING=FALSE

	/usr/local/ophidia/oph-cluster/oph-io-server/bin/oph_io_server -d -i 1 > /dev/null 2>&1 &
	/usr/local/ophidia/oph-server/bin/oph_server $DEBUG &>/dev/null &
	wait
EOF

fi

