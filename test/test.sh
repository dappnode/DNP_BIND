# Beware in the test docker-compose that travis 
# will do a docker-compose up in a the directory DNPBIND
# Therefore the name of the network has to be dnpbind_network

test_path=$(dirname $0)
docker-compose -f $test_path/../docker-compose-bind.yml up -d
docker-compose -f $test_path/docker-compose-test.yml run test
