FROM spack/centos7

LABEL author="CMCC Foundation" description="Ophidia HPDA framework"

ARG offline_ophidia=no
ARG thread_safe=yes

USER root
RUN cd / && \
        yum -y update yum && \
        yum -y update && \
        yum -y install epel-release && \
        yum -y clean all

RUN yum -y --nogpgcheck install http://repo.mysql.com/mysql57-community-release-el7.rpm && \
	yum -y --nogpgcheck install mysql-community-devel mysql-community-server && \
	yum -y clean all

RUN sed -i "s|# build_jobs: 16|build_jobs: 2|g" $SPACK_ROOT/etc/spack/defaults/config.yaml
RUN echo "[LOG] OPHIDIA COMPONENTS INSTALLATION"
RUN spack install ophidia-primitives
RUN spack install ophidia-io-server
RUN spack install ophidia-analytics-framework
RUN spack install ophidia-server

#POST_INSTALL SCRIPT
RUN chmod -R 777 /var/lib/mysql && \
    chown mysql:mysql /var/lib/mysql && \
	chmod 777 /var/log/ && \
	mkdir -p /repo && \
	chmod -R 777 /repo && \
	mkdir -p /usr/local/ophidia && \
    mkdir -p /usr/local/ophidia/oph-cluster && \
    cd /usr/local/ophidia/oph-cluster && ln -s `spack location -i ophidia-primitives` oph-primitives && \
    cd /usr/local/ophidia/oph-cluster && ln -s `spack location -i ophidia-io-server` oph-io-server && \
    cd /usr/local/ophidia/oph-cluster && ln -s `spack location -i ophidia-analytics-framework` oph-analytics-framework && \
    cd /usr/local/ophidia && ln -s `spack location -i ophidia-server` oph-server && \
    ls -la /usr/local/ophidia && \
	useradd -r ophidia -d /usr/local/ophidia && \
    usermod -u 1000 ophidia && \
	groupmod -g 1000 ophidia && \
    chown -R ophidia:ophidia /usr/local/ophidia && \
    chown -R ophidia:ophidia $SPACK_ROOT/opt/spack/linux-centos7-haswell/gcc-4.8.5

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
# OPHIDIA PRIMITIVES
RUN cp /usr/local/ophidia/oph-cluster/oph-primitives/lib/liboph_*.so /usr/lib64/mysql/plugin && \
	sed -i '/GRANT/d' /usr/local/ophidia/oph-cluster/oph-primitives/etc/create_func.sql

USER mysql
RUN mysqld & &> /dev/null ;\
	while [ ! -S /var/lib/mysql/mysql.sock ]; do sleep 1; done && \
	MYSQL_PWD="abcd" mysql -u root mysql < /usr/local/ophidia/oph-cluster/oph-primitives/etc/create_func.sql && \
	MYSQL_PWD="abcd" mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'abcd' WITH GRANT OPTION;" && \
	MYSQL_PWD="abcd" mysql -u root -e "FLUSH PRIVILEGES;" && \
	MYSQL_PWD="abcd" mysql -u root ophidiadb -e "INSERT INTO hostpartition (partitionname) VALUES ('main');"

USER root
# IO SERVER PER FRAMEWORK
RUN chown -R ophidia:ophidia /usr/local/ophidia && \
	sed -i "s/127.0.0.1/0.0.0.0/g" /usr/local/ophidia/oph-cluster/oph-io-server/etc/oph_ioserver.conf
#OPHIDIA ANALYTICS FRAMEWORK
RUN mkdir -p /var/www/html/ophidia && \
	chown ophidia:ophidia /var/www/html/ophidia 

#OPHIDIA SERVER
RUN spack stage ophidia-server && spack cd ophidia-server && cp -r authz /usr/local/ophidia/oph-server/
RUN chown -R ophidia:ophidia /usr/local/ophidia && \
    chown -R ophidia:ophidia $SPACK_ROOT/opt/spack/linux-centos7-haswell/gcc-4.8.5
    
USER ophidia
RUN mkdir -p /usr/local/ophidia/oph-cluster/oph-analytics-framework/log
RUN mkdir -p /var/www/html/ophidia/sessions
RUN mkdir -p /usr/local/ophidia/oph-server/log && \
    mkdir -p /usr/local/ophidia/oph-server/authz/sessions && \
    mkdir -p /usr/local/ophidia/oph-server/etc/cert

