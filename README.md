# Create docker network
docker network create mysql_network

# Create master db
docker run -d --name db-master --network mysql_network -v ${pwd}/master:/var/lib/mysql -e MYSQL_ALLOW_EMPTY_PASSWORD=yes mysql:5.7.32

# Create slave db
docker run -d --name db-slave --network mysql_network -v ${pwd}/slave:/var/lib/mysql -e MYSQL_ALLOW_EMPTY_PASSWORD=yes mysql:5.7.32

# Create phpmyadmin with ARBITRARY to connect with any DB
docker run -d --name myadmin --network mysql_network -e PMA_ARBITRARY=1 -p 8080:80 phpmyadmin

# Checking DB container IP to connect from phpmyadmin
- docker inspect db-master
Get "IPAddress": "172.19.0.2", from Networks part and login with that host name to work with db-master database

- docker inspect db-slave
Get "IPAddress": "172.19.0.3", from Networks part and login with that host name to work with db-slave database

# Phpmyadmin Start
http://localhost:8080

# Replication

### I.Master (db-master container)

1. Login to master phpmyadmin. Click `Replication` button from db-master phpmyadmin and copy server-id,etc...
2. Create my.cnf file and paste server-id... to my.cnf file
3. Copy my.cnf to db-master container with this command
	*docker cp my.cnf container_id:/etc/mysql*
4. restart container
	*docker restart db-master*
5. Enter db-master container and check master status in mysql
	SHOW MASTER STATU\G;

	|File|Position|Binlog_Do_DB|Binlog_Ignore_DB|Binlog_Ignore_DB|Executed_Gtid_Set|
	|--|--|--|--|--|--|
	| master-bin.000001 | 154  |
	1 row in set (0.00 sec)
6. Create replica user in mysql
	*GRANT REPLICATION SLAVE ON *.* TO 'replicator'@'% IDENTIFIED BY '12345';*

### II.Slave (db-slave container)

1. Prepare my.cnf file with following setting
	[mysqld]
	#Set up server_ID, pay attention to be unique
	server-id=201
	#Enable the binary log function for use when slave is the master of other slave
	log-bin=mysql-slave-bin
	#relay_ Log configure relay log
	relay_log=mysql-relay-bin
	#Set to read-only. If this item is not set, it means that the slave is readable and writable
	read_only=1
2. copy my.cnf file to db-slave container
	*docker cp my.cnf container_id:/etc/mysql*
3. restart container
	*docker restart db-slave*
4. Enter db-slave container and execute following command to connect master host and specific user called `replicator` that created in master mysql server.
*change master to master_host='172.19.0.2', master_user='replicator', master_password='12345';*
5. Start slave with following command
	*start slave;*

### III. Create database in master will automatically create into slave database

  
  
  

# Ref:
#### master/slave replication
https://developpaper.com/configure-master-slave-server-based-on-docker-to-realize-mysql-master-slave-replication-8-0/
https://wpguru.co.uk/2013/05/how-to-setup-mysql-masterslave-replication-with-existing-data/

#### to change phpmyadmin setting
https://stackoverflow.com/questions/50620990/docker-phpmyadmin-ignoring-my-php-ini-config