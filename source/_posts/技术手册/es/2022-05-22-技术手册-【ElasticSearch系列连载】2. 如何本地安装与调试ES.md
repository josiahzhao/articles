---
title: 【ElasticSearch系列连载】2. 如何本地安装与调试ES
categories:
- 技术手册
tags:
- 搜索
- ElasticSearch
date: 2022-05-22 00:46:25
---

理解ES最简单的方式就是实际上手使用一把，所以这一节主要介绍如何在本地搭建一套可以随心所欲操作、使用的ES环境。

## 1 安装选型说明

### 1.1 ES版本选择考量

**本系列使用ES 7.10版本作为讲解样例**

截止到目前撰稿日期，已经推出了ES 8.0版本，有众多的改动和新特性，考虑到：
- 目前ES 7.11 之后开源协议进行了变更，不再适合企业大规模商用
- 在未来一段时间，市面上目前6.x 和 7.x 仍然是主流

所以本系列使用ES 7.10的版本作为讲解样例，一方面是：
- 7.x是先进且主流的版本，具有所需要的绝大部分的功能特性
- 另一方面7.10是Apache 2.0开源协议授权的最新也是最后一个ES版本了，我们可以基于这个版本进行更自由的二次开发、改造与发布

![](https://nginx.mostintelligentape.com/blogimg/202205/es/es_license_update.jpg)

### 1.2 安装方式选型

**本系列使用Docker进行ES学习环境的搭建**

如果是大规模的搭建部署，企业内通常有专职的团队或者成员来负责，如果是出于学习目的，笔者希望使用尽可能**简单，干净，通用**的方式来进行ES环境的搭建与安装 => Docker安装。

[Docker](https://www.docker.com/)可以安装在任何的平台（x86，ARM，Windows，Linux，MacOS）上，通过Docker的沙箱机制，我们可以免除所有ES对操作系统和环境的依赖干扰，快速建立一个干净的ES环境。

参考官方的[如何安装Docker](https://www.docker.com/get-started/)选择对应的平台即可进行安装，本文不再赘述。

![](https://nginx.mostintelligentape.com/blogimg/202205/es/install/docker_download.png)

### 1.3 Docker镜像选型

#### x86环境

对于大部分x86环境的情况，可以使用[elasticsearch/7.10.1](
https://hub.docker.com/layers/elasticsearch/library/elasticsearch/7.10.1/images/sha256-e9a1fe65f68b2d2b9583287d1190f67f23af08582eac4d2a8dc342e4219c7306?context=explore)镜像

#### ARM环境

对于ARM环境的情况（如树莓派、国产机型、苹果M1等），可以使用 [arm64v8/elasticsearch/7.10.1](
https://hub.docker.com/layers/elasticsearch/arm64v8/elasticsearch/7.10.1/images/sha256-a7b465c42780a7e92892878ea30941b427d691698a100454dee7296140cdb889?context=explore)镜像

> 对于下文命令中使用镜像名称的地方会统一使用*elasticsearch/7.10.1*，如果是ARM用户的话请自行改成*arm64v8/elasticsearch/7.10.1*

## 2 ES本地一键安装与启动

正文开始。

### 2.1 首次准备

首次安装时，先使用docker创建一个供测试的虚拟网络，后续搭建的其他es节点或者组件（如kibana）都使用这个虚拟网络

```
docker network create learnesnetwork
```

### 2.2 启动

启动命令如下

```
docker run --name learnes --net learnesnetwork -d -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:7.10.1
```

命令说明

- --name learnes，表示使用docker启动的这个服务名称叫做learnes，后续可以用learnes进行这个服务的查看日志，重启，删除等操作
- --net learnesnetwork，表示使用刚才创建的虚拟网络
- -d 表示后台运行
- -p 9200:9200 -p 9300:9300，表示将容器内的9200端口和9300端口分别映射到本机的9200和9300端口
- -e "discovery.type=single-node"， -e 表示设置环境变量，其中discovery.type=single-node表示告诉ES服务使用单节点模式

命令执行成功效果如下，会输出一串数字，是这个容器的id

```
josiahzhao@josiahzhaos-Mac-mini articles % docker run --name learnes -d  -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:7.10.1
4d3fef6014b0979d5dd41664b635ab1f32505cce0658cd496aef89a348760bfd
```

### 2.3 服务验证

直接访问本机的9200端口，比如 http://127.0.0.1:9200，如果能够看到如下内容说明启动正常。

![](https://nginx.mostintelligentape.com/blogimg/202205/es/install/es_start.png)

或者使用curl命令行*curl -i http://127.0.0.1:9200*，如下

```
[root@bogon ~]# curl -i http://127.0.0.1:9200
HTTP/1.1 200 OK
content-type: application/json; charset=UTF-8
content-length: 542
{
  "name" : "8b04a38d07bb",
  "cluster_name" : "docker-cluster",
  "cluster_uuid" : "knBercKuT0myJI9A7T2U5w",
  "version" : {
    "number" : "7.10.1",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "1c34507e66d7db1211f66f3513706fdf548736aa",
    "build_date" : "2020-12-05T01:00:33.671820Z",
    "build_snapshot" : false,
    "lucene_version" : "8.7.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

### 2.4 问题定位常用命令

1. 查看ES服务是否在运行

执行*docker ps*，看是否有刚才的learnes容器

```
josiahzhao@josiahzhaos-Mac-mini articles % docker ps
CONTAINER ID   IMAGE                          COMMAND                  CREATED         STATUS         PORTS                                            NAMES
4d3fef6014b0   arm64v8/elasticsearch:7.10.1   "/tini -- /usr/local…"   8 minutes ago   Up 8 minutes   0.0.0.0:9200->9200/tcp, 0.0.0.0:9300->9300/tcp   learnes
```

2. 停止es服务

执行*docker stop learnes*

```
docker stop learnes
```

3. 重启es服务

执行*docker restart learnes*

```
docker restart learnes
```

4. 查看es日志

执行*docker logs learnes*

```
josiahzhao@josiahzhaos-Mac-mini articles % docker logs learnes
{"type": "server", "timestamp": "2022-05-22T10:14:55,085Z", "level": "INFO", "......
```

5. 内存设置问题排查与解决

如果没有启动成功，通过查看日志看到如下报错

```
[1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
```

直接按照这个的[链接](https://www.elastic.co/guide/en/elasticsearch/reference/7.10/docker.html#_set_vm_max_map_count_to_at_least_262144)操作配置即可。

> 关注持续更新：下一节 - 【ElasticSearch系列连载】3. 如何搭建符合生产环境要求的ES集群