FROM anapsix/alpine-java:8_server-jre_unlimited

COPY /app/ /app/

WORKDIR /app

RUN  echo "policy.url.3=file:/app/java/jolokia.policy" >> /opt/jdk/jre/lib/security/java.security \
  && wget -O /app/java/jolokia-jvm-agent.jar http://repo1.maven.org/maven2/org/jolokia/jolokia-jvm/1.5.0/jolokia-jvm-1.5.0-agent.jar

ENV PATH /app:/app/health:$PATH

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]

HEALTHCHECK --interval=30s --timeout=10s --retries=1 CMD ["/app/health/check.sh"]
