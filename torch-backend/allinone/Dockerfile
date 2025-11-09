FROM ghcr.io/intertwin-eu/itwinai-dev:jlab-slim-0.3.2-torch2.4-bookworm

LABEL author="CMCC Foundation" description="Ophidia HPDA Framework"

ARG thread_safe=no
ARG jupyter=no
ARG python=no
ARG main_partition=yes
ARG ioservers=0
ARG version=1.9.0
ARG version_primitives=$version
ARG version_io_server=$version
ARG version_analytics_framework=$version
ARG version_server=$version
ARG version_terminal=$version
ARG devel=no
ARG branch=master
ARG branch_primitives=$branch
ARG branch_io_server=$branch
ARG branch_analytics_framework=$branch
ARG branch_server=$branch
ARG branch_terminal=$branch
ARG branch_pyophidia=$branch
ARG cjose=no
ARG zarr=no
ARG s3=no
ARG cdo=no
ARG nco=no
ARG valgrind=no
ARG debug_level=0
ARG logging=no
ARG logging_dir=/home/jovyan/work/log
ARG libmatheval_extensions=no

USER root

RUN apt update -y && \
	apt install -y autoconf autotools-dev gcc make git libltdl-dev curl && \
	apt autoremove -y && apt clean -y

ENV OPHIDIA_DIR=/usr/local/ophidia

RUN mkdir -p /repo && \
	chmod -R 777 /repo && \
	mkdir -p $OPHIDIA_DIR && \
	mkdir -p $OPHIDIA_DIR/extra && \
	chown -R $NB_UID:$NB_UID $OPHIDIA_DIR

ADD server_scripts/oph_submit.sh /offline_ophidia/

RUN cd /repo && \
	apt update -y && \
	apt install libaio1 apt-utils libmecab2 psmisc && \
	apt autoremove -y && apt clean -y && \
	wget https://downloads.mysql.com/archives/get/p/23/file/mysql-server_8.0.41-1debian12_amd64.deb-bundle.tar && \
	tar -xvf mysql-server_8.0.41-1debian12_amd64.deb-bundle.tar

RUN cd /repo && \
	dpkg-preconfigure mysql-community-server_*.deb && \
	dpkg -i mysql-common_*.deb mysql-community-client-plugins_*.deb mysql-community-client-core_*.deb mysql-community-client_*.deb mysql-client_*.deb && \
	dpkg -i mysql-community-server-core_*.deb mysql-community-server_*.deb mysql-server_*.deb && \
	dpkg -i libmysqlclient*.deb && \
	chmod +x /var/run/mysqld && \
	usermod -d /var/lib/mysql/ mysql

RUN	echo "#!/bin/bash" >> /usr/sbin/start_mysql && \
	echo "rm -f /var/run/mysqld/mysqld.sock" >> /usr/sbin/start_mysql && \
	echo "mysqld -u mysql >/dev/null 2>&1 &" >> /usr/sbin/start_mysql && \
	chmod +x /usr/sbin/start_mysql

