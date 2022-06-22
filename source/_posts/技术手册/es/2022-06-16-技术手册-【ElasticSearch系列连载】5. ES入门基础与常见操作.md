---
title: 【ElasticSearch系列连载】5. ES入门基础与常见操作
categories:
- 技术手册
tags:
- 搜索
- ElasticSearch
date: 2022-06-03 00:46:25
---

![](https://nginx.mostintelligentape.com/blogimg/202205/es/es_logo.jpg)

# 【ElasticSearch系列连载】5. ES入门基础与常见操作

## 1 ES 数据格式-JSON

我们要存储的对象通常不是简单的键值对就能表示的，更多的情况是需要存储更加复杂的数据结构，比如数组、地址、嵌套结构等等。

如果我们使用传统的关系型数据库进行常见的行列存储的话，很多情况我们都需要将一些复杂的数据结构拍平，通过构造一个宽表来存储你的数据，或者需要将你的数据通过逗号分隔等形式拥挤的存储在一个字段中，每次从数据库写入和读取数据都需要进行序列化和反序列化的操作。

Elasticsearch是面向文档的，能够直接将复杂的对象进行存储，同时还能对复杂数据结构中的各个字段建立索引来让它能够被高效的检索到。在使用Elasticsearch的过程中，你建立索引的对象、搜索的对象、排序的对象以及筛选的对象都是文档，而不是行列格式的关系型数据，这是ES和其他关系型数据库最大的不同之一，以及为什么ES能够提供复杂的全文搜索。

![](https://nginx.mostintelligentape.com/blogimg/202206/es/sql-vs-nosql.jpg)

ElasticSearch使用JSON (JavaScript Object Notation) 作为文档的存储结构。目前绝大多数语言都能友好地支持JSON格式数据的转化与传输，也是大多数NoSQL类型数据库的存储标准。

一条注册用户信息的JSON文档如下：

```
{
    "email": "josiah@zhao.com",
    "name": "josiah",
    "info": {
        "bio": "工期短、质量好、成本低，这三项里面你最多只能同时做到两项", 
        "age": 25,
        "interests": [ "游泳", "钢琴" ]
    },
    "login_time": "2022/01/01" 
}
```

可以看到，虽然用户的原始信息有嵌套，数组和日期等相对复杂的结构，但是通过JSON的格式进行读写与展示就会容易很多。远比使用关系型数据库存储考虑如何将复杂结构拍平存储转化要简单的多。


## 2 索引的概念

在ElasticSearch中，每一个文档数据有一个"类型" (type) ，type是属于"索引" (index) 。他们的关系和关系型数据库相比如下：

关系型数据库 (如MySQL) ：数据库 (Database) => 数据表 (Table) => 行 (Row) => 列 (Column)
ElasticSearch：索引 (Index) => 类型 (Type) => 文档 (Document) => 属性 (Field)

> 注意，在V2.X中，一个Index的类型可以有多个，但是在V7.0以及之后的版本中Type被废弃了。一个Index中只有一个默认的Type，即 _doc。

和索引相关的几个概念。

**索引 (Index)**

如上文所述，名词的索引就是好比数据库，用来存储各个文档。

**对文档建索引 (Index)**

对一个文档建索引，就是将文档写入一个用来存储文档的索引，就好比是SQL的insert语句一样。

**倒排索引 (Inverted index)**

好比关系型数据库能够在字段上建立B-tree索引一样，来提升字段的查询效率。ElasticSearch和Lucene也使用一种数据库来加速文档字段的搜索，这个数据结构就叫做"倒排索引"。在默认的情况下，ElasticSearch会对文档中的所有字段都建立倒排索引。

## 3 用户数据存储场景实例

现在，我们要对一批用户数据"建索引"，需要满足如下的要求：

1. 允许每一条用户数据存储多个标签，数字和文本
2. 可以获取任意用户的完整信息
3. 允许结构化条件搜索，比如搜索年龄大于25岁的用户
4. 允许简单的全文搜索和复杂的短语搜索
5. 可以将匹配搜索词的内容进行高亮标记
6. 可以在数据上做统计分析

### 3.1 对文档建立索引

我们使用下面的三个curl请求对3个用户建立索引。

其中:

- "my_user_list" 就是索引的名称
- "_doc" 是索引的类型(如上文所述，7.0之后类型固定只能是_doc)
- "_doc" 之后的数字是文档的唯一标识，我们分别写入了id为1,2,3的三个用户文档数据
- "-d" 之后的JSON格式数据是录入的用户数据，分别是张三，李四和王五

我们可以看到，向ElasticSearch的索引中写入数据，不需要对索引做任何的初始化，ElasticSearch会自动感知数据的每一个字段，自动初始化索引的类型，自动建立倒排索引等等；除非特殊情况，不需要用户再做任何的初始化。

```
curl -H "Content-Type: application/json" -XPOST 'http://localhost:9200/my_user_list/_doc/1' -d '
{
    "name": "张三",
    "info": {
        "bio": "工期短、质量好、成本低，这三项里面你最多只能同时做到两项", 
        "age": 25,
        "interests": [ "游泳", "钢琴" ]
    },
    "login_time": "2022/01/01" 
}
'

curl -H "Content-Type: application/json" -XPOST 'http://localhost:9200/my_user_list/_doc/2' -d '
{
    "name": "李四",
    "info": {
        "bio": "钱多、事少、离家近，这三项里面你最多只能同时做到两项", 
        "age": 22,
        "interests": [ "篮球", "钢琴" ]
    },
    "login_time": "2022/02/01" 
}
'

curl -H "Content-Type: application/json" -XPOST 'http://localhost:9200/my_user_list/_doc/3' -d '
{
    "name": "王五",
    "info": {
        "bio": "提高效率、降低成本、满足定制，这三项里面你最多只能同时做到两项", 
        "age": 21,
        "interests": [ "游泳", "羽毛球" ]
    },
    "login_time": "2022/03/01" 
}
'

```

### 3.2 获取文档

现在，我们要获取其中一个用户的数据文档，我们只需要发起一个GET请求，将要获取的文档id传入即可，如下。

- "my_user_list" 就是索引的名称
- "_doc" 是索引的类型(如上文所述，7.0之后类型固定只能是_doc)
- "_doc" 之后的数字是文档的唯一标识，这里我们获取id为1的文档
- "pretty" 表示对返回的内容优化一下JSON格式方便阅读

```
curl -XGET 'http://localhost:9200/my_user_list/_doc/1?pretty'
```

返回如下，可以看到用户的详细信息在返回体的"_source"字段中。
```
{
  "_index" : "my_user_list",
  "_type" : "_doc",
  "_id" : "1",
  "_version" : 1,
  "_seq_no" : 0,
  "_primary_term" : 1,
  "found" : true,
  "_source" : {
    "name" : "张三",
    "info" : {
      "bio" : "工期短、质量好、成本低，这三项里面你最多只能同时做到两项",
      "age" : 25,
      "interests" : [
        "游泳",
        "钢琴"
      ]
    },
    "login_time" : "2022/01/01"
  }
}
```

### 3.3 简易搜索

只是按照id获取文档的详情还是太简单了，我们现在试着做一些简单的搜索动作。

**获取全部数据**

现在我们试着获取索引中的全部数据，可以执行如下GET语句，可以看到将3.2中id的部分换成了"_search"。

- "my_user_list" 就是索引的名称
- "_doc" 是索引的类型(如上文所述，7.0之后类型固定只能是_doc)
- "_search" 表示我们要通过搜索的方式获取一系列文档（没有传输条件等于获取所有文档）
- "pretty" 表示对返回的内容优化一下JSON格式方便阅读

```
curl -XGET 'http://localhost:9200/my_user_list/_doc/_search?pretty'
```

返回如下，可以看到耗时67ms，返回的信息列表在返回体的"hits"字段中，不仅返回了命中的数据id，还返回了每一条你可能需要的当时录入的数据详情。

```
{
  "took" : 67,
  "timed_out" : false,
  "_shards" : {...},
  "hits" : {
    "total" : {...},
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "my_user_list",
        "_type" : "_doc",
        "_id" : "1",
        "_score" : 1.0,
        "_source" : {
          "name" : "张三",
          "info" : {
            "bio" : "工期短、质量好、成本低，这三项里面你最多只能同时做到两项",
            "age" : 25,
            "interests" : [
              "游泳",
              "钢琴"
            ]
          },
          "login_time" : "2022/01/01"
        }
      },
      {
        "_index" : "my_user_list",
        "_type" : "_doc",
        "_id" : "2",
        "_score" : 1.0,
        "_source" : {
          "name" : "李四",
          "info" : {
            "bio" : "钱多、事少、离家近，这三项里面你最多只能同时做到两项",
            "age" : 22,
            "interests" : [
              "篮球",
              "钢琴"
            ]
          },
          "login_time" : "2022/02/01"
        }
      },
      {
        "_index" : "my_user_list",
        "_type" : "_doc",
        "_id" : "3",
        "_score" : 1.0,
        "_source" : {
          "name" : "王五",
          "info" : {
            "bio" : "提高效率、降低成本、满足定制，这三项里面你最多只能同时做到两项",
            "age" : 21,
            "interests" : [
              "游泳",
              "羽毛球"
            ]
          },
          "login_time" : "2022/03/01"
        }
      }
    ]
  }
}
```

**简单条件搜索:query-string**

接下来让我们搜索年龄是25的用户数据。由于这个搜索条件比较简单，我们可以直接通过在"_search"后添加参数"q"来传入搜索条件 (query-string搜索) 即可完成搜索，如下

- "my_user_list" 就是索引的名称
- "_doc" 是索引的类型(如上文所述，7.0之后类型固定只能是_doc)
- "_search" 表示我们要通过搜索的方式获取一系列文档（没有传输条件等于获取所有文档）
- "q" 标识搜索条件，使用key:value的格式，支持局部匹配
- "pretty" 表示对返回的内容优化一下JSON格式方便阅读

```
curl -XGET 'http://localhost:9200/my_user_list/_doc/_search?q=info.age:25&pretty'
```

返回如下，返回的信息列表在返回体的"hits"字段中。由于张三的年龄是25岁自然被命中返回。

```
{
  "took" : 8,
  "timed_out" : false,
  "_shards" : {...},
  "hits" : {
    "total" : {...},
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "my_user_list",
        "_type" : "_doc",
        "_id" : "1",
        "_score" : 1.0,
        "_source" : {
          "name" : "张三",
          "info" : {
            "bio" : "工期短、质量好、成本低，这三项里面你最多只能同时做到两项",
            "age" : 25,
            "interests" : [
              "游泳",
              "钢琴"
            ]
          },
          "login_time" : "2022/01/01"
        }
      }
    ]
  }
}
```

### 3.4 使用DSL搜索

在测试和简单的搜索场景下可以使用上面的query-string搜索方式，但是它的功能局限性也很明显，不能完成更加复杂搜索查询条件。

ElasticSearch提供了一个更加灵活、强大的搜索方式，叫做DSL(domain-specific language)搜索，通过DSL搜索我们可以构建更加复杂，更加健壮的搜索条件。

DSL搜索条件同样使用JSON格式构造，比如我们搜索姓名中有"张"字的用户数据，通过在JSON中构造query.match.name字段即可对文档数据中的name进行匹配查询。(具体语法会在后面的章节中介绍)

```
curl -H "Content-Type: application/json" -XGET 'http://localhost:9200/my_user_list/_doc/_search?pretty' -d '
{
    "query" : {
        "match" : {
            "name" : "张" 
        }
    } 
}
'
```

返回结果如下。

```
{
  "took" : 8,
  "timed_out" : false,
  "_shards" : {...},
  "hits" : {
    "total" : {...},
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "my_user_list",
        "_type" : "_doc",
        "_id" : "1",
        "_score" : 0.9808291,
        "_source" : {
          "name" : "张三",
          "info" : {
            "bio" : "工期短、质量好、成本低，这三项里面你最多只能同时做到两项",
            "age" : 25,
            "interests" : [
              "游泳",
              "钢琴"
            ]
          },
          "login_time" : "2022/01/01"
        }
      }
    ]
  }
}
```

### 3.5 更加复杂的搜索

下面我们通过DSL搜索进行一个更加复杂的查询。

- 年龄大于21岁
- bio中包含"离家近"

如下的DSL JSON通过info.age gt(great than) 21表示"年龄大于21岁"，通过"info.bio: 离家近"来表示"bio中包含离家近"。

> 更细节的DSL语法可以在官网中进行查询，也会在后面的章节中进行介绍

```
curl -H "Content-Type: application/json" -XGET 'http://localhost:9200/my_user_list/_doc/_search?pretty' -d '
{
  "query": { 
    "bool": { 
      "must": { "range": { "info.age": { "gt": 21 }}},
      "filter": { "match": { "info.bio": "离家近" }}
    }
  }
}
'
```

返回结果如下，22岁的李四。

```
{
  "took" : 8,
  "timed_out" : false,
  "_shards" : {...},
  "hits" : {
    "total" : {...},
    "max_score" : 1.0,
    "hits" : [
      {
        "_index" : "my_user_list",
        "_type" : "_doc",
        "_id" : "2",
        "_score" : 3.0731034,
        "_source" : {
          "name" : "李四",
          "info" : {
            "bio" : "钱多、事少、离家近，这三项里面你最多只能同时做到两项",
            "age" : 22,
            "interests" : [
              "篮球",
              "钢琴"
            ]
          },
          "login_time" : "2022/02/01"
        }
      }
    ]
  }
}
```

### 3.6 全文搜索

下面，我们来进行一次全文搜索，要知道全文搜索在关系型数据库中是很难做到的(like '%a%b%c%d%e')。

比如我们要搜索个人简介中关注"质量好、成本低"的人。

```
curl -H "Content-Type: application/json" -XGET 'http://localhost:9200/my_user_list/_doc/_search?pretty' -d '
{
    "query" : {
        "match" : {
            "info.bio" : "质量好、成本低" 
        }
    } 
}
'
```


可以看到返回结果如下，ElasticSearch按照文档数据与搜索内容的相关性进行排序，张三排在第一位，因为他的内容直接包含"质量好、成本低"。

但同时我们可以看到李四也命中返回，因为他的简介中有"成本"这两个字，但是由于并没有"质量好"等其他字样，所以李四的相关性打分要比张三低，排在后面。

```
{
  "took" : 8,
  "timed_out" : false,
  "_shards" : {...},
  "hits" : {
    "total" : {...},
    "max_score" : 1.0,
    "hits" : {
    "total" : {
      "value" : 2,
      "relation" : "eq"
    },
    "max_score" : 4.376054,
    "hits" : [
      {
        "_index" : "my_user_list",
        "_type" : "_doc",
        "_id" : "1",
        "_score" : 4.376054,
        "_source" : {
          "name" : "张三",
          "info" : {
            "bio" : "工期短、质量好、成本低，这三项里面你最多只能同时做到两项",
            "age" : 25,
            "interests" : [
              "游泳",
              "钢琴"
            ]
          },
          "login_time" : "2022/01/01"
        }
      },
      {
        "_index" : "my_user_list",
        "_type" : "_doc",
        "_id" : "3",
        "_score" : 1.3517995,
        "_source" : {
          "name" : "王五",
          "info" : {
            "bio" : "提高效率、降低成本、满足定制，这三项里面你最多只能同时做到两项",
            "age" : 21,
            "interests" : [
              "游泳",
              "羽毛球"
            ]
          },
          "login_time" : "2022/03/01"
        }
      }
    ]
  }
}
```

全文搜索是ElasticSearch的一个重要特性，上面"相关性"的是ElasticSearch的重要概念，同时也是和传统的关系型数据库十分不一样的地方。

### 3.7 Phrase搜索

上面的全文搜索固然很好，但是有时候你会希望找到文档数据中"精确匹配/包含"某些内容的条目，这时你就会需要Phrase搜索，如下，通过"match_phrase"来表示使用Phrase搜索模式。
```
curl -H "Content-Type: application/json" -XGET 'http://localhost:9200/my_user_list/_doc/_search?pretty' -d '
{
    "query" : {
        "match_phrase" : {
            "info.bio" : "质量好、成本低" 
        }
    } 
}
'
```

可以看到返回结果如下，info.bio中必须严格包含"质量好、成本低"的才会返回，所以结果只有张三，没有了李四。

```
{
  "took" : 8,
  "timed_out" : false,
  "_shards" : {...},
  "hits" : {
    "total" : {...},
    "max_score" : 1.0,
    "hits" : {
    "total" : {
      "value" : 2,
      "relation" : "eq"
    },
    "max_score" : 4.376054,
    "hits" : [
      {
        "_index" : "my_user_list",
        "_type" : "_doc",
        "_id" : "1",
        "_score" : 4.376054,
        "_source" : {
          "name" : "张三",
          "info" : {
            "bio" : "工期短、质量好、成本低，这三项里面你最多只能同时做到两项",
            "age" : 25,
            "interests" : [
              "游泳",
              "钢琴"
            ]
          },
          "login_time" : "2022/01/01"
        }
      }
    ]
  }
}
```

### 3.8 高亮搜索结果

为了满足很多应用需要对匹配到的数据进行高亮显示的需求，ElasticSearch支持在搜索结果中对命中的部分进行标记。

如下，在搜索时使用"highlight"并指定要高亮的内容如"info.bio"即可。

```
curl -H "Content-Type: application/json" -XGET 'http://localhost:9200/my_user_list/_doc/_search?pretty' -d '
{
    "query" : {
        "match_phrase" : {
            "info.bio" : "质量好、成本低" 
        }
    },
    "highlight": {
        "fields" : {
            "info.bio" : {}
        } 
    }
}
'
```

可以看到返回结果如下，highlight.info.bio中通过'em'标签对命中的内容进行了标记，这样应用侧就可以通过定位/替换'em'标签来完成高亮内容的渲染。

```
{
  "took" : 8,
  "timed_out" : false,
  "_shards" : {...},
  "hits" : {
    "total" : {...},
    "max_score" : 1.0,
    "hits" : {
    "total" : {
      "value" : 2,
      "relation" : "eq"
    },
    "max_score" : 4.376054,
    "hits" : [
      {
        "_index" : "my_user_list",
        "_type" : "_doc",
        "_id" : "1",
        "_score" : 4.376054,
        "_source" : {
          "name" : "张三",
          "info" : {
            "bio" : "工期短、质量好、成本低，这三项里面你最多只能同时做到两项",
            "age" : 25,
            "interests" : [
              "游泳",
              "钢琴"
            ]
          },
          "login_time" : "2022/01/01"
        },
        "highlight" : {
          "info.bio" : [
            "工期短、<em>质</em><em>量</em><em>好</em>、<em>成</em><em>本</em><em>低</em>，这三项里面你最多只能同时做到两项"
          ]
        }
      }
    ]
  }
}
```

### 3.9 分析与统计

类似于SQL的Group by方法，但是通过DSL的语法会更加强大也更加高效。

**统计所有用户的热门兴趣有什么**

如下，通过自定义一个"兴趣统计"的聚合查询条件，对info.interests进行统计。

```
curl -H "Content-Type: application/json" -XGET 'http://localhost:9200/my_user_list/_doc/_search?pretty' -d '
{
    "aggs" : {
        "兴趣统计" : {
            "terms" : { "field": "info.interests.keyword" }
        }
    }
}
'
```

可以在返回结果的"aggregations.兴趣统计.buckets"中可以看到"游泳"和"钢琴"是感兴趣人数最多的。

```
{
  "took" : 7,
  "timed_out" : false,
  "_shards" : {...},
  "hits" : {...},
  "aggregations" : {
    "兴趣统计" : {
      "doc_count_error_upper_bound" : 0,
      "sum_other_doc_count" : 0,
      "buckets" : [
        {
          "key" : "游泳",
          "doc_count" : 2
        },
        {
          "key" : "钢琴",
          "doc_count" : 2
        },
        {
          "key" : "篮球",
          "doc_count" : 1
        },
        {
          "key" : "羽毛球",
          "doc_count" : 1
        }
      ]
    }
  }
}
```

**符合搜索条件用户的热门兴趣有什么**

在DSL可以同时支持query条件和aggs统计条件，如下，对年龄大于21岁的用户进行热门兴趣统计。

```
curl -H "Content-Type: application/json" -XGET 'http://localhost:9200/my_user_list/_doc/_search?pretty' -d '
{
    "query": { 
        "range": { "info.age": { "gt": 21 }}
    },
    "aggs" : {
        "兴趣统计" : {
            "terms" : { "field": "info.interests.keyword" }
        }
    }
}
'
```

可以看到返回结果是针对21岁以上用户的兴趣统计。

```
{
  "took" : 7,
  "timed_out" : false,
  "_shards" : {...},
  "hits" : {...},
  "aggregations" : {
    "兴趣统计" : {
      "doc_count_error_upper_bound" : 0,
      "sum_other_doc_count" : 0,
      "buckets" : [
        {
          "key" : "钢琴",
          "doc_count" : 2
        },
        {
          "key" : "游泳",
          "doc_count" : 1
        },
        {
          "key" : "篮球",
          "doc_count" : 1
        }
      ]
    }
  }
}
```

**多级嵌套统计**


在DSL可以支持aggs的嵌套统计，比如统计各类兴趣下各个用户的平均年龄，如下，第一个"aggs.兴趣统计"又嵌套了一个"aggs.年龄统计"。

```
curl -H "Content-Type: application/json" -XGET 'http://localhost:9200/my_user_list/_doc/_search?pretty' -d '
{
    "aggs" : {
        "兴趣统计" : {
            "terms" : { "field": "info.interests.keyword" },
             "aggs" : {
                "年龄统计" : {
                    "avg" : { "field": "info.age" }
                }
            }
        }
    }
}
'
```

可以看到返回结果在每一个兴趣下都新增了一个"年龄统计"，如喜欢游泳的人有2个，平均年龄是23岁。

```
{
  "took" : 7,
  "timed_out" : false,
  "_shards" : {...},
  "hits" : {...},
  "aggregations" : {
    "兴趣统计" : {
      "doc_count_error_upper_bound" : 0,
      "sum_other_doc_count" : 0,
      "buckets" : [
        {
          "key" : "游泳",
          "doc_count" : 2,
          "年龄统计" : {
            "value" : 23.0
          }
        },
        {
          "key" : "钢琴",
          "doc_count" : 2,
          "年龄统计" : {
            "value" : 23.5
          }
        },
        {
          "key" : "篮球",
          "doc_count" : 1,
          "年龄统计" : {
            "value" : 22.0
          }
        },
        {
          "key" : "羽毛球",
          "doc_count" : 1,
          "年龄统计" : {
            "value" : 21.0
          }
        }
      ]
    }
  }
}
```

### 3.10 删除索引

通过DELETE方法，对指定索引进行如下请求即可删除索引。

```
curl -XDELETE 'http://localhost:9200/my_user_list'
```

## 4 分布式

ElasticSearch天然带有分布式的属性，上述的所有操作方式在单节点和集群上都是一样的，ElasticSearch隐藏并自动完成了大部分分布式中需要的功能和细节，比如：

- 将数据进行分片，然后将分片进行分区存储到不同的节点上
- 将数据分片均匀的分布到不同的节点上，确保索引的建立和搜索的负载是均衡的
- 对分片进行多份冗余存储，避免因为某一个节点物理损坏而导致丢失数据
- 将你的搜索请求自动路由到存有你的目标文档数据的节点
- 通过无感知的形式能够在线对节点数量进行横向扩容

## 5 总结

本文通过一些说明和案例，对ElasticSearch的基础功能做了一个快速的概览，可以看到和传统数据库相比，ElasticSearch在搜索方式、功能、性能上都有很好的提升和补充。

关于细节的语法和其他集群、管理、维护相关的内容会在后续的章节中陆续进行介绍。
