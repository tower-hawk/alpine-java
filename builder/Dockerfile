FROM anapsix/alpine-java:8_jdk_unlimited

RUN  mkdir -p /build \
  && apk add --update --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ --no-cache \
       bash curl maven git ca-certificates openssl openssh

WORKDIR /build
