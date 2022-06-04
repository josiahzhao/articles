---
title: 【ElasticSearch系列连载】3. 如何安装符合生产环境要求的ES集群
categories:
- 技术手册
tags:
- 搜索
- ElasticSearch
date: 2022-05-22 00:46:25
---

上一节介绍的一键安装方式，可以快速启动一个ES环境用于学习，调试和测试，但是还不足以作为生产环境，比如：

- 不支持集群模式
- 无法轻易对配置文件进行调整与维护
- 后续写入的搜索数据会随着容器删除而删除，没有在本地进行持久化存储
- 9200端口暴露，不需要认证即可访问

如果想一步到位了解更详细的ES部署方式用于生产环境，可以继续阅读这一节。

所以，这一节将介绍如何部署一个具有**加密**且具有数据+配置文件**持久化存储**的ES**集群**（2个节点）


多机部署
docker rm -f learnes01
docker run --name learnes01 --net learnesnetwork -d -p 9200:9200 -p 9300:9300 --add-host learnes01:192.168.51.53 --add-host learnes02:192.168.51.121 -e "node.name=learnes01" -e "network.publish_host=192.168.51.53" -e "cluster.name=learnes-cluster" -e "discovery.seed_hosts=learnes02" -e "cluster.initial_master_nodes=learnes01,learnes02" elasticsearch:7.10.1

discovery.zen.ping.unicast.hosts: ["k8snode16","None","k8snode15","k8smaster01"]
#
# Prevent the "split brain" by configuring the majority of nodes (total number of master-eligible nodes / 2 + 1):
#
discovery.zen.minimum_master_nodes: 3


docker network create esnet


docker rm -f es02
docker run \
--name es02 \
--net esnet \
-d -p 9200:9200 -p 9300:9300 \
-v /data/elasticsearch/es02/data:/usr/share/elasticsearch/data \
-v /data/elasticsearch/es02/logs:/usr/share/elasticsearch/logs \
-v /data/elasticsearch/es02/config:/usr/share/elasticsearch/config \
--add-host es01:192.168.51.53 --add-host es02:192.168.51.121 \
-e "TAKE_FILE_OWNERSHIP=1" \
-e "node.name=es02" \
-e "network.publish_host=192.168.51.121" \
-e "cluster.name=learnes-cluster" \
-e "discovery.seed_hosts=es01" \
-e "cluster.initial_master_nodes=es01,es02" \
elasticsearch:7.10.1

单机部署
docker rm -f learnes01
docker rm -f learnes02

docker run --name learnes01 --net learnesnetwork -d -p 9200:9200 -p 9300:9300 -e "node.name=learnes01" -e "cluster.name=learnes-cluster" -e "discovery.seed_hosts=learnes02" -e "cluster.initial_master_nodes=learnes01,learnes02" elasticsearch:7.10.1


docker run --name learnes02 --net learnesnetwork -d -e "node.name=learnes02" -e "cluster.name=learnes-cluster" -e "discovery.seed_hosts=learnes01" -e "cluster.initial_master_nodes=learnes01,learnes02" elasticsearch:7.10.1

开启认证





参考文档

https://www.elastic.co/guide/en/elasticsearch/reference/7.10/elasticsearch-intro.html
https://www.elastic.co/guide/en/elasticsearch/reference/7.10/docker.html
https://stackoverflow.com/questions/69415530/start-up-elastic-search-on-multiple-hosts-using-docker
https://discuss.elastic.co/t/handshake-failed-unexpected-remote-node/117082
https://docs.docker.com/engine/reference/run/#network-settings
