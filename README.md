#  基于[**Pgpool-II**](https://pgpool.net/) 的PostgreSQL高可用集群自动化部署

### 一、 基于 [**Ansible**](https://www.ansible.com/)自动化部署
该 Ansible Playbook 旨在在生产环境的专用物理服务器或云服务器上部署PostgreSQL高可用性集群。
可以将集群部署在虚拟机或docker中以用于测试环境和小型项目。

**注意!**  本 Playbook 不支持在已有的PostgreSQL数据库服务器上部署集群（部署安装将会清空已存在数据库数据）。

   
### 二、 使用限制和注意事项
为保障集群的稳定可用，PostgreSQL有部分使用上的约束。
  
> [**Pgpool-II 限制**](https://www.pgpool.net/docs/latest/en/html/restrictions.html)
  - pg_terminate_backend()用于停止后端，则将触发故障转移。在扩展协议模式下，您不能使用该功能。
  - Pgpool-II无法处理多语句查询（单行上有多个SQL命令）。
  - 临时表，请使用/*NO LOAD BALANCE*/  SQL声明。
  - SQL类型命令不能在扩展查询模式下使用。  
  - 客户端和后端PostgreSQL的字符编码必须相同。   
  - libpq版本必须为3.0或更高版本

>  PostgreSQL 数据库的root权限
  - 建议不要向使用用户提供superuser权限，因为对"postgresq"，"pgpool", "repl"数据库登陆用户的任何修改，包括删除、修改密码、修改权限等，都将造成集群不用！
    
> 注意事项
  - 必须保持集群内至少2台以上节点（Pgpool、Postgresql进程）正常运行，才能保证集群高可用。
    

### 三、 [**Pgpool-II 功能**](https://www.pgpool.net/docs/latest/en/html/intro-whatis.html)

  Pgpool-II是位于PostgreSQL服务器和 PostgreSQL数据库客户端之间的代理软件。它提供以下功能：
  - 连接池(Connection Pooling)
  - 负载均衡(Load Balancing)
  - 自动故障转移(Automated fail over)
  - 在线恢复(Online Recovery)
  - 主从复制（Replication）
  - 限制超额连接（Limiting Exceeding Connections）
  - 看门狗监控与检查(Watchdog)
  - 查询缓存 (In Memory Query Cache)
  
### 四、 部署集群 
 
#### 安装要求

##### 操作系统
基于RedHat的发行版（x86_64），最低操作系统版本： RedHat7、 CentOS: 7

经过测试，工作正常： `CentOS 7.6`

##### PostgreSQL版本：
支持的PostgreSQL10以上版本： 10、 11、 12

经过测试，工作正常： `PostgreSQL 11`

##### Ansible版本
- Ansible 2.7.10及更高版本

已在Ansible 2.8.6及更高版本上进行了测试。

#### 部署前准备

  1. 准备节点主机：  
     在部署 PostgreSQL 集群，必须准备节点主机（至少3台，建议5台），节点主机必须在同一网段上。

     建议配置： vCPU x 2核, 内存 16GB, (存储大小请根据实际业务需求规划)
     
     开放访问端口： 22/tcp, 5432/tcp, 6432/tcp, 9000/tcp, 9898/tcp, 9694/udp

     22/tcp：SSH（Secure Shell）服务的默认端口，用于远程登录和安全Shell访问。
     5432/tcp：PostgreSQL 数据库的默认端口，用于 PostgreSQL 服务器与客户端之间的通信。
     6432/tcp：通常也用于 PostgreSQL 数据库，但是不是默认端口，可能是用户自定义的其他 PostgreSQL 实例端口。
     9000/tcp：经常用于 Web 服务器（如 Nginx、Apache）和应用服务器（如 PHP-FPM）的默认端口。
     9898/tcp：可能是用户自定义的应用程序端口，具体用途取决于用户的配置和实际情况。
     9694/udp：也可能是用户自定义的应用程序端口，通常用于 UDP 协议通信，具体功能由用户进行配置。
   
   
  2. 准备安装主机：

     在部署 PostgreSQL 集群之前，必须准备Ansible主机。安装 Ansible，参见[**Ansible安装指南**](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
  
     确保主机访问， Ansible 自动化部署需要root权限或sudo。示例：
   
     第一步，在运行Ansible主机上生成SSH密钥：
    
         # ssh-keygen
             
     第二步，将密钥分配给群集节点主机。可以使用bash循环： 
    
         # for host in master.example.com \ 
           node1 \ 
           node2 \  
           node3; \ 
           do ssh-copy-id -i ~/.ssh/id_rsa.pub $host; \
           done
     
     第三步,确认可以通过SSH访问循环中列出的每个主机。

  3. 准备虚拟IP：

      请确保vip尚未使用，并在集群节点主机上漂移。

#### 快速开始

  假设主机和vip信息如下：
  - 主机名: node1, ip: 172.28.1.11
  - 主机名: node2, ip: 172.28.1.12
  - 主机名: node3, ip: 172.28.1.13
  - vip: 172.28.1.100
    
  1. 进入 postgresql-cluster 目录
  
         #cd postgresql-cluster
  
  2. 编辑主机清单文件，设置部署安装的相关变量（hostname, vip, password等）
      
         #vim production
      
     示例：
      
            [master]
            172.28.1.11 hostname="node1"
              
            [replication]
            172.28.1.12 hostname="node2"
            172.28.1.13 hostname="node3"
             
            [postgres_cluster:children]
            master
            replication
            
            [all:vars]
            # Set PostgreSQL database username and password
            postgresql_superuser_password: "postgres" #PostgreSQL 超级用户密码(username: postgres)
            postgresql_replication_password: "repl"   #PostgreSQL 复制用户密码(username: repl)
            postgresql_pgpool_password: "pgpool"      #PostgreSQL pgpool用户密码(username: pgpool)
            
            # Set Pgpool username and password
            pgpool_pcp_password: "pgpool"             #Pgpool pcp 用户密码(username: pgpool)
            
            # Set Cluster vip
            pgpool_vip: "172.28.1.100"                #虚拟IP
            pgpool_vip_dev: "eth0"                    #vip绑定的网卡
            pgpool_vip_dev_label: "{{ pgpool_vip_dev }}:0" # 虚拟网卡标签
        
  4. 运行Playbook， 部署集群
       
          #ansible-playbook  postgresql-cluster.yml -i production

  5. 客户端链接测试

          #psql -h 172.28.1.100 -p 6432 -U postgres postgres


### 五、 维护
  请注意，该Playbook的设计目标更多地与PostgreSQL 高可用群集的初始部署有关，因此，当前它与执行群集的持续维护无关。
  
  Pgpool常用命令，示例：

  1. [**Pgppol-PCP命令**](https://www.pgpool.net/docs/latest/en/html/pcp-commands.html)
  
     [**pcp_watchdog_info**](https://www.pgpool.net/docs/latest/en/html/pcp-watchdog-info.html)
   
     显示有关给定节点ID的信息。示例：
     
         # pcp_watchdog_info -h 172.28.1.100 -p 9898 -U pgpool -w
           3 YES server3:6432 Linux server3 server3

           server3:6432 Linux server3 server3 6432 9000 4 MASTER
           server1:6432 Linux server1 server1 6432 9000 7 STANDBY
           server2:6432 Linux server2 server2 6432 9000 7 STANDBY
  
     [**pcp_recovery_node**](https://www.pgpool.net/docs/latest/en/html/pcp-recovery-node.html)
     
     在线恢复故障节点附加到集群。示例：
    
          #pcp_recovery_node -h 172.28.1.100 -p 9898 -U pgpool -n 1 -w 

          pcp_recovery_node -- Command Successful
  2. [**Pgppol-SQL类型命令**](https://www.pgpool.net/docs/latest/en/html/sql-commands.html)
 
     [**PGPOOL SHOW**](https://www.pgpool.net/docs/latest/en/html/sql-pgpool-show.html) 显示Pgpool -II配置参数的当前值 。 示例：   
      
         #psql -h 172.28.1.100 -p 6432 -U postgres postgres  -c "show all" 
  
          Password for user postgres: 
                            name                  |                setting                 |                                                          description                                                    
                
          ----------------------------------------+----------------------------------------+-------------------------------------------------------------------------------------------------------------------------
          ------
           allow_system_table_mods                | off                                    | Allows modifications of the structure of system tables.
           application_name                       | psql                                   | Sets the application name to be reported in statistics and logs.
           archive_command                        | cd .                                   | Sets the shell command that will be called to archive a WAL file.
           archive_mode                           | on                                     | Allows archiving of WAL files using archive_command.
           archive_timeout                        | 30min                                  | Forces a switch to the next WAL file if a new file has not been started within N seconds.
           array_nulls                            | on                                     | Enable input of NULL elements in arrays.
          ....

      [**SHOW POOL NODES**](https://www.pgpool.net/docs/latest/en/html/sql-show-pool-nodes.html) 
      
      显示节点ID、主机名、端口、状态、权重（仅在使用负载平衡模式时才有意义）、角色、SELECT查询发给每个后端的计数，
      每个节点是否为负载均衡节点是否设置复制延迟（仅在流复制模式下）和上次状态更改时间。
      除此复制状态外，还显示了Pgpool-II 4.1或更高版本中的备用节点的状态和同步状态。 示例： 
  
          #psql -h 172.28.1.100 -p 6432 -U postgres postgres  -c "show pool_nodes" 
          
          Password for user postgres: 
           node_id | hostname | port | status | lb_weight |  role   | select_cnt | load_balance_node | replication_delay | replication_state | replication_sync_state | last_status_change  
          ---------+----------+------+--------+-----------+---------+------------+-------------------+-------------------+-------------------+------------------------+---------------------
           0       | node1  | 5432 | up     | 0.333333  | primary | 0          | false             | 0                 |                   |                        | 2019-11-25 08:47:53
           1       | node2  | 5432 | up     | 0.333333  | standby | 0          | false             | 0                 | streaming         | async                  | 2019-11-25 08:47:53
           2       | node3  | 5432 | up     | 0.333333  | standby | 0          | true              | 0                 | streaming         | async                  | 2019-11-25 08:47:53
          (3 rows)

   
### 六、 备份与恢复   
   
   高可用性群集提供了自动故障转移机制，并不涵盖所有灾难恢复方案。必须自己备份数据。

   推荐以下备份和还原工具：
   * [pgbackrest](https://github.com/pgbackrest/pgbackrest)
   * [pg_probackup](https://github.com/postgrespro/pg_probackup)
   * [wal-g](https://github.com/wal-g/wal-g) 

### 七、 参考资料
    
   * [PostgreSQL 官方中文文档](http://www.postgres.cn/docs/11/index.html)
   * [Pgpool 官方文档](https://www.pgpool.net/docs/latest/en/html/index.html)
   * [Pgpool 集群配置样例](https://www.pgpool.net/docs/latest/en/html/example-cluster.html)
   * [PostgreSQL集群（一主多从）简明手册](https://yq.aliyun.com/articles/582876)
   * [PostgreSQL on Linux 最佳实践](https://github.com/digoal/blog/blob/master/201611/20161121_01.md?spm=a2c4e.10696291.0.0.1d0c19a4qf8Bbr&file=20161121_01.md)






   
   



