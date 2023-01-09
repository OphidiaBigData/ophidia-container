FROM centos:7

LABEL author="CMCC Foundation" description="Ophidia HPDA Framework - Backend only"

ARG offline_ophidia=no
ARG thread_safe=yes

USER root

RUN cd / && \
	yum -y update yum && \
	yum -y update && \
	yum -y install epel-release && \
	yum -y clean all

RUN yum -y --nogpgcheck install http://repo.mysql.com/mysql57-community-release-el7.rpm && \
	yum -y --nogpgcheck install mysql-community-devel mysql-community-server mysql-community-client && \
	yum -y clean all && \
	chmod -R 777 /var/lib/mysql && \
	chmod 777 /var/log/ && \
	mkdir -p /repo && \
	chmod -R 777 /repo && \
	mkdir -p /usr/local/ophidia && \
	mkdir -p /usr/local/ophidia/extra && \
	useradd -r ophidia -d /usr/local/ophidia && \
	usermod -u 1000 ophidia && \
	groupmod -g 1000 ophidia && \
	chown -R ophidia:ophidia /usr/local/ophidia

ADD server_scripts/oph_submit.sh #offline_ophidia_*.tar.gz /offline_ophidia/

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
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-primitives/releases/download/v1.7.1/ophidia-primitives-1.7.1-0.el7.centos.x86_64.rpm  && \
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
RUN if [ "$thread_safe" = "yes" ] ; then \
	yum -y install gcc-c++ zlib zlib-devel mpich-3.0.x86_64 mpich-3.0-devel.x86_64 mpich-3.0-autoload.x86_64 && \
	yum -y clean all ; else \
	yum -y install hdf5-devel hdf5-mpich-devel && \
	yum -y install netcdf-devel netcdf-mpich-devel && \
	yum -y install mpich-3.0-autoload.x86_64 && \
	yum -y clean all ; fi
#HDF5-MPICH THREAD-SAFE
ENV MODULEPATH=/usr/share/Modules/modulefiles:/etc/modulefiles
RUN if [ "$thread_safe" = "yes" ] ; then \
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
RUN if [ "$thread_safe" = "yes" ] ; then \
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

RUN if [ "$thread_safe" = "yes" ] ; then \
	echo "Using online io-server source code in order to enable thread-safe" && \
	yum -y install bison\* flex\* autoconf automake libtool\* && yum -y clean all ; fi
USER ophidia
RUN if [ "$thread_safe" = "yes" ] ; then \
	mkdir /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/ophidia-io-server && \
	cd ophidia-io-server && \
	#git checkout master && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=/usr/local/ophidia/oph-cluster/oph-io-server --with-netcdf-path=/usr/local/ophidia/extra/netcdf-ts/ --enable-parallel-nc4 > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	mkdir -p /usr/local/ophidia/oph-cluster/oph-io-server/data1/var && \
	mkdir -p /usr/local/ophidia/oph-cluster/oph-io-server/data1/log && \
	rm -rf /usr/local/ophidia/src ; fi
USER root

RUN if [ "$thread_safe" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-io-server/releases/download/v1.7.1/ophidia-io-server-1.7.1-0.el7.centos.x86_64.rpm && \
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
RUN if [ "$thread_safe" = "yes" ] ; then \
	echo "Using online analytics-framework source code in order to enable thread-safe" && \
	yum -y install jansson\* libxml2\* openssl-devel gsl gsl-devel libcurl libcurl-devel cfitsio cfitsio-devel && yum -y clean all && \
	mkdir -p /var/www/html/ophidia && \
	chown ophidia:ophidia /var/www/html/ophidia ; fi
USER ophidia
RUN if [ "$thread_safe" = "yes" ] ; then \
	mkdir -p /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/ophidia-analytics-framework && \
	cd ophidia-analytics-framework && \
	#git checkout master && \
	eval `/usr/bin/modulecmd bash load /etc/modulefiles/mpi/mpich-3.0-x86_64` && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=/usr/local/ophidia/oph-cluster/oph-analytics-framework --enable-parallel-netcdf --with-netcdf-path=/usr/local/ophidia/extra/netcdf-ts/ --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia --with-ophidiaio-server-path=/usr/local/ophidia/oph-cluster/oph-io-server --enable-cfitsio > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /usr/local/ophidia/src && \
	mkdir -p /usr/local/ophidia/oph-cluster/oph-analytics-framework/log ; fi
USER root

RUN if [ "$thread_safe" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-analytics-framework/releases/download/v1.7.1/ophidia-analytics-framework-1.7.1-0.el7.centos.x86_64.rpm && \
	yum -y install ophidia-analytics-framework-*.rpm && yum -y clean all && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	chown -R ophidia:ophidia /var/www/html/ophidia && \
	rm -rf /repo/* ; fi

#CJOSE
RUN if [ "$thread_safe" != "yes" ] ; then yum -y install openssl-devel jansson-devel && yum -y clean all ; fi && \
	cd /repo && \
	curl -s -LOJk https://github.com/cisco/cjose/archive/0.4.1.tar.gz && \
	tar -xzf cjose-0.4.1.tar.gz && \
	cd cjose-0.4.1 && \
	./configure --prefix=/usr/local/ophidia/extra > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /repo/*

#OPHIDIA SERVER
RUN cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-server/releases/download/v1.7.1/ophidia-server-1.7.1-0.el7.centos.x86_64.rpm && \
	yum -y install ophidia-server-*.rpm && yum -y clean all && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	chown -R ophidia:ophidia /var/www/html/ophidia && \
	touch /usr/local/ophidia/oph-server/log/server.log && \
	sed -i "s/OPH_MAX_CORES=.*/OPH_MAX_CORES=0/g" /usr/local/ophidia/oph-server/authz/users/oph-test/user.dat && \
	sed -i "s/OPH_MAX_CORES=.*/OPH_MAX_CORES=0/g" /usr/local/ophidia/oph-server/authz/users/framework/user.dat && \
	rm -rf /repo/*

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
RUN yum -y install --nogpgcheck mod_ssl php-mysql php-devel php-gd php-pecl-memcache php-pspell php-snmp php-xmlrpc php-xml && \
	yum -y clean all && \
	mkdir -p /etc/httpd/conf/ssl && \
	cd /etc/httpd/conf/ssl && \
	openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -out server.crt -keyout server.key -subj "/"

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

COPY server_scripts/oph_submit.sh /usr/local/ophidia/oph-server/etc/script/oph_submit.sh
COPY entrypoint.sh /

EXPOSE 11732
EXPOSE 65000

LABEL OFFLINE_OPHIDIA_RPMS=$offline_ophidia THREAD_SAFE=$thread_safe

ENTRYPOINT ["/entrypoint.sh"]

