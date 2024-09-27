FROM ubuntu:24.04

LABEL author="CMCC Foundation" description="Ophidia HPDA Framework"

ARG thread_safe=no
ARG jupyter=no
ARG python=no
ARG main_partition=yes
ARG ioservers=0
ARG version=1.8.0
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
ARG cdo=no
ARG valgrind=no
ARG debug_level=0

USER root

RUN cd / && \
	apt update -y && \
	apt install -y mysql-server && \
	apt install -y mysql-client libmysqlclient-dev && \
	apt autoremove -y && apt clean -y && \
	chmod +x /var/run/mysqld

RUN apt install -y autoconf autotools-dev gcc make git libltdl-dev curl && apt autoremove -y && apt clean -y

RUN mkdir -p /repo && \
	chmod -R 777 /repo && \
	mkdir -p /usr/local/ophidia && \
	mkdir -p /usr/local/ophidia/extra && \
	useradd -r ophidia -d /usr/local/ophidia && \
	usermod -u 2000 ophidia && \
	groupmod -g 2000 ophidia && \
	chown -R ophidia:ophidia /usr/local/ophidia

ADD server_scripts/oph_submit.sh /offline_ophidia/

RUN	service mysql start && \
	while [ ! -S /var/run/mysqld/mysqld.sock ]; do sleep 1; done && \
	mysqladmin -u root password abcd && \
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
	apt install -y gsl-bin libgslcblas0 libgsl-dev autoconf automake libtool\* pkg-config && apt autoremove -y && apt clean -y ; fi

USER ophidia

#OPHIDIA PRIMITIVES
RUN if [ "$devel" = "yes" ] ; then \
	mkdir /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/ophidia-primitives && \
	cd ophidia-primitives && \
	git checkout $branch_primitives && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=/usr/local/ophidia/oph-cluster/oph-primitives --with-matheval-path=/usr/lib/$(uname -m)-linux-gnu > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /usr/local/ophidia/src ; fi

USER root

