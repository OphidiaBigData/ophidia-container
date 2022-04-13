# Ready-to-use ***Ophidia HPDA Framework*** (Back-end only) image

This image is built from the `ophidiabigdata/ophidia-backend` base image to add the `jovyan` user, thus making it completely embeddable in a Jupyter environment based on the `jupyterhub/singleuser` image. 

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
$ docker tag ophidia:squashed ophidia:latest
```

Visit https://pypi.org/project/docker-squash/ to read the full documentation.

## Container run instruction:

To start the container the following command can be used:

```
$ docker run --rm -d -v NETCDF_FILES_HOST_PATH:CONTAINER_PATH ophidia:latest
```
