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
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-primitives/releases/download/v1.8.0/ophidia-primitives-1.8.0-0.el7.centos.x86_64.rpm  && \
	yum -y install ophidia-primitives-*.rpm && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	rm -rf /repo/* && \
	cp /usr/local/ophidia/oph-cluster/oph-primitives/lib/liboph_*.so /usr/lib64/mysql/plugin && \
	sed -i '/GRANT/d' /usr/local/ophidia/oph-cluster/oph-primitives/etc/create_func.sql && \
	yum -y clean all

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
	cd /repo && wget -q https://github.com/OphidiaBigData/ophidia-io-server/releases/download/v1.8.0/ophidia-io-server-1.8.0-0.el7.centos.x86_64.rpm && \
	yum -y install ophidia-io-server-*.rpm && yum -y clean all && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	sed -i "s/127.0.0.1/0.0.0.0/g" /usr/local/ophidia/oph-cluster/oph-io-server/etc/oph_ioserver.conf && \
	rm -rf /repo/* ; fi

RUN yum -y install libcurl libcurl-devel libssh2 libssh2-devel perl-IPC-Cmd perl-Test-Simple

USER root

COPY server_scripts/oph_submit.sh /usr/local/ophidia/oph-server/etc/script/oph_submit.sh
COPY entrypoint_worker.sh /

EXPOSE 65000

LABEL OFFLINE_OPHIDIA_RPMS=$offline_ophidia THREAD_SAFE=$thread_safe

#CMD ["/bin/bash"]
ENTRYPOINT ["/entrypoint_worker.sh"]