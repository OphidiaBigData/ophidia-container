#!/bin/bash

function finalize_deploy()
{
	cd /usr/local/ophidia
	if [[ $CLIENT_SERVICE == "terminal" ]]
	then
		su -c "/usr/local/ophidia/oph-terminal/bin/oph_term -H 127.0.0.1 -u oph-test -p abcd -P 11732" ophidia
	elif [[ $CLIENT_SERVICE == "terminal_only" ]]
	then
		su -c "/usr/local/ophidia/oph-terminal/bin/oph_term -H $SERVER_IP -u $OPH_USER -p $OPH_PWD -P $SERVER_PORT" ophidia
	elif [[ $CLIENT_SERVICE == "jupyter" ]]
	then
		export OPH_USER="oph-test"
		export OPH_SERVER_PORT="11732"
		export OPH_SERVER_HOST="127.0.0.1"
		export OPH_PASSWD="abcd"
		su -c "jupyter-lab --no-browser --notebook-dir=/usr/local/ophidia --port=$JUPYTER_PORT --ip=$HOSTNAME &" ophidia
		wait
	fi
}

trap finalize_deploy EXIT

if [ $JUPYTER == "no" ]
then
	CLIENT_SERVICE=${DEPLOY:-'terminal'}
else
	CLIENT_SERVICE=${DEPLOY:-'jupyter'}
fi

if [ $CLIENT_SERVICE == "terminal" ]
then
	OPH_COMPONENT_MEM_LIMIT="$((${MEMORY:-2048}/2))"
	[ -z "$DEBUG" ] && DEBUG="" || DEBUG="-d"
elif [ $CLIENT_SERVICE == "terminal_only" ]
then
	SERVER_IP=${OPH_SERVER_HOST:-'172.17.0.3'}
	SERVER_PORT=${OPH_SERVER_PORT:-'11732'}
	OPH_USER=${OPH_USER:-'oph-test'}
	OPH_PWD=${OPH_PASSWD:-'abcd'}
	exit
elif [ $CLIENT_SERVICE == "jupyter" ]
then
	JUPYTER_PORT=${UI_PORT:=8888}
	OPH_COMPONENT_MEM_LIMIT="$((${MEMORY:-2048}/2))"
	[ -z "$DEBUG" ] && DEBUG="" || DEBUG="-d"
fi

[ -d '/var/run/slurm' ] && SLURM_BUILD=true || SLURM_BUILD=false

mysqld --user=mysql & &> /dev/null
while [ ! -S /var/lib/mysql/mysql.sock ]; do sleep 1; done
MYSQL_PWD="abcd" mysql -u root -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"

HOSTNAME=`hostname -I`
sed -i "s/#ServerName.*/ServerName ${HOSTNAME}/g" /etc/httpd/conf/httpd.conf
/usr/sbin/apachectl -DBACKGROUND

if $SLURM_BUILD ; then
	echo "127.0.0.1 localhost localhost.localdomain" >> /etc/hosts
	chmod go-w /var/log/
	sudo -u munge /usr/sbin/munged >/dev/null
	sudo -u munge munge -n >/dev/null
	sudo -u munge munge -n | unmunge >/dev/null
	sudo -u munge remunge >/dev/null
fi

su - ophidia <<EOF
if $SLURM_BUILD ; then
	sed -i "s/ControlAddr=.*/ControlAddr=${HOSTNAME}/g" /usr/local/ophidia/extra/etc/slurm.conf
	sed -i "s/CPUs=.*/CPUs=$(grep processor /proc/cpuinfo | wc -l)/g" /usr/local/ophidia/extra/etc/slurm.conf
	sed -i '/mpiexec.hydra /s/^/#/' /usr/local/ophidia/oph-server/etc/script/oph_submit.sh
	sed -i '/LAUNCHER/s/^#//g' /usr/local/ophidia/oph-server/etc/script/oph_submit.sh
	/usr/local/ophidia/extra/sbin/slurmd >/dev/null
	/usr/local/ophidia/extra/sbin/slurmctld >/dev/null
fi

sed -i "s/MEMORY_BUFFER=.*/MEMORY_BUFFER=${OPH_COMPONENT_MEM_LIMIT}/g" /usr/local/ophidia/oph-cluster/oph-io-server/etc/oph_ioserver.conf
sed -i "s/MEMORY=.*/MEMORY=${OPH_COMPONENT_MEM_LIMIT}/g" /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_configuration

/usr/local/ophidia/oph-cluster/oph-io-server/bin/oph_io_server -d -i 1 > /dev/null 2>&1 &
/usr/local/ophidia/oph-server/bin/oph_server $DEBUG &>/dev/null &
sleep 1
EOF

