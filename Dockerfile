FROM alpine:latest as pocobuilder

RUN apk update && \
    apk add --no-cache cmake g++ make openssl openssl-dev curl && \
    mkdir -p /tmp/po && curl -sSL https://github.com/pocoproject/poco/archive/poco-1.7.9-release.tar.gz | tar xz -C /tmp/po --strip-components=1 

RUN apk update && apk add libcap-dev && \
    cd /tmp/po && \
    cmake -DENABLE_DATA_MYSQL=OFF -DENABLE_DATA_ODBC=OFF -DENABLE_MONGODB=OFF -DENABLE_ZIP=OFF -DENABLE_PAGECOMPILER=OFF -DENABLE_PAGECOMPILER_FILE2PAGE=OFF && \
    make -j $(getconf _NPROCESSORS_ONLN) && make install

RUN apk update && apk add --no-cache alpine-sdk autoconf automake libtool

RUN echo "@testing http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

RUN mkdir -p /tmp/lo &&  curl -sSL https://github.com/LibreOffice/online/archive/2.1.5-5.tar.gz | tar xz -C /tmp/lo --strip-components=1

RUN apk update && apk add libpng-dev \
			  libcap-dev \
			  cppunit-dev \
 			  libreofficekit \
			  openssl-dev 
#			  poco-dev@testing 

COPY Admin.patch /tmp/lo/wsd
COPY IoUtil.patch /tmp/lo/common
COPY Seccomp.patch /tmp/lo/common
COPY SigUtil.patch /tmp/lo/common
COPY Util.patch /tmp/lo/common

RUN cd /tmp/lo/wsd &&  patch < Admin.patch && \
    cd /tmp/lo/common && patch < IoUtil.patch && \
    patch < Seccomp.patch && \
    patch < SigUtil.patch && \
    patch < Util.patch

RUN apk update && apk add libexecinfo-dev pcre-dev

#RUN apk update && apk add openssl openssl-dev

RUN set -xe && \
    cd /tmp/lo && \
    libtoolize && \
    aclocal && \
    autoreconf --install && \
    automake --add-missing && \
    autoreconf && \
    autoheader && \ 
#    ./configure --with-poco-includes=/tmp/mypoco/ --with-poco-libs=/tmp/poco/lib/  && \
    ./configure --enable-silent-rules --enable-debug --with-lo-path=/usr/lib/libreoffice/ --with-lokit-path=/usr/include/LibreOfficeKit/ && \
    make 

