# pgpool-postgresql-cluster

### Description
PostgreSQL HA Cluster With Pgpool

### Limits
* [**Pgpool-II Limits**](https://www.pgpool.net/docs/latest/en/html/restrictions.html)

### Pgpool-II's Features
Pgpool-II is a proxy software that sits between PostgreSQL servers and a PostgreSQL database client. It provides the following features:
 - Connection Pooling
 - Load Balancing
 - Automated fail over
 - Online Recovery
 - Replication
 - Limiting Exceeding Connections
 - Watchdog
 - In Memory Query Cache

### Deploy Cluster
#### Requirements
- Operating System Versions: RedHat/CentOS: 7.0+
- PostgreSQL Versions: 10+
- Ansible Versions: 2.7.10+

#### Preparing 
##### Node hosts
  In a highly available PostgresSQL cluster with Pgpool, recommended size of a node host  is the minimum requirements of 2 CPU cores and 16 GB of RAM.
  
  1.  Network Access Requirements
     A shared network must exist between the node hosts. 

  2. Required Ports
    Ensure the following ports required by PostgreSQL Cluster are open on your network and configured to allow access between hosts. 
     - 22/tcp   (sshd)
     - 5432/tcp (PostgreSQL accepts connectionts)
     - 6432/tcp (Pgpool-II accepts connections)
     - 9000/tcp (watchdog accepts connections)
     - 9898/tcp (PCP process accepts connections)
     - 9694/udp (UDP port for receiving Watchdog's heartbeat signal)
##### Installer host
  
  The PostgreSQL Cluster installer requires a user that has access to all hosts. If you want to run the installer as a non-root user, first configure passwordless sudo rights each host:
  
  1. Generate an SSH key on the host you run the installation playbook on:

  	# ssh-keygen 
  
  2. Distribute the key to the other cluster hosts. You can use a bash loop:

  	# for host in node1 \ 
            node2 \  
            node3; \ 
          do ssh-copy-id -i ~/.ssh/id_rsa.pub $host; \
          done 
  3. Confirm that you can access each host that is listed in the loop through SSH.

##### Install Ansible
  Install Ansible. To use EPEL as a package source for Ansible:
  
  1. Install the EPEL repository:

  	# yum -y install \
    	  https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

  2. Disable the EPEL repository globally so that it is not accidentally used during later steps of the installation:

  	# sed -i -e "s/^enabled=1/enabled=0/" /etc/yum.repos.d/epel.repo
  
  3. Install the packages for Ansible:

           # yum -y --enablerepo=epel install ansible pyOpenSSL



##### Virtual IP

  virtual IP address can floating  on all node hosts. Ensure that the IP address set to virtual IP isn't used yet.

#### Quick start
  
  PostgreSQL Cluster's node hosts and VIP example:
   - node1 172.28.1.11
   - node2 172.28.1.12
   - node2 172.28.1.13
   - vip 172.28.1.100

  1. Download or clone this repository on installer host:

  	# git clone http://gitlab.juneyao.com/guirui/postgresql-cluster.git

  2. Go to the playbook directory:
	
	# cd pgpool-postgresql-cluster
  
  3. Edit the inventory file:

  	# vim production

    For example:

          [master]
          172.28.1.11 hostname="node1"
     
          [replication]
          172.28.1.12 hostname="node2"
          172.28.1.13 hostname="node3"
    
          [postgres_cluster:children]
          master
          replication
   
          [all:vars]
          # Set PostgreSQL database user's password
         
          postgresql_superuser_password: "postgres" # username: postgres
          postgresql_replication_password: "repl"   # username: repl
          postgresql_pgpool_password: "pgpool"      #username: pgpool
   
          # Set Pgpool pcp user's password
          pgpool_pcp_password: "pgpool"             #username: pgpool
   
          # Set Cluster vip
          pgpool_vip: "172.28.1.100"                
          pgpool_vip_dev: "eth0"                   
          pgpool_vip_dev_label: "{{ pgpool_vip_dev }}:0" 
   
  4. Run playbook:
  	
	# ansible-playbook  postgresql-cluster.yml -i production

  5. Test client connetction:

	# psql -h 172.28.1.100 -p 6432 -U postgres postgres

### Exercise

  This exercise use Jupyter to control Ansible  on  build a virtual environment with docker.
  
  Go to exercise directory and run docker-compose command:
  
  	# cd example/docker
        # docker-compose up
 
  Open browser to URL: [**http://127.0.0.1:8888**](http://127.0.0.1:8888) 
 
  Input password: jupyter

  Crate a Notebook , insert ansibel command in a cell, then run command. for example:

	!ansible-playbook  postgresql-cluster.yml -i test 

### Maintenance
  Please note that the original design goal of this playbook was more concerned with the initial deploiment of a PostgreSQL HA Cluster and so it does not currently concern itself with performing ongoing maintenance of a cluster.   

  You should learn [**Pgpool**](https://www.pgpool.net/docs/latest/en/html/index.html) and [**PostgreSQL**](https://www.postgresql.org/docs/12/index.html) if the cluster for its further maintenance.
   
### Backup and Restore
  A high availability cluster provides an automatic failover mechanism, and does not cover all disaster recovery scenarios. You must take care of backing up your data yourself.
  
  Recommend the following backup and restore tools:
   - [**pgbackrest**](https://github.com/pgbackrest/pgbackrest)
   - [**pg_probackup**](https://github.com/postgrespro/pg_probackup)
   - [**wal-g**](https://github.com/wal-g/wal-g)
  Do not forget to validate your backups (for example [**pgbackrest auto**](https://github.com/vitabaks/pgbackrest_auto)).

### References
  * [**PostgreSQL Docs**](https://www.postgresql.org/docs/12/index.html)
  * [**Pgpool Docs**](https://www.pgpool.net/docs/latest/en/html/index.html)
### LICENSE
  [**Apache License 2.0**](LICENSE) 

### About
Email: [**stong1126@163.com**](stong1126@163.com)
