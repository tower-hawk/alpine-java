FROM anapsix/alpine-java:8_server-jre_unlimited

COPY /app/ /app/

WORKDIR /app

RUN echo "policy.url.3=file:/app/java/java.policy" >> /opt/jdk/jre/lib/security/java.security

ENV PATH /app:/app/health:$PATH

ENTRYPOINT ["/bin/bash", "entrypoint.sh"]

HEALTHCHECK --interval=3m --timeout=10s --retries=1 CMD ["/app/health/check.sh"]

