FROM openjdk:14-alpine

COPY /app/ /app/

WORKDIR /app

RUN  apk add --no-cache \
       --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ \
       bash \
  && ln -s /opt/open* /opt/jdk \
  && echo "policy.url.3=file:/app/java/jolokia.policy" >> /opt/jdk/conf/security/java.security \
  && wget -O /app/java/jolokia-jvm-agent.jar https://repo1.maven.org/maven2/org/jolokia/jolokia-jvm/1.6.2/jolokia-jvm-1.6.2-agent.jar

ENV PATH /app:/app/health:$PATH

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]

HEALTHCHECK --interval=30s --timeout=10s --retries=1 CMD ["/app/health/check.sh"]