RUN /usr/sbin/start_mysql && \
	while [ ! -S /var/run/mysqld/mysqld.sock ]; do sleep 1; done && \
	MYSQL_PWD="abcd" mysql -u root -e "SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));" && \
	MYSQL_PWD="abcd" mysql -u root -e "CREATE DATABASE ophidiadb;" && \
	MYSQL_PWD="abcd" mysql -u root -e "CREATE DATABASE oph_dimensions;" && \
	cd /repo && \
	curl -s -O -k https://raw.githubusercontent.com/OphidiaBigData/ophidia-analytics-framework/$branch_analytics_framework/etc/ophidiadb.sql && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb < /repo/ophidiadb.sql && \
	rm -rf /repo/*

#LIBMATHEVAL
RUN apt install -y libfl-dev flex bison libmatheval-dev libmatheval1 openssl wget sed file libmpich-dev && apt autoremove -y && apt clean -y

RUN if [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia Primitives" && \
	apt install -y gsl-bin libgslcblas0 libgsl-dev guile-2.2-dev autoconf automake libtool\* pkg-config libz-dev && apt autoremove -y && apt clean -y ; fi

RUN if [ "$s3" = "yes" ] ; then \
	apt install -y cmake libcurl4-openssl-dev && apt autoremove -y && apt clean -y ; fi

USER $NB_UID

ENV OPHIDIA_DIR=/usr/local/ophidia

#OPHIDIA PRIMITIVES
RUN if [ "$devel" = "yes" ] ; then \
	mkdir $OPHIDIA_DIR/src && \
	cd $OPHIDIA_DIR/src && \
	git clone https://github.com/OphidiaBigData/ophidia-primitives && \
	cd $OPHIDIA_DIR/src/ophidia-primitives && \
	git checkout $branch_primitives && \
	if [ "$libmatheval_extensions" = "yes" ] ; then \
	cd /repo && curl -s -O -k https://ftp.gnu.org/gnu/libmatheval/libmatheval-1.1.11.tar.gz && \
	tar -xzf libmatheval-1.1.11.tar.gz && \
	cd libmatheval-1.1.11 && \
	patch -p0 < $OPHIDIA_DIR/src/ophidia-primitives/import_plugin/libmatheval.patch && \
	./configure --prefix=$OPHIDIA_DIR/extra && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /repo/* && \
	export LIBMATHEVAL=$OPHIDIA_DIR/extra ; else \
	export LIBMATHEVAL=/usr/lib/$(uname -m)-linux-gnu ; fi && \
	cd $OPHIDIA_DIR/src/ophidia-primitives && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=$OPHIDIA_DIR/oph-cluster/oph-primitives --with-matheval-path=$LIBMATHEVAL > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf $OPHIDIA_DIR/src ; fi

USER root

ENV LD_LIBRARY_PATH=$OPHIDIA_DIR/extra/lib:$LD_LIBRARY_PATH

RUN if [ "$devel" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-primitives/releases/download/v${version_primitives}/ophidia-primitives_${version_primitives}-0_amd64.deb && \
	apt install -y ophidia-primitives_*.deb && apt autoremove -y && apt clean -y &&\
	chown -R $NB_UID:$NB_UID $OPHIDIA_DIR && \
	rm -rf /repo/* ; fi

RUN cp $OPHIDIA_DIR/oph-cluster/oph-primitives/lib/liboph_*.so /usr/lib/mysql/plugin && \
	sed -i '/GRANT/d' $OPHIDIA_DIR/oph-cluster/oph-primitives/etc/create_func.sql && \
	apt autoremove -y && apt clean -y

RUN /usr/sbin/start_mysql && \
	while [ ! -S /var/run/mysqld/mysqld.sock ]; do sleep 1; done && \
	MYSQL_PWD="abcd" mysql -u root -e "SET GLOBAL log_bin_trust_function_creators = 1;" && \
	MYSQL_PWD="abcd" mysql -u root mysql < $OPHIDIA_DIR/oph-cluster/oph-primitives/etc/create_func.sql

#OPHIDIA IO SERVER
RUN if [ "$thread_safe" != "yes" ] && [ "$devel" != "yes" ] ; then \
	apt install -y libhdf5-dev libhdf5-mpich-dev libnetcdf-dev libnetcdf-mpi-dev && \
	apt autoremove -y && apt clean -y ; fi

#HDF5-MPICH THREAD-SAFE
RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	cd /repo && \
	apt install -y mpi-default-dev && apt autoremove -y && apt clean -y && \
	wget -q https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.12/hdf5-1.12.1/src/hdf5-1.12.1.tar.gz && \
	gzip -cd hdf5-1.12.1.tar.gz | tar xf - && \
	cd hdf5-1.12.1/ && \
	./configure --prefix=$OPHIDIA_DIR/extra/ --enable-parallel --enable-threadsafe --enable-unsupported --with-zlib > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /repo/* ; fi

#S3 SUPPORT FOR ZARR
RUN	if [ "$s3" = "yes" ] ; then \
	mkdir -p $OPHIDIA_DIR/src && \
	cd $OPHIDIA_DIR/src && \
	git clone https://github.com/Blosc/c-blosc.git && \
	cd c-blosc && \
	mkdir build && \
	cd build && \
	cmake -DCMAKE_INSTALL_PREFIX=$OPHIDIA_DIR/extra .. && \
	cmake --build . --target install && \
	rm -rf $OPHIDIA_DIR/src ; fi
RUN	if [ "$s3" = "yes" ] ; then \
	mkdir -p $OPHIDIA_DIR/src && \
	cd $OPHIDIA_DIR/src && \
	git config --global http.version HTTP/1.1 && \
	git clone https://github.com/aws/aws-sdk-cpp.git && \
	cd aws-sdk-cpp && \
	git submodule update --init --recursive && \
	mkdir build && \
	cd build && \
	OLD_PATH=$PATH && \
	PATH=${PATH#/opt/conda/bin} && \
	cmake $OPHIDIA_DIR/src/aws-sdk-cpp -DBUILD_ONLY=s3 -DCMAKE_BUILD_TYPE=Debug -DENABLE_TESTING=OFF -DCMAKE_INSTALL_PREFIX=$OPHIDIA_DIR/extra && \
	make -j -k -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	PATH=$OLD_PATH && \
	rm -rf $OPHIDIA_DIR/src ; fi

#NETCDF-MPICH
RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	apt install -y libcurl4-openssl-dev libxml2 libxml2-dev && apt autoremove -y && apt clean -y && \
	cd /repo && \
	git clone https://github.com/Unidata/netcdf-c.git && \
	cd netcdf-c* && \
	git checkout tags/v4.9.3 && \
	if [ "$s3" = "yes" ] ; then enable_s3="--enable-s3" ; library_s3="-laws-cpp-sdk-s3 " ; fi && \
	CC=/usr/bin/mpicc CPP=/usr/bin/mpicxx CFLAGS="-I$OPHIDIA_DIR/extra/include/" CPPFLAGS="-I$OPHIDIA_DIR/extra/include/" LDFLAGS="-L$OPHIDIA_DIR/extra/lib/" LIBS="-ldl $library_s3" H5DIR=$OPHIDIA_DIR/extra/ ./configure --prefix=$OPHIDIA_DIR/extra --enable-netcdf4 --with-plugin-dir=$OPHIDIA_DIR/extra/lib/plugins $enable_s3 > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /repo/* ; fi

ENV	HDF5_PLUGIN_PATH=$OPHIDIA_DIR/extra/lib/plugins

RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia I/O Server" && \
	apt install -y bison flex libfl-dev libbison-dev && apt autoremove -y && apt clean -y ; fi

USER $NB_UID

RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	mkdir $OPHIDIA_DIR/src && \
	cd $OPHIDIA_DIR/src && \
	git clone https://github.com/OphidiaBigData/ophidia-io-server && \
	cd ophidia-io-server && \
	git checkout $branch_io_server && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=$OPHIDIA_DIR/oph-cluster/oph-io-server --with-netcdf-path=$OPHIDIA_DIR/extra/ --enable-parallel-nc4 > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	mkdir -p $OPHIDIA_DIR/oph-cluster/oph-io-server/data1/var && \
	mkdir -p $OPHIDIA_DIR/oph-cluster/oph-io-server/data1/log && \
	rm -rf $OPHIDIA_DIR/src ; fi

USER root

RUN if [ "$thread_safe" != "yes" ] && [ "$devel" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-io-server/releases/download/v${version_io_server}/ophidia-io-server_${version_io_server}-0_amd64.deb && \
	apt install -y ophidia-io-server_*.deb && apt autoremove -y && apt clean -y && \
	chown -R $NB_UID:$NB_UID $OPHIDIA_DIR && \
	sed -i "s/127.0.0.1/0.0.0.0/g" $OPHIDIA_DIR/oph-cluster/oph-io-server/etc/oph_ioserver.conf && \
	rm -rf /repo/* ; fi

RUN if [ "$main_partition" = "yes" ] ; then \
	/usr/sbin/start_mysql && while [ ! -S /var/run/mysqld/mysqld.sock ]; do sleep 1; done && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO host (hostname, cores, memory, status) SELECT '127.0.0.1', 4, 1, 'up' FROM DUAL WHERE NOT EXISTS (SELECT hostname FROM host WHERE hostname = '127.0.0.1') LIMIT 1;" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO dbmsinstance (idhost, login, password, port, ioservertype) SELECT host.idhost, 'root', 'abcd', 65000, 'ophidiaio_memory' FROM host WHERE hostname = '127.0.0.1' AND NOT EXISTS (SELECT * FROM dbmsinstance INNER JOIN host ON host.idhost = dbmsinstance.idhost WHERE hostname = '127.0.0.1' AND port = 65000) LIMIT 1;" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO hostpartition (partitionname) VALUES ('main');" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT IGNORE INTO hashost (idhostpartition, idhost) SELECT 1, host.idhost FROM host WHERE hostname='127.0.0.1';" ; fi

RUN if [ $ioservers -gt 0 ] ; then \
	/usr/sbin/start_mysql && while [ ! -S /var/run/mysqld/mysqld.sock ]; do sleep 1; done && \
	for i in $(seq 1 $ioservers) ; do \
	port=$((65000 + i)) && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO host (hostname, cores, memory, status) SELECT '127.0.$i.1', 4, 1, 'down' FROM DUAL WHERE NOT EXISTS (SELECT hostname FROM host WHERE hostname='127.0.$i.1') LIMIT 1;" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO dbmsinstance (idhost, login, password, port, ioservertype) SELECT host.idhost, 'root', 'abcd', $port, 'ophidiaio_memory' FROM host WHERE hostname = '127.0.$i.1' AND NOT EXISTS (SELECT * FROM dbmsinstance INNER JOIN host ON host.idhost = dbmsinstance.idhost WHERE hostname = '127.0.$i.1' AND port = $port) LIMIT 1;" ; done ; fi

#OPHIDIA ANALYTICS FRAMEWORK
RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia Analytics Framework" && \
	apt install -y libjansson-dev libssh2-1-dev libssl-dev gsl-bin libgslcblas0 libgsl-dev libcfitsio-dev && apt autoremove -y && apt clean -y && \
	mkdir -p /var/www/html/ophidia && \
	chown $NB_UID:$NB_UID /var/www/html/ophidia ; fi

USER $NB_UID

RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	mkdir -p $OPHIDIA_DIR/src && \
	cd $OPHIDIA_DIR/src && \
	git clone https://github.com/OphidiaBigData/ophidia-analytics-framework && \
	cd ophidia-analytics-framework && \
	git checkout $branch_analytics_framework && \
	./bootstrap > /dev/null 2>&1 && \
	if [ "$zarr" = "yes" ] ; then enable_zarr="--enable-zarr" ; fi && \
	./configure --prefix=$OPHIDIA_DIR/oph-cluster/oph-analytics-framework --enable-parallel-netcdf --with-netcdf-path=$OPHIDIA_DIR/extra/ --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia --with-ophidiaio-server-path=$OPHIDIA_DIR/oph-cluster/oph-io-server --enable-cfitsio --with-debug-level=$debug_level $enable_zarr > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf $OPHIDIA_DIR/src && \
	mkdir -p $OPHIDIA_DIR/oph-cluster/oph-analytics-framework/log ; fi

USER root

RUN if [ "$thread_safe" != "yes" ] && [ "$devel" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-analytics-framework/releases/download/v${version_analytics_framework}/ophidia-analytics-framework_${version_analytics_framework}-0_amd64.deb && \
	apt install -y ophidia-analytics-framework_*.deb && apt autoremove -y && apt clean -y && \
	chown -R $NB_UID:$NB_UID $OPHIDIA_DIR && \
	chown -R $NB_UID:$NB_UID /var/www/html/ophidia && \
	rm -rf /repo/* ; fi

#CJOSE
RUN if [ "$cjose" = "yes" ] ; then \
	cd /repo && \
	curl -s -LOJk https://github.com/cisco/cjose/archive/0.4.1.tar.gz && \
	tar -xzf cjose-0.4.1.tar.gz && \
	cd cjose-0.4.1 && \
	./configure --prefix=$OPHIDIA_DIR/extra > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /repo/* ; fi

#OPHIDIA SERVER
RUN if [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia Server" && \
	mkdir -p /var/www/html/ophidia && \
	chown -R $NB_UID:$NB_UID /var/www/html/ophidia ; fi

USER $NB_UID

RUN if [ "$devel" = "yes" ] ; then \
	mkdir -p $OPHIDIA_DIR/src && \
	cd $OPHIDIA_DIR/src && \
	git clone https://github.com/OphidiaBigData/ophidia-server && \
	cd ophidia-server && \
	git checkout $branch_server && \
	./bootstrap > /dev/null 2>&1 && \
	if [ "$libmatheval_extensions" = "yes" ] ; then \
	export LIBMATHEVAL=$OPHIDIA_DIR/extra ; else \
	export LIBMATHEVAL=/usr/lib/$(uname -m)-linux-gnu ; fi && \
	./configure --prefix=$OPHIDIA_DIR/oph-server --with-framework-path=$OPHIDIA_DIR/oph-cluster/oph-analytics-framework --enable-webaccess --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia --with-ws-hostname=localhost --with-matheval-path=$LIBMATHEVAL > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	mv authz $OPHIDIA_DIR/oph-server/ && \
	mkdir -p $OPHIDIA_DIR/oph-server/log && \
	mkdir -p $OPHIDIA_DIR/oph-server/authz/sessions && \
	mkdir -p /var/www/html/ophidia/sessions && \
	touch $OPHIDIA_DIR/oph-server/log/server.log && \
	rm -rf $OPHIDIA_DIR/src ; fi

USER root

RUN if [ "$devel" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-server/releases/download/v${version_server}/ophidia-server_${version_server}-0_amd64.deb && \
	apt install -y ophidia-server_*.deb && apt autoremove -y && apt clean -y && \
	chown -R $NB_UID:$NB_UID $OPHIDIA_DIR && \
	touch $OPHIDIA_DIR/oph-server/log/server.log && \
	sed -i "s/OPH_MAX_CORES=.*/OPH_MAX_CORES=0/g" $OPHIDIA_DIR/oph-server/authz/users/oph-test/user.dat && \
	sed -i "s/OPH_MAX_CORES=.*/OPH_MAX_CORES=0/g" $OPHIDIA_DIR/oph-server/authz/users/framework/user.dat && \
	rm -rf /repo/* ; fi

