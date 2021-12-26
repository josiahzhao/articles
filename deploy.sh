#!/bin/bash

ssh mia "cd /data/code/articles && git pull && docker restart blog_docker-hexo-next_1"