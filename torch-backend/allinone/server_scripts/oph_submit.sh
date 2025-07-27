#
#    Ophidia Server
#    Copyright (C) 2012-2021 CMCC Foundation
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
ncores=${2}
log=${3}
submissionstring=${4}
queue=${5}
serverid=${6}
workflowid=${7}
project=${8}

# Const
FRAMEWORK_PATH=/usr/local/ophidia/oph-cluster/oph-analytics-framework
SCRIPT_DIR=${HOME}/.ophidia
SCRIPT_FILE=${SCRIPT_DIR}/${serverid}${taskid}.submit.sh

# Body
mkdir -p ${HOME}/.ophidia

> ${SCRIPT_FILE}
echo "#!/bin/bash" >> ${SCRIPT_FILE}
echo "${FRAMEWORK_PATH}/bin/oph_analytics_framework \"${submissionstring}\"" >> ${SCRIPT_FILE}
chmod +x ${SCRIPT_FILE}

mpiexec.hydra -n ${ncores} -outfile-pattern ${log} -errfile-pattern ${log} ${SCRIPT_FILE}
chmod +r ${log}

if [ $? -ne 0 ]; then
	echo "Unable to submit ${SCRIPT_FILE}"
	rm -f ${SCRIPT_FILE}
	exit 1
fi

rm -f ${SCRIPT_FILE}

exit 0