RUN if [ "$devel" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-primitives/releases/download/v$version/ophidia-primitives_$version*.deb && \
	apt install -y ophidia-primitives_*.deb && apt autoremove -y && apt clean -y &&\
	chown -R ophidia:ophidia /usr/local/ophidia && \
	rm -rf /repo/* ; fi

RUN cp /usr/local/ophidia/oph-cluster/oph-primitives/lib/liboph_*.so /usr/lib/mysql/plugin && \
	sed -i '/GRANT/d' /usr/local/ophidia/oph-cluster/oph-primitives/etc/create_func.sql && \
	apt autoremove -y && apt clean -y

RUN service mysql start && \
	while [ ! -S /var/run/mysqld/mysqld.sock ]; do sleep 1; done && \
	MYSQL_PWD="abcd" mysql -u root -e "SET GLOBAL log_bin_trust_function_creators = 1;" && \
	MYSQL_PWD="abcd" mysql -u root mysql < /usr/local/ophidia/oph-cluster/oph-primitives/etc/create_func.sql

#OPHIDIA IO SERVER
RUN if [ "$thread_safe" != "yes" ] && [ "$devel" != "yes" ] ; then \
	apt install -y libhdf5-dev libhdf5-mpich-dev libnetcdf-dev libnetcdf-mpi-dev && \
	apt autoremove -y && apt clean -y ; fi

#HDF5-MPICH THREAD-SAFE
RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
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
	apt install -y git libcurl4-openssl-dev libxml2 libxml2-dev && apt autoremove -y && apt clean -y && \
	cd /repo && \
	git clone https://github.com/Unidata/netcdf-c.git && \
	cd netcdf-c* && \
	git checkout tags/v4.9.2 && \
	CC=/usr/bin/mpicc CPPFLAGS="-I/usr/local/ophidia/extra/hdf5-ts/include/" LDFLAGS="-L/usr/local/ophidia/extra/hdf5-ts/lib/" LIBS=-ldl H5DIR=/usr/local/ophidia/extra/hdf5-ts/ ./configure --prefix=/usr/local/ophidia/extra/netcdf-ts --enable-netcdf4 --with-plugin-dir=/usr/local/ophidia/extra/netcdf-ts/lib/plugins > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /repo/* ; fi

ENV	HDF5_PLUGIN_PATH=/usr/local/ophidia/extra/netcdf-ts/lib/plugins

RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia I/O Server" && \
	apt install -y bison flex libfl-dev libbison-dev && apt autoremove -y && apt clean -y ; fi

USER ophidia

RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	mkdir /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/ophidia-io-server && \
	cd ophidia-io-server && \
	git checkout $branch_io_server && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=/usr/local/ophidia/oph-cluster/oph-io-server --with-netcdf-path=/usr/local/ophidia/extra/netcdf-ts/ --enable-parallel-nc4 > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	mkdir -p /usr/local/ophidia/oph-cluster/oph-io-server/data1/var && \
	mkdir -p /usr/local/ophidia/oph-cluster/oph-io-server/data1/log && \
	rm -rf /usr/local/ophidia/src ; fi

USER root

RUN if [ "$thread_safe" != "yes" ] && [ "$devel" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-io-server/releases/download/v$version/ophidia-io-server_$version*.deb && \
	apt install -y ophidia-io-server_*.deb && apt autoremove -y && apt clean -y && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	sed -i "s/127.0.0.1/0.0.0.0/g" /usr/local/ophidia/oph-cluster/oph-io-server/etc/oph_ioserver.conf && \
	rm -rf /repo/* ; fi

RUN if [ "$main_partition" = "yes" ] ; then \
	service mysql start && while [ ! -S /var/run/mysqld/mysqld.sock ]; do sleep 1; done && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO host (hostname, cores, memory, status) SELECT '127.0.0.1', 4, 1, 'up' FROM DUAL WHERE NOT EXISTS (SELECT hostname FROM host WHERE hostname = '127.0.0.1') LIMIT 1;" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO dbmsinstance (idhost, login, password, port, ioservertype) SELECT host.idhost, 'root', 'abcd', 65000, 'ophidiaio_memory' FROM host WHERE hostname = '127.0.0.1' AND NOT EXISTS (SELECT * FROM dbmsinstance INNER JOIN host ON host.idhost = dbmsinstance.idhost WHERE hostname = '127.0.0.1' AND port = 65000) LIMIT 1;" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO hostpartition (partitionname) VALUES ('main');" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT IGNORE INTO hashost (idhostpartition, idhost) SELECT 1, host.idhost FROM host WHERE hostname='127.0.0.1';" ; fi

RUN if [ $ioservers -gt 0 ] ; then \
	service mysql start && while [ ! -S /var/run/mysqld/mysqld.sock ]; do sleep 1; done && \
	for i in $(seq 1 $ioservers) ; do \
	port=$((65000 + i)) && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO host (hostname, cores, memory, status) SELECT '127.0.$i.1', 4, 1, 'down' FROM DUAL WHERE NOT EXISTS (SELECT hostname FROM host WHERE hostname='127.0.$i.1') LIMIT 1;" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO dbmsinstance (idhost, login, password, port, ioservertype) SELECT host.idhost, 'root', 'abcd', $port, 'ophidiaio_memory' FROM host WHERE hostname = '127.0.$i.1' AND NOT EXISTS (SELECT * FROM dbmsinstance INNER JOIN host ON host.idhost = dbmsinstance.idhost WHERE hostname = '127.0.$i.1' AND port = $port) LIMIT 1;" ; done ; fi

#OPHIDIA ANALYTICS FRAMEWORK
RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia Analytics Framework" && \
	apt install -y libjansson-dev libssh2-1-dev libssl-dev gsl-bin libgslcblas0 libgsl-dev libcfitsio-dev && apt autoremove -y && apt clean -y && \
	mkdir -p /var/www/html/ophidia && \
	chown ophidia:ophidia /var/www/html/ophidia ; fi

USER ophidia

RUN if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	mkdir -p /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/ophidia-analytics-framework && \
	cd ophidia-analytics-framework && \
	git checkout $branch_analytics_framework && \
	./bootstrap > /dev/null 2>&1 && \
	if [ "$zarr" = "yes" ] ; then enable_zarr = "--enable-zarr" ; fi && \
	./configure --prefix=/usr/local/ophidia/oph-cluster/oph-analytics-framework --enable-parallel-netcdf --with-netcdf-path=/usr/local/ophidia/extra/netcdf-ts/ --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia --with-ophidiaio-server-path=/usr/local/ophidia/oph-cluster/oph-io-server --enable-cfitsio --with-debug-level=$debug_level $enable_zarr > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /usr/local/ophidia/src && \
	mkdir -p /usr/local/ophidia/oph-cluster/oph-analytics-framework/log ; fi

USER root

RUN if [ "$thread_safe" != "yes" ] && [ "$devel" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-analytics-framework/releases/download/v$version/ophidia-analytics-framework_$version*.deb && \
	apt install -y ophidia-analytics-framework_*.deb && apt autoremove -y && apt clean -y && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	chown -R ophidia:ophidia /var/www/html/ophidia && \
	rm -rf /repo/* ; fi

#CJOSE
RUN if [ "$cjose" = "yes" ] ; then \
	cd /repo && \
	curl -s -LOJk https://github.com/cisco/cjose/archive/0.4.1.tar.gz && \
	tar -xzf cjose-0.4.1.tar.gz && \
	cd cjose-0.4.1 && \
	./configure --prefix=/usr/local/ophidia/extra > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /repo/* ; fi

#OPHIDIA SERVER
RUN if [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia Server" && \
	mkdir -p /var/www/html/ophidia && \
	chown -R ophidia:ophidia /var/www/html/ophidia ; fi

USER ophidia

RUN if [ "$devel" = "yes" ] ; then \
	mkdir -p /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/ophidia-server && \
	cd ophidia-server && \
	git checkout $branch_server && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=/usr/local/ophidia/oph-server --with-framework-path=/usr/local/ophidia/oph-cluster/oph-analytics-framework --enable-webaccess --with-web-server-path=/var/www/html/ophidia --with-web-server-url=http://127.0.0.1/ophidia --with-ws-hostname=localhost --with-matheval-path=/usr/lib/$(uname -m)-linux-gnu > /dev/null 2>&1 && \
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
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-server/releases/download/v$version/ophidia-server_$version*.deb && \
	apt install -y ophidia-server_*.deb && apt autoremove -y && apt clean -y && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	touch /usr/local/ophidia/oph-server/log/server.log && \
	sed -i "s/OPH_MAX_CORES=.*/OPH_MAX_CORES=0/g" /usr/local/ophidia/oph-server/authz/users/oph-test/user.dat && \
	sed -i "s/OPH_MAX_CORES=.*/OPH_MAX_CORES=0/g" /usr/local/ophidia/oph-server/authz/users/framework/user.dat && \
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
	mkdir -p /usr/local/ophidia/oph-server/etc/cert && \
	cp cacert.pem myserver.pem /usr/local/ophidia/oph-server/etc/cert && \
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

#OPHIDIA TERMINAL
RUN if [ "$devel" = "yes" ] ; then \
	echo "Using online source code for Ophidia Terminal" && \
	apt install -y graphviz-dev libgtk2.0-dev policycoreutils-python-utils libreadline-dev && apt autoremove -y && apt clean -y ; fi

USER ophidia

RUN if [ "$devel" = "yes" ] ; then \
	mkdir -p /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/ophidia-terminal && \
	cd ophidia-terminal && \
	git checkout $branch_terminal && \
	./bootstrap > /dev/null 2>&1 && \
	./configure --prefix=/usr/local/ophidia/oph-terminal --disable-xml-ssl-check --disable-xml-removal > /dev/null 2>&1 && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /usr/local/ophidia/src ; fi

USER root

RUN if [ "$devel" != "yes" ] ; then \
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-terminal/releases/download/v$version/ophidia-terminal_$version*.deb && \
	apt install -y ophidia-terminal_*.deb && apt autoremove -y && apt clean -y && \
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

USER root

ENV PATH=/usr/local/ophidia/extra/bin:/usr/local/ophidia/extra/netcdf-ts/bin:$PATH

COPY server_scripts/oph_submit.sh /usr/local/ophidia/extra/etc/

RUN if [ "$jupyter" = "yes" ] || [ "$python" = "yes" ] ; then \
    apt install -y graphviz && apt autoremove -y && apt clean -y ; fi

ENV CONDA_DIR=/opt/conda
RUN if [ "$jupyter" = "yes" ] || [ "$python" = "yes" ] ; then \
    wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-$(uname -m).sh -O miniconda.sh && \
    bash miniconda.sh -b -p /opt/conda && \
    rm -r miniconda.sh ; fi
ENV PATH=$CONDA_DIR/bin:$PATH

USER ophidia

ENV PATH=$CONDA_DIR/bin:$PATH
ADD environment.yml /tmp/environment.yml
RUN if [ "$jupyter" = "yes" ] || [ "$python" = "yes" ] ; then \
    conda env create -f /tmp/environment.yml -p /usr/local/ophidia/env ; fi

USER root

RUN rm -r /tmp/environment.yml

USER ophidia

ENV PATH=/usr/local/ophidia/env/bin:$PATH:/usr/local/ophidia/proj/bin:/usr/local/ophidia/.local/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/ophidia/proj/lib:/usr/local/ophidia/.local/lib

RUN echo "export PATH=$PATH" >> ~/.bashrc && \
	echo "export LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> ~/.bashrc

RUN if [ "$jupyter" = "yes" ] ; then \
	pip install jupyterlab && \
	mkdir -p /usr/local/ophidia/.jupyter/ && \
	touch /usr/local/ophidia/.jupyter/jupyter_server_config.json && \
	printf "{\n  \"ServerApp\": {\n    \"password\": \"argon2:\$argon2id\$v=19\$m=10240,t=10,p=8\$qowYWxFJARKuf//IthKHmQ\$MHA01UDBcUa40VXEjL6apw\"\n  }\n}" > /usr/local/ophidia/.jupyter/jupyter_server_config.json && \
	chmod 600 /usr/local/ophidia/.jupyter/jupyter_server_config.json && \
	printf "\nYour jupyter password is:\t\'ophidia\'\n" ; fi

RUN if [ "$jupyter" = "yes" ] || [ "$python" = "yes" ] ; then \
	mkdir -p /usr/local/ophidia/src && \
	cd /usr/local/ophidia/src && \
	git clone https://github.com/OphidiaBigData/PyOphidia.git && \
	cd PyOphidia/ && \
	git checkout $branch_pyophidia && \
	pip install . && \
	cp -r PyOphidia/utils /usr/local/ophidia/ && \
	cp -r examples /usr/local/ophidia/ && \
	rm -f /usr/local/ophidia/examples/utils/tasks && \
	cp -r PyOphidia/utils/tasks /usr/local/ophidia/examples/utils/ && \
	rm -rf /usr/local/ophidia/src ; fi

RUN if [ "$jupyter" = "yes" ] || [ "$python" = "yes" ] ; then \
	echo "export PATH=$PATH:/usr/local/ophidia/utils" >> ~/.bashrc && \
	echo "source activate /usr/local/ophidia/env" >> ~/.bashrc && \
	conda clean -y --all ; fi

USER root

#CDO
RUN	if [ "$cdo" = "yes" ] ; then \
	cd /repo && \
	curl -s -O -k https://code.mpimet.mpg.de/attachments/download/29649/cdo-2.4.4.tar.gz && \
	tar -xzf cdo-2.4.4.tar.gz && \
	cd cdo-2.4.4 && \
	if [ "$thread_safe" = "yes" ] || [ "$devel" = "yes" ] ; then \
	PYTHON="/usr/bin/python3" CFLAGS="-I/usr/local/ophidia/extra/hdf5-ts/include -I/usr/local/ophidia/extra/netcdf-ts/include -I/usr/lib/$(uname -m)-linux-gnu/mpich/include" CPPFLAGS="-I/usr/local/ophidia/extra/hdf5-ts/include -I/usr/local/ophidia/extra/netcdf-ts/include -I/usr/lib/$(uname -m)-linux-gnu/mpich/include" LDFLAGS="-L/usr/local/ophidia/extra/hdf5-ts/lib -L/usr/local/ophidia/extra/netcdf-ts/lib" ./configure --prefix=/usr/local/ophidia/extra --with-hdf5=yes --with-netcdf=yes > /dev/null 2>&1 ; else \
	PYTHON="/usr/bin/python3" CFLAGS="-I/usr/include -I/usr/include/hdf5/serial -I/usr/lib/$(uname -m)-linux-gnu/mpich/include" CPPFLAGS="-I/usr/include -I/usr/include/hdf5/serial -I/usr/lib/$(uname -m)-linux-gnu/mpich/include" LDFLAGS="-L/usr/lib/$(uname -m)-linux-gnu" ./configure --prefix=/usr/local/ophidia/extra --with-hdf5=yes --with-netcdf=yes > /dev/null 2>&1 ; fi && \
	make -s > /dev/null 2>&1 && \
	make install -s > /dev/null 2>&1 && \
	rm -rf /repo/* ; fi

RUN	service mysql start && \
	while [ ! -S /var/run/mysqld/mysqld.sock ]; do sleep 1; done && \
	MYSQL_PWD="abcd" mysql -u root -e "DROP USER 'root'@'localhost'; CREATE USER 'root'@'%' IDENTIFIED BY 'abcd'; GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"

RUN	if [ "$valgrind" = "yes" ] ; then \
	apt install -y valgrind && \
	apt autoremove -y && apt clean -y ; fi

COPY ssl-params.conf /etc/apache2/conf-available/
COPY server_scripts/oph_submit.sh /usr/local/ophidia/oph-server/etc/script/oph_submit.sh
COPY server_scripts/oph_cancel.sh /usr/local/ophidia/oph-server/etc/script/oph_cancel.sh
COPY server_scripts/oph_start.sh /usr/local/ophidia/oph-server/etc/script/oph_start.sh
COPY server_scripts/oph_check.sh /usr/local/ophidia/oph-server/etc/script/oph_check.sh
COPY server_scripts/start_ioserver.sh /usr/local/ophidia/oph-server/etc/script/start_ioserver.sh
COPY server_scripts/stop_ioserver.sh /usr/local/ophidia/oph-server/etc/script/stop_ioserver.sh
COPY server_scripts/oph_ioserver.conf.template /usr/local/ophidia/oph-server/etc/script/oph_ioserver.conf.template
COPY entrypoint.sh /

RUN	echo "ENABLE_CLUSTER_DEPLOYMENT=yes\nENABLE_CLUSTER_INCREASE=yes" >> /usr/local/ophidia/oph-server/etc/server.conf

EXPOSE 11732
EXPOSE 8888
EXPOSE 65000

ENV JUPYTER=$jupyter
ENV PYTHON=$python
ENV MAIN_PARTITION=$main_partition

ENTRYPOINT ["/entrypoint.sh"]
