FROM centos:7

LABEL author="CMCC Foundation" description="Ophidia HPDA Framework"

ARG slurm=no
ARG thread_safe=yes
ARG jupyter=no
ARG version=1.8.0
ARG devel=no
ARG branch=master

USER root

COPY CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo

RUN rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022

RUN cd / && \
	yum -y update yum && \
	yum -y update && \
	yum -y install epel-release && \
	yum -y install http://repo.mysql.com/mysql57-community-release-el7.rpm && \
	yum -y install mysql-community-devel mysql-community-server mysql-community-client && \
	yum -y clean all

RUN chmod -R 777 /var/lib/mysql && \
	chmod 777 /var/log/ && \
	mkdir -p /repo && \
	chmod -R 777 /repo && \
	mkdir -p /usr/local/ophidia && \
	mkdir -p /usr/local/ophidia/extra && \
	useradd -r ophidia -d /usr/local/ophidia && \
	usermod -u 1000 ophidia && \
	groupmod -g 1000 ophidia && \
	chown -R ophidia:ophidia /usr/local/ophidia

ADD server_scripts/oph_submit.sh /offline_ophidia/

USER mysql

RUN mysqld --initialize-insecure && \
	mysqld & &> /dev/null ;\
	while [ ! -S /var/lib/mysql/mysql.sock ]; do sleep 1; done && \
	mysqladmin -u root password abcd && \
	MYSQL_PWD="abcd" mysql -u root -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));" && \
	MYSQL_PWD="abcd" mysql -u root -e "CREATE DATABASE ophidiadb;" && \
	MYSQL_PWD="abcd" mysql -u root -e "CREATE DATABASE oph_dimensions;" && \
	cd /repo && \
	curl -s -O -k https://raw.githubusercontent.com/OphidiaBigData/ophidia-analytics-framework/master/etc/ophidiadb.sql && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb < /repo/ophidiadb.sql && \
	rm -rf /repo/*

USER root

