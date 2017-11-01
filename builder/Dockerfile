FROM anapsix/alpine-java:8_jdk_unlimited

RUN  mkdir -p /build \
  && apk add --update --no-cache \
       --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ \
       bash curl maven git ca-certificates openssl openssh

WORKDIR /build
