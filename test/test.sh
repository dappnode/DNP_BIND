# [On trusty]:
#   Beware in the test docker-compose that travis 
#   will do a docker-compose up in a the directory DNPBIND
#   Therefore the name of the network has to be dnpbind_network
# [On xenial]:
#   The name of the folder is DNP_BIND and the network dnp_bind_network

docker network create --driver bridge --subnet 172.33.0.0/16 dncore_network || echo "dncore_network already exists"
docker-compose -f docker-compose.yml up -d
docker-compose -f test/docker-compose-test.yml run test