RUN yum -y install compat-guile18 compat-guile18-devel flex flex-devel guile-devel guile bison openssl wget sed gcc make file && \
	#LIBMATHEVAL
	cd /repo && \
	curl -s -O http://ftp.gnu.org/gnu/libmatheval/libmatheval-1.1.11.tar.gz && \
	tar -xzf libmatheval-1.1.11.tar.gz && \
	cd /repo/libmatheval-1.1.11 && \
	./configure --prefix=/usr/local/ophidia/extra > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	#OPHIDIA PRIMITIVES
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-primitives/releases/download/v$version/ophidia-primitives-$version-0.el7.centos.x86_64.rpm && \
	yum -y install ophidia-primitives-*.rpm && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	rm -rf /repo/* && \
	cp /usr/local/ophidia/oph-cluster/oph-primitives/lib/liboph_*.so /usr/lib64/mysql/plugin && \
	sed -i '/GRANT/d' /usr/local/ophidia/oph-cluster/oph-primitives/etc/create_func.sql && \
	yum -y clean all

USER mysql
RUN mysqld & &> /dev/null ;\
	while [ ! -S /var/lib/mysql/mysql.sock ]; do sleep 1; done && \
	MYSQL_PWD="abcd" mysql -u root mysql < /usr/local/ophidia/oph-cluster/oph-primitives/etc/create_func.sql && \
	MYSQL_PWD="abcd" mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'abcd' WITH GRANT OPTION;" && \
	MYSQL_PWD="abcd" mysql -u root -e "FLUSH PRIVILEGES;" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO hostpartition (partitionname) VALUES ('main');"

USER root

#OPHIDIA IO SERVER
RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	yum -y install gcc-c++ zlib zlib-devel mpich-3.0.x86_64 mpich-3.0-devel.x86_64 mpich-3.0-autoload.x86_64 && \
	yum -y clean all ; else \
	yum -y install hdf5-devel hdf5-mpich-devel && \
	yum -y install netcdf-devel netcdf-mpich-devel && \
	yum -y install mpich-3.0-autoload.x86_64 && \
	yum -y clean all ; fi
#HDF5-MPICH THREAD-SAFE
ENV MODULEPATH=/usr/share/Modules/modulefiles:/etc/modulefiles
RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	eval `/usr/bin/modulecmd bash load /etc/modulefiles/mpi/mpich-3.0-x86_64` && \
	cd /repo && \
	wget -q https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.1/src/hdf5-1.12.1.tar.gz && \
        gzip -cd hdf5-1.12.1.tar.gz | tar xf - && \
	cd hdf5-1.12.1/ && \
	./configure --prefix=/usr/local/ophidia/extra/hdf5-ts/ --enable-parallel --enable-threadsafe --enable-unsupported --with-zlib > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /repo/* ; fi
#NETCDF-MPICH
RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	yum -y install git && yum -y clean all && \
	cd /repo && \
	git clone https://github.com/Unidata/netcdf-c.git && \
	cd netcdf-c && \
	git checkout tags/v4.4.0 && \
	eval `/usr/bin/modulecmd bash load /etc/modulefiles/mpi/mpich-3.0-x86_64` && \
	CC=/usr/lib64/mpich/bin/mpicc CPPFLAGS="-I/usr/local/ophidia/extra/hdf5-ts/include/" LDFLAGS="-L/usr/local/ophidia/extra/hdf5-ts/lib/" LIBS=-ldl H5DIR=/usr/local/ophidia/extra/hdf5-ts/ ./configure --prefix=/usr/local/ophidia/extra/netcdf-ts --enable-netcdf4 --enable-parallel-tests > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /repo/* ; fi

RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia I/O Server" && \
	yum -y install bison\* flex\* autoconf automake libtool\* && yum -y clean all ; fi

USER ophidia

RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	mkdir /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/ophidia-io-server && \
	cd ophidia-io-server && \
	git checkout $branch && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=/usr/local/ophidia/oph-cluster/oph-io-server --with-netcdf-path=/usr/local/ophidia/extra/netcdf-ts/ --enable-parallel-nc4 > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	mkdir -p /usr/local/ophidia/oph-cluster/oph-io-server/data1/var && \
	mkdir -p /usr/local/ophidia/oph-cluster/oph-io-server/data1/log && \
	rm -rf /usr/local/ophidia/src ; fi

USER root

RUN if [ "$thread_safe" != "yes" ] && [ "$devel" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-io-server/releases/download/v$version/ophidia-io-server-$version-0.el7.centos.x86_64.rpm && \
	yum -y install ophidia-io-server-*.rpm && yum -y clean all && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	sed -i "s/127.0.0.1/0.0.0.0/g" /usr/local/ophidia/oph-cluster/oph-io-server/etc/oph_ioserver.conf && \
	rm -rf /repo/* ; fi

USER mysql

RUN mysqld & &> /dev/null ;\
	while [ ! -S /var/lib/mysql/mysql.sock ]; do sleep 1; done && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO host (hostname, cores, memory) SELECT '127.0.0.1', 4, 1 FROM DUAL WHERE NOT EXISTS (SELECT hostname FROM host WHERE hostname='127.0.0.1') LIMIT 1;" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT IGNORE INTO hashost (idhostpartition, idhost) SELECT 1, host.idhost FROM host WHERE hostname='127.0.0.1';" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO dbmsinstance (idhost, login, password, port, ioservertype) SELECT host.idhost, 'root', 'abcd', 65000, 'ophidiaio_memory' FROM host WHERE hostname='127.0.0.1' AND NOT EXISTS (SELECT * FROM dbmsinstance INNER JOIN host ON host.idhost = dbmsinstance.idhost WHERE hostname='127.0.0.1' AND port=65000) LIMIT 1;" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "UPDATE host SET status='up' WHERE hostname='127.0.0.1';"

USER root

#OPHIDIA ANALYTICS FRAMEWORK
RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia Analytics Framework" && \
	yum -y install jansson\* libxml2\* openssl-devel gsl gsl-devel libcurl libcurl-devel cfitsio cfitsio-devel && yum -y clean all && \
	mkdir -p /var/www/html/ophidia && \
	chown ophidia:ophidia /var/www/html/ophidia ; fi

USER ophidia

RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	mkdir -p /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/ophidia-analytics-framework && \
	cd ophidia-analytics-framework && \
	git checkout $branch && \
	eval `/usr/bin/modulecmd bash load /etc/modulefiles/mpi/mpich-3.0-x86_64` && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=/usr/local/ophidia/oph-cluster/oph-analytics-framework --enable-parallel-netcdf --with-netcdf-path=/usr/local/ophidia/extra/netcdf-ts/ --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia --with-ophidiaio-server-path=/usr/local/ophidia/oph-cluster/oph-io-server --enable-cfitsio > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /usr/local/ophidia/src && \
	mkdir -p /usr/local/ophidia/oph-cluster/oph-analytics-framework/log ; fi

USER root

RUN if [ "$thread_safe" != "yes" ] && [ "$devel" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-analytics-framework/releases/download/v$version/ophidia-analytics-framework-$version-0.el7.centos.x86_64.rpm && \
	yum -y install ophidia-analytics-framework-*.rpm && yum -y clean all && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	chown -R ophidia:ophidia /var/www/html/ophidia && \
	rm -rf /repo/* ; fi

#CJOSE
RUN if [ "$thread_safe" != "yes" ] && [ "$devel" != "yes" ] ; then yum -y install openssl-devel jansson-devel && yum -y clean all ; fi && \
	cd /repo && \
	curl -s -LOJk https://github.com/cisco/cjose/archive/0.4.1.tar.gz && \
	tar -xzf cjose-0.4.1.tar.gz && \
	cd cjose-0.4.1 && \
	./configure --prefix=/usr/local/ophidia/extra > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /repo/*

#OPHIDIA SERVER
RUN if [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia Server" && \
	yum -y install compat-guile18 compat-guile18-devel flex-devel guile-devel guile bison openssl-devel curl libcurl-devel libxml2\* jansson\* libssh2\* && yum -y clean all && \
	mkdir -p /var/www/html/ophidia && \
	chown -R ophidia:ophidia /var/www/html/ophidia ; fi

USER ophidia

RUN if [ "$devel" = "yes" ] ; then \
	mkdir -p /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/ophidia-server && \
	cd ophidia-server && \
	git checkout $branch && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=/usr/local/ophidia/oph-server --with-framework-path=/usr/local/ophidia/oph-cluster/oph-analytics-framework --enable-webaccess --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia --with-ws-hostname=localhost --with-matheval-path=/usr/local/ophidia/extra/lib > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	mv authz /usr/local/ophidia/oph-server/ && \
	mkdir -p /usr/local/ophidia/oph-server/log && \
	mkdir -p /usr/local/ophidia/oph-server/authz/sessions && \
	mkdir -p /var/www/html/ophidia/sessions && \
	touch /usr/local/ophidia/oph-server/log/server.log && \
	rm -rf /usr/local/ophidia/src ; fi

USER root

RUN if [ "$devel" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-server/releases/download/v$version/ophidia-server-$version-0.el7.centos.x86_64.rpm && \
	yum -y install ophidia-server-*.rpm && yum -y clean all && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	chown -R ophidia:ophidia /var/www/html/ophidia && \
	touch /usr/local/ophidia/oph-server/log/server.log && \
	sed -i "s/OPH_MAX_CORES=.*/OPH_MAX_CORES=0/g" /usr/local/ophidia/oph-server/authz/users/oph-test/user.dat && \
	sed -i "s/OPH_MAX_CORES=.*/OPH_MAX_CORES=0/g" /usr/local/ophidia/oph-server/authz/users/framework/user.dat && \
	rm -rf /repo/* ; fi

