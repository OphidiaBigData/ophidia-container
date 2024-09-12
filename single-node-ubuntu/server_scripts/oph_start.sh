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

# Const
OPH_SERVER_LOCATION=/usr/local/ophidia/oph-server
IO_SERVER_LAUNCHER=${OPH_SERVER_LOCATION}/etc/script/start_ioserver.sh
IO_SERVER_FLUSHER=${OPH_SERVER_LOCATION}/etc/script/stop_ioserver.sh
SCRIPT_DIR=/usr/local/ophidia/.ophidia
START_SCRIPT_FILE=${SCRIPT_DIR}/${serverid}${taskid}.start.sh
STOP_SCRIPT_FILE=${SCRIPT_DIR}/${serverid}${taskid}.finalize.sh

# Body
mkdir -p ${SCRIPT_DIR}

for myid in {1..$nhosts}
do

	> ${START_SCRIPT_FILE}
	echo "#!/bin/bash" >> ${START_SCRIPT_FILE}
	echo "${IO_SERVER_LAUNCHER} ${hostpartition} ${myid}" >> ${START_SCRIPT_FILE}
	chmod +x ${START_SCRIPT_FILE}

	${START_SCRIPT_FILE} >> ${log} 2>>&1 < /dev/null

done

for i in {1..$nhosts}
do

	> ${STOP_SCRIPT_FILE}
	echo "#!/bin/bash" >> ${STOP_SCRIPT_FILE}
	echo "${IO_SERVER_FLUSHER} ${hostpartition} ${myid}" >> ${STOP_SCRIPT_FILE}
	chmod +x ${STOP_SCRIPT_FILE}

	${STOP_SCRIPT_FILE} >> ${log} 2>>&1 < /dev/null

done

rm -f ${START_SCRIPT_FILE}
rm -f ${STOP_SCRIPT_FILE}

exit 0

