# JupyterLab image for itwinai with Rucio client

The files in this folder are adapted from the work done by [itwinai](https://github.com/interTwin-eu/itwinai/tree/itwinai-jlab/env-files/torch/jupyter).

To build this container run

```bash
docker build -t jupyter .
```

Run the associated image as follows

```
docker run --rm -it -p 8888:8888 jupyter:latest
```

Additional arguments can also be specified for this case:
- ```OPH_SERVER_HOST```: Ophidia Server IP Address (default: 172.17.0.2).
- ```OPH_SERVER_PORT```: Ophidia Server port (default: 11732).
- ```OPH_USER```: Ophidia user (default: oph-test).
- ```OPH_PASSWD```: Ophidia password (default: abcd).

For example: 

```
$ docker run --rm -it -p 8888:8888 \
-e OPH_SERVER_HOST='172.17.0.2' \
-e OPH_SERVER_PORT='11732' \
-e OPH_USER='oph-test' \
-e OPH_PASSWD='abcd' \
jupyter:latest
```