USER root
RUN chown -R ophidia:ophidia /usr/local/ophidia && \
    chown -R ophidia:ophidia /var/www/html/ophidia && \
    sed -i "s/OPH_MAX_CORES=.*/OPH_MAX_CORES=0/g" /usr/local/ophidia/oph-server/authz/users/oph-test/user.dat && \
    sed -i "s/OPH_MAX_CORES=.*/OPH_MAX_CORES=0/g" /usr/local/ophidia/oph-server/authz/users/framework/user.dat
    
RUN ldconfig /usr/lib/openssl-3.0.7/lib64/

COPY openssl.cnf /usr/tmp/openssl.cnf
RUN cp /usr/tmp/openssl.cnf `spack location -i openssl`/etc/openssl/


RUN cd /usr/local/ophidia/oph-server/etc/cert && \
	`spack location -i openssl`/bin/openssl req -newkey rsa:2048 \
        -passout pass:abcd \
        -subj "/" -sha256 \
        -keyout rootkey.pem \
        -out rootreq.pem && \
    `spack location -i openssl`/bin/openssl x509 -req -in rootreq.pem \
        -passin pass:abcd \
        -sha256 \
        -extfile /usr/tmp/openssl.cnf \
        -extensions v3_ca \
        -signkey rootkey.pem \
        -out cacert.pem \
        -days 1095 && \
   cat cacert.pem rootkey.pem  > root.pem

RUN cd /usr/local/ophidia/oph-server/etc/cert && \
	`spack location -i openssl`/bin/openssl req -newkey rsa:2048 \
        -passout pass:abcd \
        -subj "/" -sha256 \
        -keyout myserverkey.pem \
        -out myserverreq.pem && \
   `spack location -i openssl`/bin/openssl x509 -req \
        -in myserverreq.pem \
        -passin pass:abcd \
        -sha256 -extfile /usr/tmp/openssl.cnf -extensions usr_cert \
        -CA root.pem \
        -CAkey root.pem \
        -CAcreateserial \
        -out myservercert.pem -days 1095 && \
   cat myserverkey.pem myservercert.pem > myserver.pem && \
   cat myservercert.pem cacert.pem > myservertmp.pem && \
   mv -f myservertmp.pem myservercert.pem 

USER root
#WEB SERVER

RUN	mkdir -p /etc/httpd/conf/ssl && \
	cd /etc/httpd/conf/ssl && \
	`spack location -i openssl`/bin/openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -out server.crt -keyout server.key -subj "/"

#OPERATORS_FIXES
RUN cd /usr/local/ophidia/oph-cluster/oph-analytics-framework/etc/operators_xml/ && \
	sed -i "s/mysql_table|//" OPH_IMPORTNC_operator_1.0.xml OPH_INSTANCES_operator_1.0.xml OPH_RANDCUBE_operator_1.0.xml && \
	sed -i "s/default=\"mysql_table/default=\"ophidiaio_memory/" OPH_IMPORTNC_operator_1.0.xml OPH_RANDCUBE_operator_1.0.xml && \
	sed -i "s/ophidiaio_memory|all/ophidiaio_memory/" OPH_INSTANCES_operator_1.0.xml && \
	sed -i "s/values=\"ophidiaio_memory\">ioserver_filter/values=\"all|ophidiaio_memory\">ioserver_filter/" OPH_INSTANCES_operator_1.0.xml && \
	sed -i "s/maxvalue=\"10000\">limit_filter/maxvalue=\"100000000\">limit_filter/" OPH_EXPLORECUBE_operator_1.0.xml

COPY server_scripts/oph_submit.sh /usr/local/ophidia/oph-server/etc/script/oph_submit.sh
RUN chmod +x /usr/local/ophidia/oph-server/etc/script/oph_submit.sh
COPY entrypoint_master.sh /

EXPOSE 11732
EXPOSE 3306

LABEL OFFLINE_OPHIDIA_RPMS=$offline_ophidia THREAD_SAFE=$thread_safe

ENTRYPOINT ["/entrypoint_master.sh"]

