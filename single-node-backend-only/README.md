# Ready-to-use ***Ophidia HPDA Framework*** (Backend only) in a single Docker container

## Requirements:
- Linux Kernel (tested on CentOS 7 OS and Windows Subsystem for Linux 2 Kernel)
- Docker for Linux (tested with >=v17) or Docker Desktop for Windows (tested with >=v4.0.1 on engine >=20.10.8)
- At least 1.8GB of free disk space (according to which option is activated). 

## Image build instruction:
To build the image run:

```
$ docker build -t ophidia .
```

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
$ docker run --rm -d -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH ophidia:latest
```

The following subsections will provide additional details about the possible options available.

#### Ophidia software stack deploy as PyOphidia or Ophidia Terminal backend

Additional environment variables can be specified for this case:

- ```MEMORY```: the RAM limit (in MB) used by Ophidia. Default maximum memory allocation is 2GB. For example if you want to use maximum 4GB of RAM, run: 

  ```
  $ docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH -e MEMORY=4096 ophidia:latest
  ```

- ```DEBUG```: a flag to enable the debug mode (not active by default). For example:

  ```
  $ docker run --rm -it -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH -e DEBUG=1 ophidia:latest
  ```

##### Run notes:

- If running with Docker Desktop for Windows (with WSL2 Kernel), note that the *"NETCDF\_FILES\_HOST\_PATH"* binding string must be in Windows' directory path specification convention (i.e. use backslashes instead of forward slashes).
- If running with Docker Desktop for Mac on Apple silicon add ```--platform linux/amd64``` to the *docker run* command before the image name to run the image under emulation.

