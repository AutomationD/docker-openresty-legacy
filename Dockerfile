################################################################################
# Base image
################################################################################

FROM debian:jessie

MAINTAINER Dmitry Kireev <dmitry@kireev.co>

################################################################################
# Build Openresty
################################################################################

###################################
# Set environment.
# 1.11.2.1-1.0.2j-1.11.33.4-rev-2
ENV PAGESPEED_VERSION="1.11.33.4"
ENV NGINX_VERSION="1.11.2.1"
ENV OPENSSL_VERSION="1.0.2j"

ENV \
  DEBIAN_FRONTEND=noninteractive \
  TERM=xterm-color
###################################


# Install base utils
RUN apt-get update && apt-get -y install \
  build-essential \
  curl \
  libreadline-dev \
  libncurses5-dev \
  libpcre3-dev \
  libgeoip-dev \
  zlib1g zlib1g-dev \
  vim \
  wget

# Use actual mirror instead of using httpredir which could break
RUN sed -i "s/httpredir.debian.org/`curl -s -D - http://httpredir.debian.org/demo/debian/ | awk '/^Link:/ { print $2 }' | sed -e 's@<http://\(.*\)/debian/>;@\1@g'`/" /etc/apt/sources.list


WORKDIR /root/

################################################################################
# Build instructions
################################################################################



### Download Tarballs ###
RUN echo "Downloading Tarballs" && \
  echo "Download PageSpeed" && \
  wget https://github.com/pagespeed/ngx_pagespeed/archive/v${PAGESPEED_VERSION}-beta.tar.gz -O /root/ngx_pagespeed-${PAGESPEED_VERSION}-beta.tar.gz && \
  tar --owner root --group root --no-same-owner -zxf ngx_pagespeed-${PAGESPEED_VERSION}-beta.tar.gz && \
  \
  echo "Download PageSpeed Optimization Library and extract it to nginx source dir" && \
  wget https://dl.google.com/dl/page-speed/psol/${PAGESPEED_VERSION}.tar.gz -O /root/ngx_pagespeed-${PAGESPEED_VERSION}-beta/psol-${PAGESPEED_VERSION}.tar.gz && \
  cd ngx_pagespeed-${PAGESPEED_VERSION}-beta && \
  tar --owner root --group root --no-same-owner -zxf psol-${PAGESPEED_VERSION}.tar.gz && \
  cd .. && \
  \
  echo "Download OpenSSL" && \
  wget https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz -O /root/openssl-${OPENSSL_VERSION}.tar.gz && \
  tar --owner root --group root --no-same-owner -zxf openssl-${OPENSSL_VERSION}.tar.gz && \
  \
  echo "Download Nginx" && \
  wget https://openresty.org/download/openresty-${NGINX_VERSION}.tar.gz -O /root/openresty-${NGINX_VERSION}.tar.gz && \
  tar --owner root --group root --no-same-owner -zxf openresty-${NGINX_VERSION}.tar.gz && \
  rm -f openresty-${NGINX_VERSION}.tar.gz


### Configure Nginx ###
RUN  echo "Configure Nginx" && \
  cd openresty-* && \
  ./configure \
  --sbin-path=/usr/sbin/nginx \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-client-body-temp-path=/var/lib/nginx/body \
  --http-fastcgi-temp-path=/var/lib/nginx/fastcgi \
  --http-log-path=/var/log/nginx/access.log \
  --http-proxy-temp-path=/var/lib/nginx/proxy \
  --http-scgi-temp-path=/var/lib/nginx/scgi \
  --http-uwsgi-temp-path=/var/lib/nginx/uwsgi \
  --lock-path=/var/lock/nginx.lock \
  --pid-path=/run/nginx.pid \
  --with-http_gzip_static_module \
  --with-http_stub_status_module \
  --with-http_ssl_module \
  --with-http_realip_module \
  --add-module=/root/ngx_pagespeed-${PAGESPEED_VERSION}-beta \
  --with-openssl=/root/openssl-${OPENSSL_VERSION} \
  --without-http_redis_module \
  --without-http_redis2_module \
  --without-http_xss_module \
  --without-http_rds_json_module \
  --without-http_rds_csv_module \
  --without-lua_resty_memcached \
  --without-lua_resty_mysql \
  --without-http_ssi_module \
  --without-http_autoindex_module \
  --without-http_uwsgi_module \
  --without-http_scgi_module && \
  \
  make && \
  make install && \
  make clean && \
  cd .. && \
  rm -rf openresty-*&& \
  ldconfig && \
  mkdir -p /var/lib/nginx /var/log/nginx


