FROM ghcr.io/intertwin-eu/itwinai:jlab-slim-0.3.0-torch2.4-jammy

USER root

RUN apt-get update && apt-get install -y graphviz && apt-get clean -y

USER $NB_UID

ENV PYOPHIDIA_DIR=$HOME/pyophidia
RUN mkdir -p $PYOPHIDIA_DIR
ADD requirements.txt $PYOPHIDIA_DIR/requirements.txt
RUN pip install --no-cache-dir -r $PYOPHIDIA_DIR/requirements.txt
RUN rm -rf $PYOPHIDIA_DIR/requirements.txt

RUN mkdir -p $PYOPHIDIA_DIR/src && \
	cd $PYOPHIDIA_DIR/src && \
	git clone https://github.com/OphidiaBigData/PyOphidia.git && \
	cd PyOphidia/ && \
	git checkout release && \
	python -m pip install ".[convert,prov,display]" && \
	cp -r pyophidia/utils $PYOPHIDIA_DIR/ && \
	cp -r examples $PYOPHIDIA_DIR/ && \
	rm -f $PYOPHIDIA_DIR/examples/utils/tasks && \
	cp -r pyophidia/utils/tasks $PYOPHIDIA_DIR/examples/utils/ && \
	rm -rf $PYOPHIDIA_DIR/src

ENV PATH=$PATH:$PYOPHIDIA_DIR/utils

ENV OPH_SERVER_HOST="172.17.0.2"
ENV OPH_SERVER_PORT="11732"
ENV OPH_USER="oph-test"
ENV OPH_PASSWD="abcd"

RUN	pip install jupyterhub==3.0.0

WORKDIR $HOME

CMD ["setup.sh", "start-notebook.sh"]
