#!/bin/bash

test_dir=$(dirname $0)
docker stop DAppNodeCore-bind.dnp.dappnode.eth
docker rm DAppNodeCore-bind.dnp.dappnode.eth
docker volume rm dnp_bind_binddnpdappnodeeth_data
docker rmi $(docker images | awk '/bind.dnp.dappnode.eth/ {print $3}')
docker-compose -f $test_dir/../docker-compose-bind.yml build
docker-compose -f $test_dir/../docker-compose-bind.yml up -d
docker-compose -f $test_dir/docker-compose-test.yml build
docker-compose -f $test_dir/docker-compose-test.yml run test
docker rm test_test_run_1
docker rmi $(docker images | awk '/^test/ {print $3}')


