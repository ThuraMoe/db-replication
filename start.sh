#!/bin/bash
# Local .env
if [ -f .env ]; then
    # Load Environment Variables
    export $(cat .env | grep -v '#' | sed 's/\r$//' | awk '/=/ {print $1}' )
fi

#docker-compose up -d

echo docker ps -aqf "name=^$MASTER_CONTAINER_NAME$" | tee -a "$(tty)"
exit
docker cp docker cp master-my.cnf $MASTER_CONTAINER_NAME:/etc/mysql/my.cnf
docker cp docker cp slave-my.cnf $SLAVE_CONTAINER_NAME:/etc/mysql/my.cnf

docker restart $MASTER_CONTAINER_NAME
docker restart $SLAVE_CONTAINER_NAME

# create replica user on master db container 
docker exec $MASTER_CONTAINER_NAME bash -c "mysql -h$MASTER_HOST_IP -P 3306 --protocol=tcp -uroot -p$MASTER_ROOT_PASSWORD -e \"CREATE USER '$REPLICA_USER_NAME'@'%' IDENTIFIED BY '$REPLICA_PASSWORD'; GRANT REPLICATION SLAVE ON *.* TO '$REPLICA_USER_NAME'@'%' IDENTIFIED BY '$REPLICA_PASSWORD'; FLUSH PRIVILEGES; \"; exit;"

# create replica user on master db container 
#docker exec $MASTER_CONTAINER_NAME bash -c "mysql -h$MASTER_HOST_IP -P 3306 --protocol=tcp -uroot -p$MASTER_ROOT_PASSWORD -e \"GRANT REPLICATION SLAVE ON *.* TO '$REPLICA_USER_NAME'@'%' IDENTIFIED BY '$REPLICA_PASSWORD';FLUSH PRIVILEGES;\"; exit;"

# connect slave to master connection
docker exec $SLAVE_CONTAINER_NAME bash -c "mysql -h$SLAVE_HOST_IP -P 3306 --protocol=tcp -uroot -p$SLAVE_ROOT_PASSWORD -e \"CHANGE MASTER TO MASTER_HOST='$MASTER_HOST_IP', MASTER_USER='$REPLICA_USER_NAME', MASTER_PASSWORD='$REPLICA_PASSWORD' \"; exit;"
