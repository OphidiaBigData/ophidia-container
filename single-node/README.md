# Ready-to-use ***Ophidia HPDA Framework*** in a single Docker container

## Requirements:
- Linux OS (tested on CentOS 7)
- Docker (tested with >=v17)
- At least 4-5GB of free disk space (according to the various option is activated). 

## Image build instruction:
To build the image run:

```docker build -t ophidia .```

### Build notes:

Add ```--build-arg slurm=yes``` to the build command above to install and configure the Slurm resource managere in the container.

Add ```--build-arg jupyter=yes``` to the build command above to install and configure Jupyter Notebook and a set of Python modules in the container.

## Optional: Image squash instruction:

The following command can be used to reduce  (squash) the image size (around 40% smaller):

```
pip install docker-squash 
docker-squash -t ophidia:squashed ophidia:latest
docker rmi ophidia:latest
docker tag -t ophidia:squashed ophidia:latest
```

Visit https://pypi.org/project/docker-squash/ to read the full documentation.

## Container run instruction:
To start the container run the following command:

```docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH ophidia:latest```

The ```-d``` option can be added to the run command in order to run it in background as a service:

```docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH -d ophidia:latest```

The container can also be named by adding ```--name ophidia``` option to the command above in order to name the container:

```docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH --name ophidia ophidia:latest```

### Run notes:

Different execution scenarios are supported by specifying an additional argument at the end of the previous command.

#### Full software stack

The ```terminal``` argument (default) can be used to deploy the entire Ophidia Framework and give access to a ready-to-use Ophidia Terminal. 
Additional arguments can be specified for this case:
- RAM limit (in MB). Default maximum memory allocation is 2GB. For example if you want to use maximum 4GB of RAM, run: 

  ```docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH ophidia:latest terminal 4096```

- A flag to enable the debug mode (not active by default). For example: 

  ```docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH ophidia:latest terminal 2048 1```

#### Full software stack with Jupyter Notebook

The ```jupyter``` argument can be used to deploy the entire Ophidia Framework and a pre-configured Jupyter Notebook and Python environment accessible from the host.  
Additional arguments can also be specified for this case:
- Jupyter port. Default port is 8888. A different port, like 8889 can be specified as in the example: 

  ```docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH ophidia:latest jupyter 8889```

- RAM limit (in MB). Same as for the previous case. For example: 

  ```docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH ophidia:latest jupyter 8888 4096```

- Debug mode. Same as for the previous case. For example:  
  
  ```docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH ophidia:latest jupyter 8888 2048 1```

The Jupyter Notebook server can be accessed from the browser and the URL will be "http://CONTAINER_IP:JUPYTER_PORT" (for example: http://172.17.0.3:8888/). To access the Jupyter Notebook server type "ophidia" as password. The URL will be shown in the output of the running container. 

The container's IP Address can also be found by running for example: 

```docker inspect CONTAINER_NAME | grep \"IPAddress\" | head -n 1 | awk '{print $2}'```

The Jupyter Notebook working dir is "/home/ophidia". It is hence recommended to mount notebooks and files from the host under this folder to access them from the UI. For example: 

```docker run --rm -it -v HOST_FILES_PATH:/home/ophidia/files ophidia:latest jupyter```

#### Ophidia Terminal only

The ```terminal_only``` argument can be used to run only the Ophidia Terminal to be used with an existing Ophidia deployment.
Additional arguments can also be specified for this case:
- Ophidia Server IP Address (default: 172.17.0.3).
- Ophidia Server port (default: 11732).
- Ophidia user (default: oph-test).
- Ophidia password (default: abcd).

For example: 

```docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH ophidia:latest terminal_only 172.17.0.3 11732 oph-test abcd```
