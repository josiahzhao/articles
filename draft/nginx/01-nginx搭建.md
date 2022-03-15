
## 介绍

    本章，分别介绍在不同的环境下如何搭建和启动nginx服务。

    nginx版本选择撰写时的最新版本: 1.21.6。

    推荐使用Docker方式安装，能够屏蔽不同环境下的差异，也不容易对现有文件系统和软件系统产生干扰和影响。
    

## Docker安装

### 准备条件

如何安装docker和了解docker的基础使用，请参考：
- [官方文档](https://docs.docker.com/desktop/)
- [中文菜鸟教程](https://www.runoob.com/docker/docker-tutorial.html)

### 安装与启动
如果只是需要部署启动一个nginx，只需要执行下面一行命令即可。
```
docker run -it -p 8000:80 nginx:1.21.6
```

参数说明
- -it: 表示以交互的形式启动，可以看到nginx的具体运行情况；如果需要后台稳定运行，可以不使用该参数，换用-d等参数。
- -p 8000:80:表示将本机的8000端口映射到容器内的80端口，由于nginx启动时默认在80端口提供服务，通过这个-p参数后，通过本机的8000端口就等价于访问容器内的80端口。

### 验证

直接浏览器访问[http://127.0.0.1:8000](http://127.0.0.1:8000/)即可看到成功启动的效果。

![docker_install.png]()



## Windows安装

### 安装

访问[nginx官方下载页面](https://nginx.org/en/download.html)

选择[Windows-1.21.6版本](https://nginx.org/download/nginx-1.21.6.zip)


## Mac安装

## CentOS安装

## Ubuntu安装