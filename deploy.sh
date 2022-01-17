#!/bin/bash

git pull
git add *
git commit -m 'feat: update'
git push origin master
ssh mia "docker cp /data/code/articles/utils.js docker restart blog_docker-hexo-next_1:/hexo/website/themes/next/source/js/"
ssh mia "cd /data/code/articles && git pull && docker restart blog_docker-hexo-next_1"