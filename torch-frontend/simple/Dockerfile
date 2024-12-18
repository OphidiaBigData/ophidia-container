FROM ghcr.io/intertwin-eu/itwinai-dev:jlab-0.2.2.dev-cmcc-v6

USER root

RUN apt-get update && apt-get install -y graphviz && apt-get clean -y

USER $NB_UID

ENV OPHIDIA_DIR=$HOME/ophidia
RUN mkdir -p $OPHIDIA_DIR
ADD requirements.txt $OPHIDIA_DIR/requirements.txt
RUN pip install --no-cache-dir -r $OPHIDIA_DIR/requirements.txt
RUN rm -rf $OPHIDIA_DIR/requirements.txt
RUN mkdir -p $OPHIDIA_DIR/src && \
	cd $OPHIDIA_DIR/src && \
	git clone https://github.com/OphidiaBigData/PyOphidia.git && \
	cd PyOphidia/ && \
	git checkout release && \
	pip install . && \
	cp -r PyOphidia/utils $OPHIDIA_DIR/ && \
	cp -r examples $OPHIDIA_DIR/ && \
	rm -f $OPHIDIA_DIR/examples/utils/tasks && \
	cp -r PyOphidia/utils/tasks $OPHIDIA_DIR/examples/utils/ && \
	rm -rf $OPHIDIA_DIR/src && \
	echo "export PATH=$PATH:$OPHIDIA_DIR/utils" >> ~/.bashrc

WORKDIR $HOME

CMD ["setup.sh", "start-notebook.sh"]
