#
# Customer Support Dockerfile
#
FROM tutum.co/zuppler/nginx:v3
MAINTAINER Iulian Costan <iulian.costan@zuppler.com>

CMD ["nginx"]

RUN mkdir /site

COPY dist/ /site/
COPY nginx.conf /etc/nginx/sites-enabled/
