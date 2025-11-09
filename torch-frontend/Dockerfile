FROM  ghcr.io/intertwin-eu/itwinai-dev:jlab-test-1

USER root

RUN apt-get update && apt-get install -y graphviz nodejs netcdf-bin cdo nco w3m && apt-get clean -y

# Additional directory for ML4Fires
#RUN	mkdir -p /ceph
#RUN	chown $NB_UID:$NB_UID /ceph

USER $NB_UID

# Additional packages for ML4Fires
#RUN	pip install rucio rucio-clients dask
#RUN	pip install --force-reinstall -v "mlflow==2.22.1"

# Additional packages for PyOphidia
ENV PYOPHIDIA_DIR=$HOME/pyophidia
RUN mkdir -p $PYOPHIDIA_DIR
ADD requirements.txt $PYOPHIDIA_DIR/requirements.txt
RUN pip install --no-cache-dir -r $PYOPHIDIA_DIR/requirements.txt
RUN rm -rf $PYOPHIDIA_DIR/requirements.txt

# PyOphidia
RUN mkdir -p $PYOPHIDIA_DIR/src && \
	cd $PYOPHIDIA_DIR/src && \
	git clone https://github.com/OphidiaBigData/PyOphidia.git && \
	cd PyOphidia/ && \
	git checkout release && \
	python -m pip install ".[convert,cwl,prov,display]" && \
	cp -r pyophidia/utils $PYOPHIDIA_DIR/ && \
	cp -r examples $PYOPHIDIA_DIR/ && \
	rm -f $PYOPHIDIA_DIR/examples/utils/tasks && \
	cp -r pyophidia/utils/tasks $PYOPHIDIA_DIR/examples/utils/ && \
	rm -rf $PYOPHIDIA_DIR/src && \
	echo "export PATH=$PATH:$PYOPHIDIA_DIR/utils" >> ~/.bashrc

ENV PATH=$PATH:$PYOPHIDIA_DIR/utils

ENV OPH_SERVER_HOST="172.17.0.2"
ENV OPH_SERVER_PORT="11732"
ENV OPH_USER="oph-test"
ENV OPH_PASSWD="abcd"

WORKDIR $HOME

CMD ["setup.sh", "start-notebook.sh"]