#certificates generation and installation
RUN openssl req -newkey rsa:2048 \
	    -passout pass:abcd \
	    -subj "/" -sha256 \
	    -keyout rootkey.pem \
	    -out rootreq.pem && \
	openssl x509 -req -in rootreq.pem \
	    -passin pass:abcd \
	    -sha1 -extensions v3_ca \
	    -signkey rootkey.pem \
	    -out rootcert.pem &&\
	cat rootcert.pem rootkey.pem  > cacert.pem && \
	openssl req -newkey rsa:2048 \
	    -passout pass:abcd \
	    -subj "/" -sha256 \
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
	mkdir -p $OPHIDIA_DIR/oph-server/etc/cert && \
	cp cacert.pem myserver.pem $OPHIDIA_DIR/oph-server/etc/cert && \
	rm cacert.pem myserver.pem

#WEB SERVER
RUN apt install -y apache2-bin php libapache2-mod-php && \
	apt autoremove -y && apt clean -y && \
	mkdir -p /etc/httpd/conf/ssl && \
	cd /etc/httpd/conf/ssl && \
	openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -out server.crt -keyout server.key -subj "/" && \
	cp -f server.crt /etc/ssl/certs/ssl-cert-snakeoil.pem && \
	cp -f server.key /etc/ssl/private/ssl-cert-snakeoil.key && \
	a2enmod ssl && a2enmod headers && a2ensite default-ssl