#certificates generation and installation
RUN openssl req -newkey rsa:1024 \
	    -passout pass:abcd \
	    -subj "/" -sha1 \
	    -keyout rootkey.pem \
	    -out rootreq.pem && \
	openssl x509 -req -in rootreq.pem \
	    -passin pass:abcd \
	    -sha1 -extensions v3_ca \
	    -signkey rootkey.pem \
	    -out rootcert.pem &&\
	cat rootcert.pem rootkey.pem  > cacert.pem && \
	openssl req -newkey rsa:1024 \
	    -passout pass:abcd \
	    -subj "/" -sha1 \
	    -keyout serverkey.pem \
	    -out serverreq.pem && \
	openssl x509 -req \
	    -in serverreq.pem \
	    -passin pass:abcd \
	    -sha1 -extensions usr_cert \
	    -CA cacert.pem  \
	    -CAkey cacert.pem \
	    -CAcreateserial \
	    -out servercert.pem && \
	cat servercert.pem serverkey.pem rootcert.pem > myserver.pem && \
	mkdir -p /usr/local/ophidia/oph-server/etc/cert && \
	cp cacert.pem myserver.pem  /usr/local/ophidia/oph-server/etc/cert && \
	rm cacert.pem myserver.pem

#WEB SERVER
RUN yum -y install mod_ssl php-mysql php-devel php-gd php-pecl-memcache php-pspell php-snmp php-xmlrpc php-xml && \
	yum -y clean all && \
	mkdir -p /etc/httpd/conf/ssl && \
	cd /etc/httpd/conf/ssl && \
	openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -out server.crt -keyout server.key -subj "/"

