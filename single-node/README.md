# Ready-to-use ***Ophidia HPDA Framework*** in a single Docker container

## Requirements:
- Linux Kernel (tested on CentOS 7 OS and Windows Subsystem for Linux 2 Kernel)
- Docker for Linux (tested with >=v17) or Docker Desktop for Windows (tested with >=v4.0.1 on engine >=20.10.8)
- At least 4 GB of free disk space (according to which option is activated). 

## Image build instruction:
To build the image run:

```
$ docker build -t ophidia .
```

### Build notes:

Add ```--build-arg slurm=yes``` to the build command above to install and configure the Slurm resource managere in the container.

Add ```--build-arg jupyter=yes``` to the build command above to install and configure Jupyter Notebook and a set of Python modules in the container.

## Optional: Image squash instruction:

The following command can be used to reduce  (squash) the image size (around 40% smaller):

```
$ pip install docker-squash 
$ docker-squash -t ophidia:squashed ophidia:latest
$ docker rmi ophidia:latest
$ docker tag -t ophidia:squashed ophidia:latest
```

Visit https://pypi.org/project/docker-squash/ to read the full documentation.

## Container run instruction:

To start the container the following command can be used:

```
$ docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH ophidia:latest
```

The ```-d``` option can be added to the run command in order to run it in background as a service:

```
$ docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH -d ophidia:latest
```

The container can also be named by adding ```--name ophidia``` option to the command above in order to name the container:

```
$ docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH --name ophidia ophidia:latest
```

The following subsections will provide additional details about the possible options available.

#### Full Ophidia software stack with Jupyter Notebook

The ```DEPLOY=jupyter``` option (default) can be used to start the entire Ophidia Framework, a pre-configured Jupyter Notebook and the Python environment accessible from the host.  
Additional environment variables can be specified for this case:
- ```UI_PORT```: the Jupyter port. Default value is 8888. A different port, like 8889 can be specified as in the example: 

  ```
  $ docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH -e UI_PORT=8889 ophidia:latest
  ```

- ```MEMORY```: the RAM limit (in MB) used by Ophidia. Default maximum memory allocation is 2GB. For example if you want to use maximum 4GB of RAM, run: 

  ```
  $ docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH -e MEMORY=4096 ophidia:latest
  ```

- ```DEBUG```: a flag to enable the debug mode (not active by default). For example:

  ```
  $ docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH -e DEBUG=1 ophidia:latest
  ```

The Jupyter Notebook server can be accessed from the browser and the URL will be "http\://CONTAINER_IP:JUPYTER_PORT" (for example: ```http://172.17.0.2:8888/```). The URL will also be shown in the output of the running container. To login to the Jupyter Notebook server type "ophidia" as password.  

The container's IP Address can also be found by running for example: 

```
$ docker inspect CONTAINER_NAME | grep \"IPAddress\" | head -n 1 | awk '{print $2}'
```

The Jupyter Notebook working dir is "/home/ophidia". It is hence recommended to mount notebooks and files from the host under this folder to access them from the UI. For example: 

```
$ docker run --rm -it -v HOST_FILES_PATH:/home/ophidia/CONTAINER_PATH ophidia:latest jupyter
```

##### Run notes:

- If running with Docker Desktop for Windows (with WSL2 Kernel), on PowerShell add ```-p 8888:8888``` to the *docker run* command before the image name in the  Jupyter deploy mode. Note that the *"NETCDF\_FILES\_HOST\_PATH"* binding string must be in Windows' directory path specification convention (i.e. use backslashes instead of forward slashes). Open a browser and visit "http\://localhost:8888" or, in case of issues, open PowerShell, type "hostname" and use the resulting output as the first part of the URL to visit (i.e. "http\://HOSTNAME:8888").
- If running with Docker Desktop for Mac on Apple silicon add ```--platform linux/amd64``` to the *docker run* command before the image name to run the image under emulation.

#### Full Ophidia software stack only

The ```DEPLOY=terminal``` option can be used to start the entire Ophidia Framework and give access to a ready-to-use Ophidia Terminal. 
Additional arguments can be specified also for this case:

- ```MEMORY```: the RAM limit (in MB) used by Ophidia.
- ```DEBUG```: a flag to enable the debug mode.

For example:

```
$ docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH \
-e DEPLOY=terminal \
-e MEMORY=4096 \
-e DEBUG=1 \
ophidia:latest
```

#### Ophidia Terminal only

The ```DEPLOY=terminal_only``` option can be used to run only the Ophidia Terminal to be used with an existing Ophidia deployment.
Additional arguments can also be specified for this case:
- ```OPH_SERVER_HOST```: Ophidia Server IP Address (default: 172.17.0.3).
- ```OPH_SERVER_PORT```: Ophidia Server port (default: 11732).
- ```OPH_USER```: Ophidia user (default: oph-test).
- ```OPH_PASSWD```: Ophidia password (default: abcd).

For example: 

```
$ docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH \
-e DEPLOY=terminal_only \
-e OPH_SERVER_HOST='172.17.0.3' \
-e OPH_SERVER_PORT='11732' \
-e OPH_USER='oph-test' \
-e OPH_PASSWD='abcd' \
ophidia:latest
```
