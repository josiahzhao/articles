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



参考文档

https://www.elastic.co/guide/en/elasticsearch/reference/7.10/elasticsearch-intro.html
https://www.elastic.co/guide/en/elasticsearch/reference/7.10/docker.html
