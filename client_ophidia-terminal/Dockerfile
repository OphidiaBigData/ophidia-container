FROM centos:7

LABEL author="CMCC Foundation" description="Ophidia Terminal"

USER root

RUN cd / && \
	yum -y update yum && \
	yum -y update && \
	yum -y install epel-release wget && \
	yum -y clean all

RUN mkdir -p /usr/local/ophidia && \
	mkdir -p /usr/local/ophidia/extra && \
	useradd -r ophidia -d /usr/local/ophidia && \
	usermod -u 1000 ophidia && \
	groupmod -g 1000 ophidia && \
	chown -R ophidia:ophidia /usr/local/ophidia

RUN mkdir -p /repo && chmod -R 777 /repo && \
	cd /repo && wget --no-check-certificate -q https://download.ophidia.cmcc.it/rpm/1.6/ophidia-terminal-1.6.0-0.el7.centos.x86_64.rpm && \
	yum -y install ophidia-terminal-*.rpm && yum -y clean all && \
	chown -R ophidia:ophidia /usr/local/ophidia && \
	rm -rf /repo

ENV PATH="/usr/local/ophidia/oph-terminal/bin:$PATH"
ENV OPH_TERM_VIEWER=coloured

USER ophidia
WORKDIR /usr/local/ophidia/
RUN cd /usr/local/ophidia/
ENTRYPOINT ["oph_term"]
CMD ["-H","127.0.0.1","-P","11732","-u","oph-test","-p","abcd"]
