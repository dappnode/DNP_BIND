docker-compose -f docker-compose-bind.yml build
docker-compose -f test/docker-compose-test.yml build

docker-compose -f docker-compose-bind.yml up -d 
docker-compose -f test/docker-compose-test.yml up