#CDO
RUN	if [ "$cdo" = "yes" ] ; then \
	cd /repo && \
	curl -s -O -k https://code.mpimet.mpg.de/attachments/download/29649/cdo-2.4.4.tar.gz && \
	tar -xzf cdo-2.4.4.tar.gz && \
	cd cdo-2.4.4 && \
	if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	PYTHON="/usr/bin/python3" CFLAGS="-I$OPHIDIA_DIR/extra/include -I/usr/lib/$(uname -m)-linux-gnu/mpich/include" CPPFLAGS="-I$OPHIDIA_DIR/extra/include -I/usr/lib/$(uname -m)-linux-gnu/mpich/include" LDFLAGS="-L$OPHIDIA_DIR/extra/lib" ./configure --with-hdf5=$OPHIDIA_DIR/extra/ --with-netcdf=$OPHIDIA_DIR/extra/ --enable-netcdf4 --enable-zlib > /dev/null 2>&1 ; else \
	PYTHON="/usr/bin/python3" CFLAGS="-I/usr/include -I/usr/include/hdf5/serial -I/usr/lib/$(uname -m)-linux-gnu/mpich/include" CPPFLAGS="-I/usr/include -I/usr/include/hdf5/serial -I/usr/lib/$(uname -m)-linux-gnu/mpich/include" LDFLAGS="-L/usr/lib/$(uname -m)-linux-gnu" ./configure --with-hdf5=/usr/ --with-netcdf=/usr/ --enable-netcdf4 --enable-zlib > /dev/null 2>&1 ; fi && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /repo/* && \
	echo "CDO_PATH=/usr/local/bin" >> $OPHIDIA_DIR/oph-cluster/oph-analytics-framework/etc/oph_configuration ; fi

#NCO
RUN	if [ "$nco" = "yes" ] ; then \
	apt install -y nco && \
	apt autoremove -y && apt clean -y ; fi

#OPHIDIA TERMINAL
RUN if [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia Terminal" && \
	apt install -y graphviz-dev libgtk2.0-dev policycoreutils-python-utils libreadline-dev && apt autoremove -y && apt clean -y ; fi

USER $NB_UID

RUN if [ "$devel" = "yes" ] ; then \
	mkdir -p $OPHIDIA_DIR/src && \
	cd $OPHIDIA_DIR/src && \
	git clone https://github.com/OphidiaBigData/ophidia-terminal && \
	cd ophidia-terminal && \
	git checkout $branch_terminal && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=$OPHIDIA_DIR/oph-terminal --disable-xml-ssl-check --disable-xml-removal > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf $OPHIDIA_DIR/src ; fi

#OPERATORS_FIXES
RUN cd $OPHIDIA_DIR/oph-cluster/oph-analytics-framework/etc/operators_xml/ && \
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

USER root

ENV PATH=$OPHIDIA_DIR/oph-cluster/oph-io-server/bin:$OPHIDIA_DIR/oph-cluster/oph-analytics-framework/bin:$OPHIDIA_DIR/oph-server/bin:$OPHIDIA_DIR/extra/bin:$OPHIDIA_DIR/oph-terminal/bin:$PATH
ENV LD_LIBRARY_PATH=$HDF5_PLUGIN_PATH:$LD_LIBRARY_PATH

COPY server_scripts/oph_submit.sh $OPHIDIA_DIR/extra/etc/

RUN if [ "$jupyter" = "yes" ] || [ "$python" = "yes" ] ; then \
    apt install -y graphviz nodejs && apt autoremove -y && apt clean -y ; fi

USER $NB_UID

ENV PATH=$OPHIDIA_DIR/oph-cluster/oph-io-server/bin:$OPHIDIA_DIR/oph-cluster/oph-analytics-framework/bin:$OPHIDIA_DIR/oph-server/bin:$OPHIDIA_DIR/extra/bin:$OPHIDIA_DIR/oph-terminal/bin:$PATH

ENV PYOPHIDIA_DIR=$HOME/pyophidia
RUN mkdir -p $PYOPHIDIA_DIR
ADD requirements.txt $PYOPHIDIA_DIR/requirements.txt
RUN if [ "$jupyter" = "yes" ] || [ "$python" = "yes" ] ; then \
	pip install --no-cache-dir -r $PYOPHIDIA_DIR/requirements.txt ; fi
RUN rm -rf $PYOPHIDIA_DIR/requirements.txt

ENV PATH=$OPHIDIA_DIR/env/bin:$OPHIDIA_DIR/proj/bin:$OPHIDIA_DIR/.local/bin:$PATH
ENV LD_LIBRARY_PATH=$OPHIDIA_DIR/proj/lib:$OPHIDIA_DIR/.local/lib:$LD_LIBRARY_PATH

RUN echo "export PATH=$PATH" >> ~/.bashrc && \
	echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> ~/.bashrc && \
	echo "export HDF5_PLUGIN_PATH=$HDF5_PLUGIN_PATH" >> ~/.bashrc

RUN if [ "$jupyter" = "yes" ] ; then \
	pip install jupyterlab && \
	mkdir -p $OPHIDIA_DIR/.jupyter/ && \
	touch $OPHIDIA_DIR/.jupyter/jupyter_server_config.json && \
	printf "{\n  \"ServerApp\": {\n    \"password\": \"argon2:\$argon2id\$v=19\$m=10240,t=10,p=8\$qowYWxFJARKuf//IthKHmQ\$MHA01UDBcUa40VXEjL6apw\"\n  }\n}" > $OPHIDIA_DIR/.jupyter/jupyter_server_config.json && \
	chmod 600 $OPHIDIA_DIR/.jupyter/jupyter_server_config.json && \
	printf "\nYour jupyter password is:\t\'ophidia\'\n" ; fi

RUN if [ "$jupyter" = "yes" ] || [ "$python" = "yes" ] ; then \
	mkdir -p $PYOPHIDIA_DIR/src && \
	cd $PYOPHIDIA_DIR/src && \
	git clone https://github.com/OphidiaBigData/PyOphidia.git && \
	cd PyOphidia/ && \
	git checkout $branch_pyophidia && \
	python -m pip install ".[convert,cwl,prov,display]" && \
	cp -r pyophidia/utils $PYOPHIDIA_DIR/ && \
	cp -r examples $PYOPHIDIA_DIR/ && \
	rm -f $PYOPHIDIA_DIR/examples/utils/tasks && \
	cp -r pyophidia/utils/tasks $PYOPHIDIA_DIR/examples/utils/ && \
	rm -rf $PYOPHIDIA_DIR/src && \
	echo "export PATH=$PATH:$PYOPHIDIA_DIR/utils" >> ~/.bashrc ; fi

# The following task has been added to support jovyan-based frontend
RUN	if [ "$jupyter" = "yes" ] || [ "$python" = "yes" ] ; then \
	mkdir -p /home/jovyan && ln -s $PYOPHIDIA_DIR /home/jovyan/pyophidia ; fi

# ML4Fires on the backend
#RUN	cd / && \
#	git clone https://github.com/CMCC-Foundation/ML4Fires.git && \
#	cd /ML4Fires && \
#	git checkout feature_26 && \
#	echo "export PATH=$PATH:/ML4Fires" >> ~/.bashrc && \
#	pip install toml munch tqdm timm dask && \
#	rm -f /ML4Fires/config/credentials.toml && \
#	ln -s /home/jovyan/work/credentials.toml /ML4Fires/config/credentials.toml && \
#	mkdir -p /ML4Fires/MLFLOW && ln -s /home/jovyan/work/fires/model /ML4Fires/MLFLOW/model && \
#	sed -i 's/EXPERIMENT_NAME = "ML4Fires_Experiment"/EXPERIMENT_NAME = "ML4Fires_Experiment_Pourya"/' /ML4Fires/config/configuration.toml && \
#	sed -i 's/torch.load(path)/torch.load(path,map_location=torch.device('\''cpu'\''))/' /ML4Fires/Fires/_utilities/utils_mlflow.py

# ML4Fires on shared space
RUN	echo "export PATH=$PATH:/home/jovyan/work/ML4Fires" >> ~/.bashrc && \
	pip install toml munch tqdm timm dask zarr

RUN	if [ "$cdo" = "yes" ] ; then \
	pip install cdo ; fi

ENV OPH_SERVER_HOST="127.0.0.1"
ENV OPH_SERVER_PORT="11732"
ENV OPH_USER="oph-test"
ENV OPH_PASSWD="abcd"

WORKDIR $HOME

# Logging IO Server
RUN	if [ "$logging" = "yes" ] ; then \
	rm -rf $OPHIDIA_DIR/oph-cluster/oph-io-server/data1/log && \
	ln -s $logging_dir/ioserver0 $OPHIDIA_DIR/oph-cluster/oph-io-server/data1/log ; fi

# Logging Analytics Framework
RUN	if [ "$logging" = "yes" ] ; then \
	rm -rf $OPHIDIA_DIR/oph-cluster/oph-analytics-framework/log && \
	ln -s $logging_dir/framework $OPHIDIA_DIR/oph-cluster/oph-analytics-framework/log ; fi

# Logging Server
RUN	if [ "$logging" = "yes" ] ; then \
	rm -rf $OPHIDIA_DIR/oph-server/log && \
	ln -s $logging_dir/server $OPHIDIA_DIR/oph-server/log ; fi

USER root

# Logging IO Server
RUN	if [ "$logging" = "yes" ] || [ "$devel" = "yes" ] ; then \
	mkdir -p /root/.ophidia && \
	ln -s $logging_dir/ioserver1 /root/.ophidia/data1 ; fi

RUN	/usr/sbin/start_mysql && \
	while [ ! -S /var/run/mysqld/mysqld.sock ]; do sleep 1; done && \
	MYSQL_PWD="abcd" mysql -u root -e "DROP USER 'root'@'localhost'; CREATE USER 'root'@'%' IDENTIFIED BY 'abcd'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"

RUN	if [ "$valgrind" = "yes" ] ; then \
	apt install -y valgrind && \
	apt autoremove -y && apt clean -y ; fi

# Other packages
RUN	apt install -y bc sudo && \
	apt autoremove -y && apt clean -y

COPY ssl-params.conf /etc/apache2/conf-available/
COPY server_scripts/oph_submit.sh $OPHIDIA_DIR/oph-server/etc/script/oph_submit.sh
COPY server_scripts/oph_cancel.sh $OPHIDIA_DIR/oph-server/etc/script/oph_cancel.sh
COPY server_scripts/oph_start.sh $OPHIDIA_DIR/oph-server/etc/script/oph_start.sh
COPY server_scripts/oph_check.sh $OPHIDIA_DIR/oph-server/etc/script/oph_check.sh
COPY server_scripts/start_ioserver.sh $OPHIDIA_DIR/oph-server/etc/script/start_ioserver.sh
COPY server_scripts/stop_ioserver.sh $OPHIDIA_DIR/oph-server/etc/script/stop_ioserver.sh
COPY server_scripts/oph_ioserver.conf.template $OPHIDIA_DIR/oph-server/etc/script/oph_ioserver.conf.template
COPY entrypoint.sh /

RUN	sed -i "s:\$HOME:$HOME:" $OPHIDIA_DIR/oph-server/etc/script/oph_ioserver.conf.template

RUN	echo "ENABLE_CLUSTER_DEPLOYMENT=yes" >> $OPHIDIA_DIR/oph-server/etc/server.conf
RUN	echo "ENABLE_CLUSTER_INCREASE=yes" >> $OPHIDIA_DIR/oph-server/etc/server.conf

EXPOSE 11732
EXPOSE 8888
EXPOSE 65000

ENV JUPYTER=$jupyter
ENV PYTHON=$python
ENV MAIN_PARTITION=$main_partition

ARG frontend=yes
ENV FRONTEND=$frontend

ENTRYPOINT ["/entrypoint.sh"]