#OPHIDIA TERMINAL
RUN if [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia Terminal" && \
	yum -y install graphviz\* gtk2\* jansson\* libxml2\* openssl-devel curl libcurl-devel policycoreutils-python readline\* && yum -y clean all && \
	mkdir -p /var/www/html/ophidia && \
	chown ophidia:ophidia /var/www/html/ophidia ; fi

USER ophidia

RUN if [ "$devel" = "yes" ] ; then \
	mkdir -p /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/ophidia-terminal && \
	cd ophidia-terminal && \
	git checkout $branch && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=/usr/local/ophidia/oph-terminal --disable-xml-ssl-check --disable-xml-removal > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /usr/local/ophidia/src ; fi

USER root

RUN if [ "$devel" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-terminal/releases/download/v$version/ophidia-terminal-$version-0.el7.centos.x86_64.rpm && \
	yum -y install ophidia-terminal-*.rpm && yum -y clean all && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	rm -rf /repo/*; fi

#OPERATORS_FIXES
RUN cd /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/operators_xml/ && \
	sed -i "s/mysql_table|//" OPH_IMPORTNC_operator_1.0.xml OPH_INSTANCES_operator_1.0.xml OPH_RANDCUBE_operator_1.0.xml && \
	sed -i "s/default=\"mysql_table/default=\"ophidiaio_memory/" OPH_IMPORTNC_operator_1.0.xml OPH_RANDCUBE_operator_1.0.xml && \
	sed -i "s/ophidiaio_memory|all/ophidiaio_memory/" OPH_INSTANCES_operator_1.0.xml && \
	sed -i "s/values=\"ophidiaio_memory\">ioserver_filter/values=\"all|ophidiaio_memory\">ioserver_filter/" OPH_INSTANCES_operator_1.0.xml && \
	sed -i "s/maxvalue=\"10000\">limit_filter/maxvalue=\"100000000\">limit_filter/" OPH_EXPLORECUBE_operator_1.0.xml && \
	cd /var/www/html/ophidia/operators_xml && \
	sed -i "s/mysql_table|//" OPH_IMPORTNC_operator_1.0.xml OPH_INSTANCES_operator_1.0.xml OPH_RANDCUBE_operator_1.0.xml && \
	sed -i "s/default=\"mysql_table/default=\"ophidiaio_memory/" OPH_IMPORTNC_operator_1.0.xml OPH_RANDCUBE_operator_1.0.xml && \
	sed -i "s/ophidiaio_memory|all/ophidiaio_memory/" OPH_INSTANCES_operator_1.0.xml && \
	sed -i "s/values=\"ophidiaio_memory\">ioserver_filter/values=\"all|ophidiaio_memory\">ioserver_filter/" OPH_INSTANCES_operator_1.0.xml && \
	sed -i "s/maxvalue=\"10000\">limit_filter/maxvalue=\"100000000\">limit_filter/" OPH_EXPLORECUBE_operator_1.0.xml

ENV OPH_TERM_VIEWER=coloured
ENV OPH_TERM_FORMAT=extended_compact

#PyOphidia
RUN if [ "$devel" = "yes" ] ; then \
	yum -y install python3 && \
	yum -y clean all ; fi

USER ophidia

RUN if [ "$devel" = "yes" ] ; then \
	echo "Using online source code for PyOphidia" && \
	mkdir -p /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/PyOphidia && \
	cd PyOphidia && \
	git checkout $branch ; fi

USER root

RUN if [ "$devel" = "yes" ] ; then \
	cd /usr/local/ophidia/src/PyOphidia && \
	python3 setup.py install &&  \
	rm -rf /usr/local/ophidia/src ; fi

RUN if [ "$slurm" = "no" ] ; then echo "No internal resource manager" ; else echo "Slurm will be the internal resource manager" ; fi
#SHELL ["/bin/bash", "-c"]

RUN if [ "$slurm" = "yes" ] ; then \
	yum -y install munge munge-devel munge-libs && \
	yum -y clean all && \
	dd if=/dev/urandom bs=1 count=1024 > /etc/munge/munge.key && \
	chmod 400 /etc/munge/munge.key && \
	mkdir -p /var/run/munge && chmod 755 /var/run/munge && \
	mkdir -p /var/log/munge && chmod 700 /var/log/munge && \
	mkdir -p /var/lib/munge && chmod 711 /var/lib/munge && \
	mkdir -p /etc/munge && chmod 700 /etc/munge && \
	chown -R munge:munge /etc/munge && \
	chown -R munge:munge /var/lib/munge && \
	chown -R munge:munge /var/log/munge && \
	chown -R munge:munge /var/run/munge && \
	echo "127.0.0.1 localhost localhost.localdomain" >> /etc/hosts ; else echo "Skipping Munge" ; fi

RUN if [ "$slurm" = "yes" ] ; then \
	yum -y install sudo bzip2 slurm python3 openssl openssl-devel pam-devel numactl numactl-devel hwloc hwloc-devel lua lua-devel readline-devel rrdtool-devel ncurses-devel man2html libibmad libibumad && \
	yum -y remove slurm && \
	yum -y clean all && \
	mkdir -p /repo && cd /repo && \
	curl -k -O https://download.schedmd.com/slurm/slurm-20.11.7.tar.bz2 && \
	mkdir -p /usr/local/ophidia/extra/etc && \
	bunzip2 slurm-20.11.7.tar.bz2 && \
	tar -xf slurm-20.11.7.tar ; else echo "Skipping Slurm step 1 of 3"; fi

USER ophidia

RUN if [ "$slurm" = "yes" ] ; then \
	cd /repo/slurm-20.11.7 && \
	./configure --prefix=/usr/local/ophidia/extra > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 ; else echo "Skipping Slurm step 2 of 3" ; fi

USER root

ENV PATH="/usr/local/ophidia/extra/bin:$PATH"
RUN if [ "$slurm" = "yes" ] ; then \
	ldconfig -n /usr/local/ophidia/extra/lib/ && \
	mkdir -p /var/log/slurm && chown ophidia:ophidia /var/log/slurm && \
	mkdir -p /var/run/slurm && chown ophidia:ophidia /var/run/slurm && \
	mkdir -p /var/spool/slurm && chown ophidia:ophidia /var/spool/slurm && \
	mkdir -p /var/spool/slurmd && chown ophidia:ophidia /var/spool/slurmd && \
	mkdir -p /var/log/slurmctld && chown ophidia:ophidia /var/log/slurmctld/ ; else echo "Skipping Slurm step 3 of 3" ; fi
COPY server_scripts/oph_submit.sh slurm*.conf /usr/local/ophidia/extra/etc/
RUN if [ "$slurm" = "yes" ] ; then rm /usr/local/ophidia/extra/etc/oph_submit.sh && chown -R ophidia:ophidia /usr/local/ophidia/extra/etc/ ; fi

ENV CONDA_DIR=/opt/conda
RUN if [ "$jupyter" = "yes" ] ; then \
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-py38_4.12.0-Linux-x86_64.sh && \
    bash Miniconda3-py38_4.12.0-Linux-x86_64.sh -b -p /opt/conda && \
    rm -r Miniconda3-py38_4.12.0-Linux-x86_64.sh; else echo "Skipping Jupyter step 1 of 3" ; fi
ENV PATH=$CONDA_DIR/bin:$PATH

USER ophidia

ENV PATH=$CONDA_DIR/bin:$PATH
ADD environment.yml /tmp/environment.yml
RUN if [ "$jupyter" = "yes" ] ; then \
    conda env create -f /tmp/environment.yml -p /usr/local/ophidia/env; else echo "Skipping Jupyter step 2 of 3" ; fi

USER root

RUN rm -r /tmp/environment.yml

USER ophidia

RUN if [ "$jupyter" = "yes" ] ; then \
    echo "source activate /usr/local/ophidia/env" > ~/.bashrc; fi
ENV PATH=/usr/local/ophidia/env/bin:$PATH

ENV PATH=$PATH:/usr/local/ophidia/proj/bin:/usr/local/ophidia/.local/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/ophidia/proj/lib:/usr/local/ophidia/.local/lib

RUN if [ "$jupyter" = "yes" ] ; then \
	mkdir -p /usr/local/ophidia/.jupyter/ && \
	touch /usr/local/ophidia/.jupyter/jupyter_server_config.json && \
	printf "{\n  \"ServerApp\": {\n    \"password\": \"argon2:\$argon2id\$v=19\$m=10240,t=10,p=8\$qowYWxFJARKuf//IthKHmQ\$MHA01UDBcUa40VXEjL6apw\"\n  }\n}" > /usr/local/ophidia/.jupyter/jupyter_server_config.json && \
	chmod 600 /usr/local/ophidia/.jupyter/jupyter_server_config.json && \
	sed -i "s/ioserver='mysql_table'/ioserver='ophidiaio_memory'/g" /usr/local/ophidia/env/lib/python3.8/site-packages/PyOphidia/cube.py && \
	sed -i "s/ioserver=\"mysql_table\"/ioserver=\"ophidiaio_memory\"/g" /usr/local/ophidia/env/lib/python3.8/site-packages/PyOphidia/cube.py && \
	sed -i "s/mysql_table|//g" /usr/local/ophidia/env/lib/python3.8/site-packages/PyOphidia/cube.py && \
	printf "\nYour jupyter password is:\t\'ophidia\'\n"; else echo "Skipping Jupyter step 3 of 3" ; fi
RUN if [ "$jupyter" = "yes" ] ; then \
    cd /usr/local/ophidia/env/lib/python3.8/ && \
    git clone https://github.com/OphidiaBigData/PyOphidia.git && \
    cd PyOphidia/ && \
    git checkout $branch && \
    pip install -e . ; fi
RUN if [ "$jupyter" = "yes" ] ; then \
    conda clean -y --all; fi

USER root

COPY server_scripts/oph_submit.sh /usr/local/ophidia/oph-server/etc/script/oph_submit.sh
COPY entrypoint.sh /

EXPOSE 11732
EXPOSE 8888
EXPOSE 65000

ENV JUPYTER=$jupyter

LABEL SLURM=$slurm JUPYTER=$jupyter THREAD_SAFE=$thread_safe

ENTRYPOINT ["/entrypoint.sh"]
