FROM ophidiabigdata/ophidia-backend:latest

USER root

RUN usermod -u 1001 ophidia && \
    find / -ignore_readdir_race -user 1000 -exec chown -h ophidia {} \;

RUN useradd -u 1000 -g users -m jovyan

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
