---
title: 【ElasticSearch系列连载】1. ES版本与开源简介
categories:
- 技术手册
tags:
- 搜索
- ElasticSearch
date: 2022-05-10 00:46:25
---

![](https://nginx.mostintelligentape.com/blogimg/202205/es/es_logo.jpg)

## 诞生背景

现有的技术在数据的结构化和存储方面已经做的很好了，但是在硬盘上的原始数据并不能充分发挥数据的价值，尤其是当你需要基于这些数据做一些实时的决策时，就更容易出现使用上的困难。

ES是一个 分布式，可扩展，实时 的搜索与数据分析引擎，能够有效解决在全文搜索 或者 结构化数据的实时分析问题。

不只是大型企业，如Wikipedia，Guardian，Stack Overflow，GitHub在使用。它也可以在你的笔记本上运行，或者扩展到几百台服务器，服务数PB的数据。

ES带来了革命，但是ES并没有使用或者创造革命性的技术：全文搜索，数据分析和分布式数据存储都是已经有的技术概念。
ES是通过将这三个独立的部分进行了巧妙地融合成了一个独立的、实时的应用程序，这才是ES带来的革命。

目前，大多数数据库在从数据中提取可操作的知识方面都出奇地无能。虽然他们可以通过时间戳进行筛选或者提取特定的字段，但是它们不能轻松的进行全文搜索，进行同义词搜索以及对数据进行相关性排序。

更重要的是，面对具有一定规模的数据，如果不对数据做大量的离线预处理、批处理，大多数数据库是无法提供实时服务的。

## ES简介

ES是在Apache Lucene之上开发的。

Apache Lucene是一个开源，先进，性能强劲，功能强大的搜索引擎。但它只是一个库，不仅需要使用Java代码才能使用，而且还需要理解Lucene内部逻辑和结构，整体用起来十分复杂。

虽然ES也是JAVA编写的，内部也是使用了Lucene来进行索引和搜索，但是通过十分科学的设计将Lucene的复杂性屏蔽在了ES强大且简单的RESTful API之后。

当然，ES不只是Lucene和全文搜索，它还是：

1. 支持文档分布式存储的全字段实时搜索引擎
2. 支持实时数据分析的分布式引擎
3. 支持数百节点和PB级别的结构化与非结构化数据

同时，支持RESTful API，支持命令行，支持多种语言的SDK，使用Apache 2开源协议(已经经过多次调整)。

关于ES诞生的小故事：

```
在谈及当年接触 Lucene 并开发 Elasticsearch 的初衷的时候， Shay Banon 认为自己参与 Lucene 完全是一种偶然，当年他还是一个待业工程师，跟随自己的新婚妻子来到伦敦，妻子想在伦敦学习做一名厨师，而自己则想为妻子开发一个方便搜索菜谱的应用，所以才接触到 Lucene。直接使用 Lucene 构建搜索有很多问题，包含大量重复性的工作，所以 Shay Banon 便在 Lucene 的基础上不断地进行抽象，让 Java 程序嵌入搜索变得更容易，经过一段时间的打磨便诞生了他的第一个开源作品“Compass”，中文即“指南针”的意思。之后，他找到了一份面对高性能分布式开发环境的新工作，在工作中他渐渐发现越来越需要一个易用的、高性能、实时、分布式搜索服务，于是决定重写 Compass，将它从一个库打造成了一个独立的 server，并创建了开源项目。
第一个公开版本出现在 2010 年 2 月，在那之后 Elasticsearch 已经成为 Github 上最受欢迎的项目之一。
```

## 关于ES的各个版本

| 版本 | 发布日期 | 内容 |
| --- | --- | --- |
| 1.0.0 | 2014年2月12日 | 聚合分析、API、备份恢复等特性 |
| 2.0.0 | 2015年10月28日 | 存储压缩可配置、API语法升级等特性 |
| 5.0.0 | 2016年10月26日 | 使用Lucene 6.x、SDK、API升级、Text/Keyword、存储与性能大幅提升 |
| 6.0.0 | 2017年11月14日 | 排序、滚动升级、数据可靠、性能提升等特性 |
| 7.0.0 | 2019年4月10日 | 使用Lucene 8.x、Security免费、Zen2、稳定性等特性 |
| 8.0.0 | 2022年2月10日 | Security默认启用、NLP支持、KNN、API升级、存储与性能提升|

## ES开源协议历史

### 开源背景
Apache 2.0开源协议是最开放的协议之一：你可以修改源码将其整合到自己的产品中，并且选择不再继续开源。不像GPL等开源协议，它们会有禁止[Copyleft](https://zh.wikipedia.org/wiki/Copyleft)的声明：如果使用了开源软件，你的软件也必须开源。

由于Apache 2.0协议的开放性，可能你自己开发的开源软件会被你的对手使用反过来和你进行竞争。

![](https://nginx.mostintelligentape.com/blogimg/202205/es/open_source.jpg)

### 冲突产生

这个事情就发生在了ES上，亚马逊于 2015 年基于 Elasticsearch 推出自己的服务，将其称为 Amazon Elasticsearch Service。随后双方发生了激烈的争议。

### 协议变更

在2021年1月，Elastic 在官网发文称将对Elasticsearch和Kibana在许可证方面进行了重大的更改，决定将 Elasticsearch 和 Kibana 的开源协议由 Apache 2.0 变更为 [SSPL 与 Elastic License](https://www.elastic.co/cn/blog/elastic-license-v2)，主要原因为了阻止云厂商的「白嫖」。

之后，Amazon表示完全不能接受，ES随后发布了对应声明[Amazon：完全不能接受 — 为什么我们必须变更 Elastic 许可协议](https://www.elastic.co/cn/blog/why-license-change-aws)

### 达成和解

就在最近的2022年2月17日，[软件公司 Elastic 和亚马逊就一起商标侵权诉讼达成了和解](https://www.elastic.co/cn/blog/elastic-and-amazon-reach-agreement-on-trademark-infringement-lawsuit)。亚马逊开始从网站的各个页面以及其服务和相关项目名称中删除“Elasticsearch”一词，并由 Elastic 销售的 Elastic Cloud 取而代之。这是 Elastic 的一次重大胜利，该公司曾多次与亚马逊发生冲突。

“现在 AWS 和 AWS Marketplace 上唯一的 Elasticsearch 服务是 Elastic Cloud，我们认为这是消除市场混乱的重要一步。只有一个 Elasticsearch，而且它只来自 Elastic。”Elastic 创始人兼首席技术官 Shay Banon 说。亚马逊之前还将 Amazon Elasticsearch Service 重命名为 Amazon OpenSearch Service。从现在开始，如果你在 AWS、Azure、Google Cloud 中看到“Elasticsearch”，就会知道它肯定来自 Elastic。

### ES开源状态总结

![](https://nginx.mostintelligentape.com/blogimg/202205/es/es_license_update.jpg)

从即将发布的Elastic 7.11版本开始，Elastic 将把 Apache 2.0 授权的 Elasticsearch 和 Kibana代码转为SSPL和Elastic License的双重授权，让用户可以选择使用哪个授权。SSPL是MongoDB创建的一个源码可用的许可证，以体现开源的原则，同时提供保护，防止公有云提供商将开源产品作为服务提供而不回馈。SSPL允许自由和不受限制的使用和修改，但如果你把产品作为服务提供给别人，你也必须在SSPL下公开发布任何修改以及管理层的源代码。

> 关注持续更新：下一节 - 【ElasticSearch系列连载】2. 如何本地安装与调试ES