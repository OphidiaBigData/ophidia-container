#!/bin/bash

function finalize_deploy()
{
	export OPH_SERVER_HOST="127.0.0.1"
	export OPH_SERVER_PORT="11732"
	export OPH_USER="oph-test"
	export OPH_PASSWD="abcd"
	cd /usr/local/ophidia
	if [[ $CLIENT_SERVICE == "terminal" ]]
	then
		su -c ". ~/.bashrc; /usr/local/ophidia/oph-terminal/bin/oph_term" ophidia
	elif [[ $CLIENT_SERVICE == "terminal_only" ]]
	then
		su -c ". ~/.bashrc; /usr/local/ophidia/oph-terminal/bin/oph_term -H $_SERVER_HOST -P $_SERVER_PORT -u $_USER -p $_PASSWD" ophidia
	elif [[ $CLIENT_SERVICE == "jupyter" ]]
	then
		su -c ". ~/.bashrc; jupyter-lab --no-browser --notebook-dir=/usr/local/ophidia --port=$JUPYTER_PORT --ip=$HOSTNAME" -s /bin/bash ophidia
	elif [[ $CLIENT_SERVICE == "python" ]]
	then
		su -c ". ~/.bashrc; /usr/local/ophidia/env/bin/python" ophidia
	fi
}

trap finalize_deploy EXIT

if [ ${JUPYTER} == "yes" ]
then
	CLIENT_SERVICE=${DEPLOY:-'jupyter'}
elif [ $PYTHON == "yes" ]
then
	CLIENT_SERVICE=${DEPLOY:-'python'}
else
	CLIENT_SERVICE=${DEPLOY:-'terminal'}
fi

[ -z "${DEBUG}" ] && DEBUG="" || DEBUG="-d"
[ -z "${IO_DEBUG}" ] && IO_DEBUG="" || IO_DEBUG="-D"

[ -z "${NO_MEMORY_CHECK}" ] && NO_MEMORY_CHECK="" || NO_MEMORY_CHECK="-m"
echo "${NO_MEMORY_CHECK}" > /usr/local/ophidia/oph-cluster/oph-io-server/etc/memory_check

OPH_COMPONENT_MEM_LIMIT="$((${MEMORY:-2048}/2))"
if [ ${CLIENT_SERVICE} == "terminal_only" ]
then
	_SERVER_HOST=${OPH_SERVER_HOST:-'172.17.0.3'}
	_SERVER_PORT=${OPH_SERVER_PORT:-'11732'}
	_USER=${OPH_USER:-'oph-test'}
	_PASSWD=${OPH_PASSWD:-'abcd'}
	exit
elif [ ${CLIENT_SERVICE} == "jupyter" ]
then
	JUPYTER_PORT=${UI_PORT:=8888}
fi

[ -d '/var/run/slurm' ] && SLURM_BUILD=true || SLURM_BUILD=false

service mysql start
while [ ! -S /var/run/mysqld/mysqld.sock ]; do sleep 1; done
MYSQL_PWD="abcd" mysql -u root -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"

HOSTNAME=`hostname -I`
echo "ServerName ${HOSTNAME}" >> /etc/apache2/apache2.conf
service apache2 restart
sed -i "s/\/127.0.0.1/\/${HOSTNAME/' '/}/g" /usr/local/ophidia/oph-server/etc/server.conf
sed -i "s/\/127.0.0.1/\/${HOSTNAME/' '/}/g" /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_configuration

if ${SLURM_BUILD} ; then
	echo "127.0.0.1 localhost localhost.localdomain" >> /etc/hosts
	chmod go-w /var/log/
	sudo -u munge /usr/sbin/munged >/dev/null
	sudo -u munge munge -n >/dev/null
	sudo -u munge munge -n | unmunge >/dev/null
	sudo -u munge remunge >/dev/null
fi

su - ophidia <<EOF
. ~/.bashrc;

if ${SLURM_BUILD} ; then
	sed -i "s/ControlAddr=.*/ControlAddr=${HOSTNAME}/g" /usr/local/ophidia/extra/etc/slurm.conf
	sed -i "s/CPUs=.*/CPUs=$(grep processor /proc/cpuinfo | wc -l)/g" /usr/local/ophidia/extra/etc/slurm.conf
	sed -i '/mpiexec.hydra /s/^/#/' /usr/local/ophidia/oph-server/etc/script/oph_submit.sh
	sed -i '/LAUNCHER/s/^#//g' /usr/local/ophidia/oph-server/etc/script/oph_submit.sh
	/usr/local/ophidia/extra/sbin/slurmd >/dev/null
	/usr/local/ophidia/extra/sbin/slurmctld >/dev/null
fi

sed -i "s/MEMORY_BUFFER=.*/MEMORY_BUFFER=${OPH_COMPONENT_MEM_LIMIT}/g" /usr/local/ophidia/oph-cluster/oph-io-server/etc/oph_ioserver.conf
sed -i "s/MEMORY=.*/MEMORY=${OPH_COMPONENT_MEM_LIMIT}/g" /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/oph_configuration

if [ "${MAIN_PARTITION}" = "yes" ] ; then
	/usr/local/ophidia/oph-cluster/oph-io-server/bin/oph_io_server ${IO_DEBUG} ${NO_MEMORY_CHECK} -i 1 >/dev/null 2>&1 </dev/null &
fi

/usr/local/ophidia/oph-server/bin/oph_server ${DEBUG} >/dev/null 2>&1 </dev/null &

sleep 1
EOF

