n_workers=$1

if [ -z "$n_workers" ];then
    n_workers=1
fi

echo "Deploying 1 master and ${n_workers} workers..."

# Start MASTER
docker run -it -d --name ophidia-multinode-master-spack -v /home/container-test/multi-node-spack/data:/usr/local/ophidia/data:Z -p 11732:11732 -e MEMORY=4096 -e DEBUG=1 ophidiabigdata/ophidia-multinode-master-spack:latest || :

while [ -z "$master_ip" ];do
    master_ip=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' ophidia-multinode-master-spack)
done
echo $master_ip

# Start WORKERS
    for i in $(seq 1 $n_workers)
    do
        sleep 10
        docker run -it -d --name ophidia-multinode-worker-spack_$i -v /home/container-test/multi-node-spack/data:/usr/local/ophidia/data -e MEMORY=4096 -e OPHDB_HOST=$master_ip ophidiabigdata/ophidia-multinode-worker-spack:latest
    done