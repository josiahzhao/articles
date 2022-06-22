---
title: 【ElasticSearch系列连载】3. 如何安装符合生产环境要求的ES集群
categories:
- 技术手册
tags:
- 搜索
- ElasticSearch
date: 2022-06-02 00:46:25
---

![](https://nginx.mostintelligentape.com/blogimg/202205/es/es_logo.jpg)

# 【ElasticSearch系列连载】3. 如何安装符合生产环境要求的ES集群

通过本文，将会循序渐进地了解到ES的若干部署方案，以及相关的基础操作与配置。

上一节介绍的一键安装方式，可以快速启动一个ES环境用于学习，调试和测试，但是还不足以作为生产环境，比如：

* 不支持集群模式
* 无法轻易对配置文件进行调整与维护
* 后续写入的搜索数据会随着容器删除而删除，没有在本地进行持久化存储
* 9200端口暴露，不需要认证即可访问存在安全隐患
* 没有可视化管理界面（kibana）

本文将会依次解决持久化存储（包括数据文件与配置文件）、可视化管理（kibana）和加密（ES+Kibana）的问题，各个章节解决的问题如下：

| 章节 | 单节点 | 集群 | 数据持久化 | kibana | 加密 |
| ---| ---| ---| ---| ---| ---|
| 3.1 | ✅ |  |  |  |  |
| 3.2 | ✅ |  | ✅ |  |  |
| 3.3 | ✅ |  | ✅ | ✅ |  |
| 3.4 | ✅ |  | ✅ | ✅ | ✅ |
| 4.1 |  | ✅ | ✅ | |  |
| 4.2 |  | ✅ | ✅ | ✅ |  |
| 4.3 |  | ✅ | ✅ | ✅ |  ✅|


## 1 版本与环境选型
### 1.1 ES版本选择考量

**本系列使用ES 7.10版本作为部署选型**

截止到目前撰稿日期，已经推出了ES 8.0版本，有众多的改动和新特性，考虑到：

* 目前ES 7.11 之后开源协议进行了变更，不再适合企业大规模商用
* 在未来一段时间，市面上目前6.x 和 7.x 仍然是主流

所以本系列使用ES 7.10的版本作为讲解样例，一方面是：

* 7.x是先进且主流的版本，具有所需要的绝大部分的功能特性
* 另一方面7.10是Apache 2.0开源协议授权的最新也是最后一个ES版本了，我们可以基于这个版本进行更自由的二次开发、改造与发布

![](https://nginx.mostintelligentape.com/blogimg/202205/es/es_license_update.jpg)

### 1.2 安装方式选型

**本系列使用Docker进行ES环境的搭建**，希望使用尽可能**简单，干净，通用**的方式来进行ES环境的搭建与安装 => Docker安装。

[Docker](https://www.docker.com/)可以安装在任何的平台（x86，ARM，Windows，Linux，MacOS）上，通过Docker的沙箱机制，我们可以免除所有ES对操作系统和环境的依赖干扰，快速建立一个干净的ES环境。

参考官方的[如何安装Docker](https://www.docker.com/get-started/)选择对应的平台即可进行安装，本文不再赘述。

![](https://nginx.mostintelligentape.com/blogimg/202205/es/install/docker_download.png)

### 1.3 Docker镜像选型

#### x86环境

对于大部分x86环境的情况，可以使用

* [elasticsearch/7.10.1](
https://hub.docker.com/layers/elasticsearch/library/elasticsearch/7.10.1/images/sha256-e9a1fe65f68b2d2b9583287d1190f67f23af08582eac4d2a8dc342e4219c7306?context=explore)镜像
* [kibana/7.10.1](https://hub.docker.com/layers/kibana/library/kibana/7.10.1/images/sha256-1731793b7f3e453c65ebaf92ec0b55f4029310ba8abae9e04753a4680dd8210b?context=explore)镜像

#### ARM环境

对于ARM环境的情况（如树莓派、国产机型、苹果M1等），可以使用

* [arm64v8/elasticsearch/7.10.1](
https://hub.docker.com/layers/elasticsearch/arm64v8/elasticsearch/7.10.1/images/sha256-a7b465c42780a7e92892878ea30941b427d691698a100454dee7296140cdb889?context=explore)镜像
* [arm64v8/kibana/7.13.1](
https://hub.docker.com/layers/kibana/arm64v8/kibana/7.13.1/images/sha256-b365ceadf9e0be71ff75b339c3df027dae6ad8519e6dabfe9e0ef3d1ccbf2e5f?context=explore)镜像

> 对于下文命令中使用镜像名称的地方会统一使用*elasticsearch/7.10.1*，如果是ARM用户的话请自行改成对应镜像名称

## 2 ES部署相关基础概念说明

### 2.1 端口号

ES需要占用两个端口号

* 9200-外部通讯使用端口：它是http协议的RESTful接口，我们通过浏览器、CURL与ES打交道进行数据的增删改查等操作大都是使用这个端口，默认是9200。
* 9300-节点之间通讯使用端口：它是tcp通讯端口，集群间和TCPclient都走的它，默认是9300。

kibana需要占用一个端口号，默认是5601，可以通过浏览器直接访问。

### 2.2 存储与配置

ES需要三个存储目录，如果使用上述的elasticsearch/7.10.1镜像，默认在：

* 数据存储目录：/usr/share/elasticsearch/data
* 日志文件目录：/usr/share/elasticsearch/logs
* 配置文件目录：/usr/share/elasticsearch/config

kibana需要配置文件（kibana本身是一个无状态服务，不需要额外的数据信息），如果使用上述的kibana/7.10.1镜像，默认在：

* 配置文件路径：/usr/share/kibana/config/kibana.yml 

但是由于kibana需要的配置相对简单，本文使用环境变量的方式在运行时配置，不再单独配置yml配置文件，可以根据个人需要进行单独配置。

### 2.3 节点名称、端口号、目录规划方案

在部署集群时，哪台机器部署，每台机器部署几个ES节点，相关数据目录放在哪等问题因人而异，但都需要进行提前规划，本文规划如下：

* 机器与服务：一共两台机器A和B，准备部署3个ES节点和1个Kibana服务
* 节点部署划分：机器A部署ES节点0和ES节点1，机器B部署ES节点2和Kibana服务
* 端口号划分：为了防止节点端口号冲突（因为有多个多个节点部署在一台机器的情况），我们约定
  * 0号节点叫做es00，端口号使用9200 & 9300
  * 1号节点叫做es01，端口号使用9201 & 9301
  * ……
  * 99号节点叫做es99，端口号使用9299 & 9399
* 存储划分：为了防止节点存储路径号冲突（因为有多个多个节点部署在一台机器的情况），我们约定
  * 0号节点叫做es00，数据存储在/data/elasticsearch/es00/{data,logs,config}中
  * 1号节点叫做es01，数据存储在/data/elasticsearch/es01/{data,logs,config}中
  * ……
  * 99号节点叫做es99，数据存储在/data/elasticsearch/es99/{data,logs,config}中

具体方案如下：

| 部署内容 | 部署名称 | 端口号 | 机器 | 数据目录 |
| ---| ---| ---| ---| ---|
| ES节点0 | es00 | 9200 9300 | 机器A | 数据存储目录：/data/elasticsearch/es00/data 日志文件目录：/data/elasticsearch/es00/logs<br>配置文件目录：/data/elasticsearch/es00/config |
| ES节点1 | es01 | 9201<br>9301 | 机器A | 数据存储目录：/data/elasticsearch/es01/data<br>日志文件目录：/data/elasticsearch/es01/logs<br>配置文件目录：/data/elasticsearch/es01/config |
| ES节点2 | es02 | 9202<br>9302 | 机器B | 数据存储目录：/data/elasticsearch/es02/data<br>日志文件目录：/data/elasticsearch/es02/logs<br>配置文件目录：/data/elasticsearch/es02/config |
| Kibana服务 | kib | 5601 | 机器B | 不需要 |

## 3 单节点部署
### 3.1 裸ES简易部署

直接执行如下命令即可。

```
docker run \
--name es00 \
-d -p 9200:9200 -p 9300:9300 \
-e "discovery.type=single-node" \
elasticsearch:7.10.1
```
直接访问本机的9200端口，比如 http://127.0.0.1:9200，如果能够看到如下内容说明启动正常。

![](https://nginx.mostintelligentape.com/blogimg/202205/es/install/es_start.png)

### 3.2 ES持久化存储与配置部署

上文中提到，ES需要三个存储目录，在容器中的：

* 数据存储目录：/usr/share/elasticsearch/data
* 日志文件目录：/usr/share/elasticsearch/logs
* 配置文件目录：/usr/share/elasticsearch/config

所以我们需要将这三个目录在宿主机中进行建立，并将其映射到上述容器内的三个目录中去。

在这里，我们使用/data/elasticsearch/es00/{data,logs,config}三个目录。

#### 第一步：建立目录

```
mkdir -p /data/elasticsearch/es00/{data,logs,config}
chmod 777 -R /data/elasticsearch/es00
```
#### 第二步：拷贝配置文件

在/data/elasticsearch/es00/config中我们需要3个配置文件，在es启动时会需要使用，分别是jvm，log和es参数的配置文件。

这边已经将相关文件准备好，可以直接使用下面的命令进行下载。

```
curl https://nginx.mostintelligentape.com/blogimg/elasticsearch/single/jvm.options > /data/elasticsearch/es00/config/jvm.options

curl https://nginx.mostintelligentape.com/blogimg/elasticsearch/single/elasticsearch.yml > /data/elasticsearch/es00/config/elasticsearch.yml

curl https://nginx.mostintelligentape.com/blogimg/elasticsearch/single/log4j2.properties > /data/elasticsearch/es00/config/log4j2.properties
```
#### 第三步：启动ES

```
docker run \
--name es00 \
-d -p 9200:9200 -p 9300:9300 \
-v /data/elasticsearch/es00/data:/usr/share/elasticsearch/data \
-v /data/elasticsearch/es00/logs:/usr/share/elasticsearch/logs \
-v /data/elasticsearch/es00/config:/usr/share/elasticsearch/config \
elasticsearch:7.10.1
```
> 如果之前es00重名了，可以先执行**docker rm -f es00**，然后再运行上面的启动命令。

直接访问本机的9200端口，比如 http://127.0.0.1:9200，如果能够看到如下内容说明启动正常。

![](https://nginx.mostintelligentape.com/blogimg/202205/es/install/es_start.png)

#### 第四步：验证持久化效果

1 通过API写入数据
```
curl -X PUT http://127.0.0.1:9200/myindex/doc/1 -d'{"name":"josiah","age":18}' --header "Content-Type: application/json"
```
2 通过该API能够查询数据
```
curl http://127.0.0.1:9200/myindex/doc/1?pretty
```
能够看到刚才写入的数据能够
```
{
  "_index" : "myindex",
  "_type" : "doc",
  "_id" : "1",
  "_version" : 1,
  "_seq_no" : 0,
  "_primary_term" : 1,
  "found" : true,
  "_source" : {
    "name" : "josiah",
    "age" : 18
  }
}
```
3 验证本地目录有数据存储文件

执行如下命令，可以看到内部已有数据文件

```
du -sh /data/elasticsearch/es00/data/
```
4 删除容器，重新启动

```
docker rm -f es00

docker run \
--name es00 \
-d -p 9200:9200 -p 9300:9300 \
-v /data/elasticsearch/es00/data:/usr/share/elasticsearch/data \
-v /data/elasticsearch/es00/logs:/usr/share/elasticsearch/logs \
-v /data/elasticsearch/es00/config:/usr/share/elasticsearch/config \
elasticsearch:7.10.1
```
5 之前写入的数据仍然存在
```
curl http://127.0.0.1:9200/myindex/doc/1?pretty

{
  "_index" : "myindex",
  "_type" : "doc",
  "_id" : "1",
  "_version" : 1,
  "_seq_no" : 0,
  "_primary_term" : 1,
  "found" : true,
  "_source" : {
    "name" : "josiah",
    "age" : 18
  }
}
```
### 3.3 配套Kibana部署

执行如下命令，将下面的http://192.168.51.1:9200换成对应部署的es的地址即可。

> 不可以使用127.0.0.1或者localhost，需要使用宿主机的网卡ip

```
docker run \
--name kib \
-d -p 5601:5601 \
-e "ELASTICSEARCH_HOSTS=http://192.168.51.1:9200" \
kibana:7.10.1
```
启动后访问IP:5601即可。

![](https://nginx.mostintelligentape.com/blogimg/202206/es/kibana.jpg)


### 3.4 启用加密

#### 第一步：进入容器

在确保es00运行的情况下，执行如下命令进入容器内部（以便使用es相关脚本进行加密证书的生成与配置）
```
docker exec -it es00 bash
```
如图

![](https://nginx.mostintelligentape.com/blogimg/202206/es/enter_es00.jpg)

#### 第二步：制作p12

1 创建本地CA

仍然在容器内，执行如下语句，第一次要求输入的文件名称直接回车（图中第1个箭头），第二次要求输入的证书密码输入一个不小于6位的密码（图中第2个箭头），记录好，完成后当前目录会多一个"elastic-stack-ca.p12"文件（图中第3个箭头）。

```
./bin/elasticsearch-certutil ca
```
![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_create_ca.jpg)

2 生成数字证书

仍然在容器内，执行如下命令，第一次要求输入时输入上面创建本地CA时输入的密码（图中第1个箭头），第二次要求输入的文件名称直接回车（图中第2个箭头），第三次要求输入时也可以输入上面创建本地CA时输入的密码（图中第3个箭头），完成后当前目录会多一个"elastic-certificates.p12"文件（图中第4个箭头），然后将其移动到./config/certificates中去（也是我们做了持久化的目录），最后对其的权限进行修改确保ES能够正常使用它（图中第5个箭头）。

```
./bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12

mkdir ./config/certificates
mv ./elastic-certificates.p12 ./config/certificates/
chmod 777 ./config/certificates/elastic-certificates.p12
```
![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_create_cert.jpg)


#### 第三步：修改配置使用证书

仍然在容器内，通过执行如下的vi命令编辑elasticsearch.yml文件

```
vi ./config/elasticsearch.yml
```
添加如下内容，告知ES使用刚才创建的证书文件，如图：

```
http.cors.enabled: true
http.cors.allow-origin: "*"
http.cors.allow-headers: Authorization,X-Requested-With,Content-Type,Content-Length

xpack.security.enabled: true
xpack.security.authc.accept_default_password: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /usr/share/elasticsearch/config/certificates/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /usr/share/elasticsearch/config/certificates/elastic-certificates.p12
```
![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_add_cert_config.jpg)


最后执行如下两行语句，如果需要输入密码使用第二步的密码即可

```
./bin/elasticsearch-keystore add xpack.security.transport.ssl.keystore.secure_password
./bin/elasticsearch-keystore add xpack.security.transport.ssl.truststore.secure_password
```
#### 第四步：重启ES

接着第三步，如果还在容器内，执行exit退出容器，然后执行**docker restart es00**重启es服务。

![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_restart.jpg)


#### 第五步：配置ES访问密码

在确保es00运行的情况下，执行如下命令进入容器内部
```
docker exec -it es00 bash
```
如图

![](https://nginx.mostintelligentape.com/blogimg/202206/es/enter_es00.jpg)

然后执行如下语句，先输入**y**进行确认，然后会要求定义ES相关各类账户的密码，输入**不少于6位的，不是纯数字的**若干平台（elastic，apm，kibana，logstash，beats，remote_monitor）的密码，如图。

```
./bin/elasticsearch-setup-passwords  interactive
```
![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_set_pwd.jpg)


然后浏览器访问http://IP地址:9200，即会弹出密码框，用户名输入elastc，密码输入刚才定义的密码，即可进入，如图。

![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_has_pwd.jpg)


注：如果想要修改密码的话，可以使用下面的方法，注意--user后面跟上目前elastic用户的账号密码
* 修改elastic账号密码为a123456:
```
curl --user elastic:123456  -XPOST --header "Content-Type: application/json" -d '{"password": "a123456"}' http://192.168.1.1:9200/_security/user/elastic/_password
```
* 修改kibana账号密码为123456a:
```
curl --user elastic:a123456  -XPOST --header "Content-Type: application/json" -d '{"password": "123456a"}' http://192.168.1.1:9200/_security/user/kibana/_password
```
#### 第六步：配置Kibana访问密码

此时ES已经有了密码,如果再访问我们上面部署的Kibana会发现无法访问了，我们也需要告诉Kibana对应ES的密码才行，如图。

![](https://nginx.mostintelligentape.com/blogimg/202206/es/kibana_need_pwd.jpg)

> 如果之前已经启动了Kibana，可以先执行**docker rm -f kib**进行删除

启动命令加入ES的账号密码信息即可，如下，将ELASTICSEARCH_HOSTS，ELASTICSEARCH_USERNAME，ELASTICSEARCH_PASSWORD配置成你的ES的地址、账号和密码即可。

```
docker run \
--name kib \
-d -p 5601:5601 \
-e "ELASTICSEARCH_HOSTS=http://192.168.51.1:9200" \
-e "ELASTICSEARCH_USERNAME=elastic" \
-e "ELASTICSEARCH_PASSWORD=a123456" \
kibana:7.10.1
```
如图。
![](https://nginx.mostintelligentape.com/blogimg/202206/es/kibana_login.jpg)


## 4 集群部署

本文部署集群的规划如下：

* 机器与服务：一共两台机器A和B，准备部署3个ES节点和1个Kibana服务
* 节点部署划分：机器A部署ES节点0和ES节点1，机器B部署ES节点2和Kibana服务
* 端口号划分：为了防止节点端口号冲突（因为有多个多个节点部署在一台机器的情况），我们约定
  * 0号节点叫做es00，端口号使用9200 & 9300
  * 1号节点叫做es01，端口号使用9201 & 9301
  * ……
  * 99号节点叫做es99，端口号使用9299 & 9399
* 存储划分：为了防止节点存储路径号冲突（因为有多个多个节点部署在一台机器的情况），我们约定
  * 0号节点叫做es00，数据存储在/data/elasticsearch/es00/{data,logs,config}中
  * 1号节点叫做es01，数据存储在/data/elasticsearch/es01/{data,logs,config}中
  * ……
  * 99号节点叫做es99，数据存储在/data/elasticsearch/es99/{data,logs,config}中

具体方案如下：

| 部署内容 | 部署名称 | 端口号 | 机器 | 数据目录 |
| ---| ---| ---| ---| ---|
| ES节点0 | es00 | 9200 9300 | 机器A | 数据存储目录：/data/elasticsearch/es00/data 日志文件目录：/data/elasticsearch/es00/logs<br>配置文件目录：/data/elasticsearch/es00/config |
| ES节点1 | es01 | 9201<br>9301 | 机器A | 数据存储目录：/data/elasticsearch/es01/data<br>日志文件目录：/data/elasticsearch/es01/logs<br>配置文件目录：/data/elasticsearch/es01/config |
| ES节点2 | es02 | 9202<br>9302 | 机器B | 数据存储目录：/data/elasticsearch/es02/data<br>日志文件目录：/data/elasticsearch/es02/logs<br>配置文件目录：/data/elasticsearch/es02/config |
| Kibana服务 | kib | 5601 | 机器B | 不需要 |

### 4.1 ES集群持久化存储与配置部署

每一个节点的部署方式是一样的，这边针对es00节点的部署进行展开描述，其他两个节点的部署直接粘贴命令。

#### ES节点0（es00）

**第一步：建立目录**

```
mkdir -p /data/elasticsearch/es00/{data,logs,config}
chmod 777 -R /data/elasticsearch/es00
```
**第二步：拷贝配置文件**

在/data/elasticsearch/es00/config中我们需要3个配置文件，在es启动时会需要使用，分别是jvm，log和es参数的配置文件。

这边已经将相关文件准备好，可以直接使用下面的命令进行下载。

```
curl https://nginx.mostintelligentape.com/blogimg/elasticsearch/init_config/es00/jvm.options > /data/elasticsearch/es00/config/jvm.options

curl https://nginx.mostintelligentape.com/blogimg/elasticsearch/init_config/es00/elasticsearch.yml > /data/elasticsearch/es00/config/elasticsearch.yml

curl https://nginx.mostintelligentape.com/blogimg/elasticsearch/init_config/es00/log4j2.properties > /data/elasticsearch/es00/config/log4j2.properties
```
其中**elasticsearch.yml**补充说明，如下图：

* node.name: 文本三个节点分别是es00, es01, es02
* network.publish_host: 文本三个节点分别是es00, es01, es02
* http.port: 文本三个节点分别是9200, 9201, 9202
* transport.port: 文本三个节点分别是9300, 9301, 9302
* cluster.name: 固定my-es-cluster
* network.host: 固定0.0.0.0
* discovery.seed_hosts: 所有节点的名称和通信端口，本文固定是["es00:9300", "es01:9301", "es02:9302"]
* cluster.initial_master_nodes: 所有节点的名称，本文固定是["es00", "es01", "es02"]

![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_yml.jpg)

**第三步：启动**

执行如下命令即可启动，如果之前es00重名了，可以先执行**docker rm -f es00**，然后再运行下面的启动命令（**需要根据实际情况修改--add-host**）。

```
docker run \
--name es00 \
-d -p 9200:9200 -p 9300:9300 \
-v /data/elasticsearch/es00/data:/usr/share/elasticsearch/data \
-v /data/elasticsearch/es00/logs:/usr/share/elasticsearch/logs \
-v /data/elasticsearch/es00/config:/usr/share/elasticsearch/config \
--add-host es00:192.168.51.2 --add-host es01:192.168.51.2 --add-host es02:192.168.51.1 \
elasticsearch:7.10.1
```
上面的命令参数补充说明：

* -d: 后台运行
* -p: 端口映射
* -v: 持久化存储目录映射
* --add-host * 3: 记录所有节点名称和IP地址的映射关系，加入到容器的hosts文件中

**第四步：验证**

直接浏览器访问IP:9200即可验证启动成功

#### ES节点1（es01）

**第一步：建立目录**

```
mkdir -p /data/elasticsearch/es01/{data,logs,config}
chmod 777 -R /data/elasticsearch/es01
```
**第二步：拷贝配置文件**

```
curl https://nginx.mostintelligentape.com/blogimg/elasticsearch/init_config/es01/jvm.options > /data/elasticsearch/es01/config/jvm.options

curl https://nginx.mostintelligentape.com/blogimg/elasticsearch/init_config/es01/elasticsearch.yml > /data/elasticsearch/es01/config/elasticsearch.yml

curl https://nginx.mostintelligentape.com/blogimg/elasticsearch/init_config/es01/log4j2.properties > /data/elasticsearch/es01/config/log4j2.properties
```
**第三步：启动**

执行如下命令即可启动，如果之前es01重名了，可以先执行**docker rm -f es01**，然后再运行下面的启动命令（**需要根据实际情况修改--add-host**）。

```
docker run \
--name es01 \
-d -p 9201:9201 -p 9301:9301 \
-v /data/elasticsearch/es01/data:/usr/share/elasticsearch/data \
-v /data/elasticsearch/es01/logs:/usr/share/elasticsearch/logs \
-v /data/elasticsearch/es01/config:/usr/share/elasticsearch/config \
--add-host es00:192.168.51.2 --add-host es01:192.168.51.2 --add-host es02:192.168.51.1 \
elasticsearch:7.10.1
```
**第四步：验证**

直接浏览器访问IP:9201即可验证启动成功

#### ES节点2（es02）

**第一步：建立目录**

```
mkdir -p /data/elasticsearch/es02/{data,logs,config}
chmod 777 -R /data/elasticsearch/es02
```
**第二步：拷贝配置文件**

```
curl https://nginx.mostintelligentape.com/blogimg/elasticsearch/init_config/es02/jvm.options > /data/elasticsearch/es02/config/jvm.options

curl https://nginx.mostintelligentape.com/blogimg/elasticsearch/init_config/es02/elasticsearch.yml > /data/elasticsearch/es02/config/elasticsearch.yml

curl https://nginx.mostintelligentape.com/blogimg/elasticsearch/init_config/es02/log4j2.properties > /data/elasticsearch/es02/config/log4j2.properties
```
**第三步：启动**

执行如下命令即可启动，如果之前es02重名了，可以先执行**docker rm -f es02**，然后再运行下面的启动命令（**需要根据实际情况修改--add-host**）。

```
docker run \
--name es02 \
-d -p 9202:9202 -p 9302:9302 \
-v /data/elasticsearch/es02/data:/usr/share/elasticsearch/data \
-v /data/elasticsearch/es02/logs:/usr/share/elasticsearch/logs \
-v /data/elasticsearch/es02/config:/usr/share/elasticsearch/config \
--add-host es00:192.168.51.2 --add-host es01:192.168.51.2 --add-host es02:192.168.51.1 \
elasticsearch:7.10.1
```
**第四步：验证**

直接浏览器访问IP:9202即可验证启动成功

#### 最终验证

访问三个节点任意一个的**http://IP:端口/_cat/nodes**能够看到集群信息。

![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_cluster_success.jpg)

### 4.2 配套Kibana部署

执行如下命令，将下面的http://192.168.51.1:9200换成对应部署的es的地址与端口即可。

> 不可以使用127.0.0.1或者localhost，需要使用宿主机的网卡ip

```
docker run \
--name kib \
-d -p 5601:5601 \
-e "ELASTICSEARCH_HOSTS=http://192.168.51.1:9200" \
kibana:7.10.1
```
启动后访问IP:5601即可。

![](https://nginx.mostintelligentape.com/blogimg/202206/es/kibana.jpg)

### 4.3 启用加密

#### 第一步：进入容器

在确保es00运行的情况下，执行如下命令进入容器内部（以便使用es相关脚本进行加密证书的生成与配置）
```
docker exec -it es00 bash
```
如图

![](https://nginx.mostintelligentape.com/blogimg/202206/es/enter_es00.jpg)

#### 第二步：制作p12

1 创建本地CA

仍然在容器内，执行如下语句，第一次要求输入的文件名称直接回车（图中第1个箭头），第二次要求输入的证书密码输入一个不小于6位的密码（图中第2个箭头），记录好，完成后当前目录会多一个"elastic-stack-ca.p12"文件（图中第3个箭头）。

```
./bin/elasticsearch-certutil ca
```
![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_create_ca.jpg)

2 生成数字证书

仍然在容器内，执行如下命令，第一次要求输入时输入上面创建本地CA时输入的密码（图中第1个箭头），第二次要求输入的文件名称直接回车（图中第2个箭头），第三次要求输入时也可以输入上面创建本地CA时输入的密码（图中第3个箭头），完成后当前目录会多一个"elastic-certificates.p12"文件（图中第4个箭头），然后将其移动到./config/certificates中去（也是我们做了持久化的目录），最后对其的权限进行修改确保ES能够正常使用它（图中第5个箭头）。

```
./bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12

mkdir ./config/certificates
mv ./elastic-certificates.p12 ./config/certificates/
chmod 777 ./config/certificates/elastic-certificates.p12
```
![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_create_cert.jpg)

3 将数字证书拷贝到其他节点上
   
将上面的elastic-certificates.p12文件拷贝到**所有节点**上：

* 文件在容器内的：/usr/share/elasticsearch/config/certificates/ 目录下
* 文件也在宿主机的：/data/elasticsearch/es01/config/certificates/ 目录下
* 拷贝到其他节点（对于本文还剩es01和es02）的同样目录

#### 第三步：修改配置使用证书

依次进入所有节点的容器，通过执行如下的vi命令编辑elasticsearch.yml文件

```
vi ./config/elasticsearch.yml
```
添加如下内容，告知ES使用刚才创建的证书文件，如图：

```
http.cors.enabled: true
http.cors.allow-origin: "*"
http.cors.allow-headers: Authorization,X-Requested-With,Content-Type,Content-Length

xpack.security.enabled: true
xpack.security.authc.accept_default_password: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: /usr/share/elasticsearch/config/certificates/elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: /usr/share/elasticsearch/config/certificates/elastic-certificates.p12
```
![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_add_cert_config.jpg)


最后执行如下两行语句，如果需要输入密码使用第二步的密码即可

```
./bin/elasticsearch-keystore add xpack.security.transport.ssl.keystore.secure_password
./bin/elasticsearch-keystore add xpack.security.transport.ssl.truststore.secure_password
```
#### 第四步：重启ES

对所有机器的所有es节点进行重启。

```
docker restart es00
docker restart es01
docker restart es02
```
![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_restart.jpg)


#### 第五步：配置ES访问密码

在确保es服务运行的情况下，找**任意一个节点**执行如下命令进入容器（密码设置会自动同步到各个节点上，所以不用重复执行）
```
docker exec -it es00 bash
```
如图

![](https://nginx.mostintelligentape.com/blogimg/202206/es/enter_es00.jpg)

然后执行如下语句，先输入**y**进行确认，然后会要求定义ES相关各类账户的密码，输入**不少于6位的，不是纯数字的**若干平台（elastic，apm，kibana，logstash，beats，remote_monitor）的密码，如图。

```
./bin/elasticsearch-setup-passwords  interactive
```
![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_set_pwd.jpg)


然后浏览器访问http://IP地址:9200，即会弹出密码框，用户名输入elastc，密码输入刚才定义的密码，即可进入，如图。

![](https://nginx.mostintelligentape.com/blogimg/202206/es/es_has_pwd.jpg)


注：如果想要修改密码的话，可以使用下面的方法，注意--user后面跟上目前elastic用户的账号密码
* 修改elastic账号密码为a123456:
```
curl --user elastic:123456  -XPOST --header "Content-Type: application/json" -d '{"password": "a123456"}' http://192.168.1.1:9200/_security/user/elastic/_password
```
* 修改kibana账号密码为123456a:
```
curl --user elastic:a123456  -XPOST --header "Content-Type: application/json" -d '{"password": "123456a"}' http://192.168.1.1:9200/_security/user/kibana/_password
```
#### 第六步：配置Kibana访问密码

此时ES已经有了密码,如果再访问我们上面部署的Kibana会发现无法访问了，我们也需要告诉Kibana对应ES的密码才行，如图。

![](https://nginx.mostintelligentape.com/blogimg/202206/es/kibana_need_pwd.jpg)

> 如果之前已经启动了Kibana，可以先执行**docker rm -f kib**进行删除

启动命令加入ES的账号密码信息即可，如下，将ELASTICSEARCH_HOSTS，ELASTICSEARCH_USERNAME，ELASTICSEARCH_PASSWORD配置成你的ES的地址、账号和密码即可。

```
docker run \
--name kib \
-d -p 5601:5601 \
-e "ELASTICSEARCH_HOSTS=http://192.168.51.1:9200" \
-e "ELASTICSEARCH_USERNAME=elastic" \
-e "ELASTICSEARCH_PASSWORD=a123456" \
kibana:7.10.1
```
如图。
![](https://nginx.mostintelligentape.com/blogimg/202206/es/kibana_login.jpg)


## 5 可能问题

### 5.1 vm.max_map_count太低

如果报错vm.max_map_count太低，需要将其设置为至少262144，[参考链接](https://www.elastic.co/guide/en/elasticsearch/reference/7.10/docker.html#_set_vm_max_map_count_to_at_least_262144)

```
sysctl -w vm.max_map_count=262144
```
### 5.2 ES性能不足

在上文的jvm.options中，关于堆内存的设置默认是1GB，对于大部分生产环境来说是不够的，这一块可以根据实际情况进行调整



## 参考文档
https://github.com/elastic/kibana/issues/55031
https://www.elastic.co/guide/en/elasticsearch/reference/current/certutil.html
https://blog.csdn.net/hhf799954772/article/details/115870012
https://blog.csdn.net/yabingshi_tech/article/details/109535035
https://www.elastic.co/guide/en/kibana/7.17/docker.html
https://www.elastic.co/guide/en/elasticsearch/reference/7.10/elasticsearch-intro.html
https://www.elastic.co/guide/en/elasticsearch/reference/7.10/docker.html
https://stackoverflow.com/questions/69415530/start-up-elastic-search-on-multiple-hosts-using-docker
https://discuss.elastic.co/t/handshake-failed-unexpected-remote-node/117082
https://docs.docker.com/engine/reference/run/#network-settings
https://stackoverflow.com/questions/46627979/what-is-the-default-user-and-password-for-elasticsearch
https://baijiahao.baidu.com/s?id=1703600336205273370&wfr=spider&for=pc
https://www.elastic.co/guide/en/elasticsearch/reference/7.10/settings.html
https://stackoverflow.com/questions/66433674/what-does-discovery-seed-hosts-and-cluster-initial-master-nodes-mean-in-es
https://stackoverflow.com/questions/14379575/configure-port-number-of-elasticsearch

