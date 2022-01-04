#!/bin/bash

git pull
git add *
git commit -m 'feat: update'
git push origin master
ssh mia "cd /data/code/articles && git pull && docker restart blog_docker-hexo-next_1"