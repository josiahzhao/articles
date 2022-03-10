---
title: 完美解决Chrome Cookie SameSite跨站限制
categories:
- 技术手册
tags:
- 前端
date: 2022-03-08 00:46:25
---

## 问题背景

在前后端分离的大趋势下，如果没有额外的配置部署方案，前端地址和后台API地址是不一样的。比如在本地开发调试阶段，前端地址为`http://localhost:3000`，后台API地址为`http://api.server.com/api/list`。
![](https://nginx.mostintelligentape.com/blogimg/202203/chrome/frontserver.png)

那么地址不一样会有什么问题呢？

如果你请求的后台API需要携带Cookie进行鉴权，那么在这种地址不一样的情况下，会因为浏览器的Cookie SameSite的跨站限制，导致Cookie不会被正确传递，进而导致请求API接口总是报错没有认证或者权限不足。
![](https://nginx.mostintelligentape.com/blogimg/202203/chrome/401.jpg)
## 什么是Cookie SameSite
![](https://nginx.mostintelligentape.com/blogimg/202203/chrome/cookie.jpg)

2016年开始，Chrome 51版本对Cookie新增了一个[SameSite属性](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie/SameSite)，用来防止CSRF攻击。

简单来说，在新版本的浏览器上，如果前端地址和请求的API地址的domain不一样的话，则会限制携带Cookie。
![](https://nginx.mostintelligentape.com/blogimg/202203/chrome/samesitecookie.png)

> 具体什么是CSRF攻击，跨站与跨域的区别，可以参见我另外的文章。

## 在Chrome上如何解决Cookie SameSite限制

```
如果想从原理上解决

1. 如果有nginx等反向代理工具，则可以通过配置将前端地址与API接口地址设置为同站即可解决（如果是本地开发，可以将一个与API同domain的host映射到本地调试地址，然后使用这个host进行调试开发即可）

2. 如果API接口是https的，也可以让API接口开发的同事将Cookie的SameSite设置为None即可取消同站限制。

但本文主要讲一下如何只利用Chrome解决Cookie SameSite限制。
```

### Chrome 91版本之前

2016年开始，Chrome从51版本之后添加了Cookie SameSite属性，但可以直接通过浏览器可视化配置解除限制。

直接访问[chrome://flags/](chrome://flags/)，找到`SameSite by default cookies`选项，将其设置为禁用(Disabled)，重启Chrome即可。
![](https://nginx.mostintelligentape.com/blogimg/202203/chrome/samesite-debugging-01.png)

### Chrome 91~93版本

2021年5月，官方出于安全考虑，从91版本开始取消了可视化关闭的方式，但是还可以通过命令行启动的方式进行关闭。

#### Windows

右键单击Chrome快捷方式，打开属性，在目标后添加--disable-features=SameSiteByDefaultCookies，点击确定，重启Chrome即可。

Chrome和Edge均可，如图。

![](https://nginx.mostintelligentape.com/blogimg/202203/chrome/chromesatesite.png)
![](https://nginx.mostintelligentape.com/blogimg/202203/chrome/edge.png)

#### Mac

Mac系统下可以通过命令行打开Chrome的方式来进行关闭。

* 注意前提须关闭浏览器。

```
开启Chrome命令：
open -a "Google Chrome" --args --disable-features=SameSiteByDefaultCookies

开启Chromium版Edge浏览器命令：
open -a "Microsoft Edge" --args --disable-features=SameSiteByDefaultCookies
```

### Chrome 94版本及以上

2021年9月，已经彻底移除可视化禁用和命令行禁用的方式，详见[官方的SameSite Updates](https://www.chromium.org/updates/same-site/)。

但是Chrome浏览器插件不受跨站跨域的限制，所以对于本地调试的场景，可以通过安装相关cookie透传的插件来解决。

> 如果需要解决所有用户的这个问题，则需要使用正规的方式解决：前后端地址不跨站，或者使用https+SameSite=None

[插件下载地址](https://nginx.mostintelligentape.com/blogimg/202203/chrome/cookie_plugin_v0.2.1.zip)

安装方式

1. 打开扩展程序[chrome://extensions/](chrome://extensions/)
2. 将下载的zip插件拖拽进去
![](https://nginx.mostintelligentape.com/blogimg/202203/chrome/plugin.png)

完成。


