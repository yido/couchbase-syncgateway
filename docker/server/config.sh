#!/usr/bin/env bash

# adapted from https://github.com/cha87de/couchbase-docker-cloudnative

function retry() {
    for i in $(seq 1 10); do
        $1
	if [[ $? == 0 ]]; then
	    return 0
	fi
	sleep 1
    done
    return 1
}

function bucketCreate(){
    couchbase-cli bucket-create -c localhost -u bucket_user -p password \
        --bucket=offline-reads \
        --bucket-type=couchbase \
        --bucket-ramsize=128 \
        --bucket-replica=0 \
        --wait
    if [[ $? != 0 ]]; then
        return 1
    fi
}

function indexCreate(){ 
    # PRIMARY INDEX
    cmd='CREATE PRIMARY INDEX `#primary` ON `offline-reads`'
    createOutput=$(cbq -e http://localhost:8093 -u bucket_user -p password --script="$cmd")
    if [[ $? != 0 ]]; then
        echo $createOutput >&2
        return 1
    fi
    # adv_DISTINCT_channels_syncTs INDEX
    cmd='CREATE INDEX `adv_DISTINCT_channels_syncTs` ON `offline-reads`((distinct (array `channel` for `channel` in `channels` end)),`syncTs`)'
    createOutput=$(cbq -e http://localhost:8093 -u bucket_user -p password --script="$cmd")
    if [[ $? != 0 ]]; then
        echo $createOutput >&2
        return 1
    fi
}

function clusterUp(){
    # initialize cluster
    initOutput=$(couchbase-cli cluster-init -c localhost \
            --cluster-username=bucket_user \
            --cluster-password=password \
            --cluster-port=8091 \
            --services=data,index,query,fts \
            --cluster-ramsize=256 \
            --cluster-index-ramsize=256 \
            --cluster-fts-ramsize=256 \
            --index-storage-setting=default)
    if [[ $? != 0 ]]; then
        echo $initOutput >&2
        return 1
    fi
}

function main(){
    /entrypoint.sh couchbase-server &
    if [[ $? != 0 ]]; then
        echo "Couchbase startup failed. Exiting." >&2
        exit 1
    fi

	# wait for service to come up
    until $(curl --output /dev/null --silent --head --fail http://localhost:8091); do
        sleep 10
    done

	if couchbase-cli server-list -c 127.0.0.1:8091 --username bucket_user --password password ; then
		echo "Couchbase already initialized, skipping initialization"
	else
        clusterUp
		if [[ $? != 0 ]]; then
			echo "Cluster init failed. Exiting." >&2
			wait
		fi

		retry bucketCreate
		if [[ $? != 0 ]]; then
			echo "Bucket create failed. Exiting." >&2
			exit 1
		fi

		sleep 10

		retry indexCreate
		if [[ $? != 0 ]]; then
			echo "Index create failed. Exiting." >&2
			exit 1
		fi
	fi

    # entrypoint.sh launches the server but since config.sh is pid 1 we keep it
    # running so that the docker container does not exit.
    wait
}

main
