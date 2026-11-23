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
taskid=${1}
nhosts=${2}
log=${3}
hostpartition=${4}
queue=${5}
serverid=${6}
workflowid=${7}
project=${8}
taskname=${9}
ndbms=${10}

# Const
OPH_SERVER_LOCATION=/usr/local/ophidia/oph-server
IO_SERVER_LAUNCHER=${OPH_SERVER_LOCATION}/etc/script/start_ioserver.sh
IO_SERVER_FLUSHER=${OPH_SERVER_LOCATION}/etc/script/stop_ioserver.sh
SCRIPT_DIR=${HOME}/.ophidia

# Body
mkdir -p ${SCRIPT_DIR}

echo "Start ${nhosts} I/O servers" > ${log}

for myid in $(seq 1 $nhosts)
do
	START_SCRIPT_FILE=${SCRIPT_DIR}/${serverid}${taskid}.${myid}.submit.sh
	
	> ${START_SCRIPT_FILE}
	echo "Create launcher for job ${myid}" >> ${log}
	echo "#!/bin/bash" >> ${START_SCRIPT_FILE}
	echo "${IO_SERVER_LAUNCHER} ${hostpartition} ${myid} ${taskid} ${serverid}" >> ${START_SCRIPT_FILE}
	chmod +x ${START_SCRIPT_FILE}

	echo "Start launcher for job ${myid}" >> ${log}
	${START_SCRIPT_FILE} >>${log} 2>>${log} </dev/null &
done

wait $(jobs -p)

echo "Stop ${nhosts} I/O servers" >> ${log}

STOP_SCRIPT_FILE=${SCRIPT_DIR}/${serverid}${taskid}.stop.sh
for myid in $(seq 1 $nhosts)
do
	rm -f ${SCRIPT_DIR}/${serverid}${taskid}.${myid}.submit.sh
	
	> ${STOP_SCRIPT_FILE}
	echo "Create destroyer for job ${myid}" >> ${log}
	echo "#!/bin/bash" >> ${STOP_SCRIPT_FILE}
	echo "${IO_SERVER_FLUSHER} ${hostpartition} ${myid}" >> ${STOP_SCRIPT_FILE}
	chmod +x ${STOP_SCRIPT_FILE}

	echo "Start destroyer for job ${myid}" >> ${log}
	${STOP_SCRIPT_FILE} >>${log} 2>>${log} </dev/null
done
rm -f ${STOP_SCRIPT_FILE}

exit 0
