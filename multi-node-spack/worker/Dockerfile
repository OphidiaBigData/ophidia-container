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

RUN sed -i "s|# build_jobs: 16|build_jobs: 2|g" $SPACK_ROOT/etc/spack/defaults/config.yaml
RUN echo "[LOG] OPHIDIA COMPONENTS INSTALLATION"
RUN spack install ophidia-io-server

#POST_INSTALL SCRIPT


RUN yum -y --nogpgcheck install http://repo.mysql.com/mysql57-community-release-el7.rpm && \
	yum -y --nogpgcheck install mysql-community-devel mysql-community-server mysql-community-client && \
	yum -y clean all && \
    chmod -R 777 /var/lib/mysql && \
    chown mysql:mysql /var/lib/mysql && \
	chmod 777 /var/log/ && \
	mkdir -p /repo && \
	chmod -R 777 /repo && \
	mkdir -p /usr/local/ophidia && \
    mkdir -p /usr/local/ophidia/oph-cluster && \
    cd /usr/local/ophidia/oph-cluster && ln -s `spack location -i ophidia-primitives` oph-primitives && \
    cd /usr/local/ophidia/oph-cluster && ln -s `spack location -i ophidia-io-server` oph-io-server && \
	useradd -r ophidia -d /usr/local/ophidia && \
    usermod -u 1000 ophidia && \
	groupmod -g 1000 ophidia && \
    chown -R ophidia:ophidia /usr/local/ophidia && \
    chown -R ophidia:ophidia $SPACK_ROOT/opt/spack/linux-centos7-haswell/gcc-4.8.5


ADD server_scripts/oph_submit.sh #offline_ophidia_*.tar.gz /offline_ophidia/

# OPHIDIA PRIMITIVES
RUN cp /usr/local/ophidia/oph-cluster/oph-primitives/lib/liboph_*.so /usr/lib64/mysql/plugin && \
	sed -i '/GRANT/d' /usr/local/ophidia/oph-cluster/oph-primitives/etc/create_func.sql

RUN chown -R ophidia:ophidia /usr/local/ophidia && \
    chown -R ophidia:ophidia $SPACK_ROOT/opt/spack/linux-centos7-haswell/gcc-4.8.5

USER ophidia

RUN mkdir -p /usr/local/ophidia/oph-cluster/oph-io-server/data1/var && \
	mkdir -p /usr/local/ophidia/oph-cluster/oph-io-server/data1/log

USER root

COPY entrypoint_worker.sh /

EXPOSE 65000

LABEL OFFLINE_OPHIDIA_RPMS=$offline_ophidia THREAD_SAFE=$thread_safe

ENTRYPOINT ["/entrypoint_worker.sh"]






