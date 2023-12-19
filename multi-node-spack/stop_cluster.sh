n_workers=$1

if [ -z "$n_workers" ];then
    n_workers=1
fi

echo "Stopping 1 master and ${n_workers} workers..."

docker stop ophidia-multinode-master-spack
docker rm ophidia-multinode-master-spack
echo "master stopped and deleted"

for i in $(seq 1 $n_workers)
do
    sleep 5
    docker stop ophidia-multinode-worker-spack_$i
    docker rm ophidia-multinode-worker-spack_$i
    echo "worker_$i stopped and deleted"
done