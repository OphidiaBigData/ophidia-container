FROM ophidiabigdata/ophidia-backend:latest

USER root

RUN yum -y install cronie

RUN usermod -u 1001 ophidia && \
    find / -ignore_readdir_race -user 1000 -exec chown -h ophidia {} \;

RUN useradd -u 1000 -g users -m jovyan

RUN usermod -a -G users ophidia
RUN chmod 775 /home/jovyan/

COPY entrypoint.sh /entrypoint.sh
COPY crontab_local /var/spool/cron/root
COPY fix_logs_permission.sh /root/fix_logs_permission.sh

ENTRYPOINT ["/entrypoint.sh"]