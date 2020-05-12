FROM openjdk:14-alpine as source

RUN jlink \
  --output /opt/jre \
  --compress=2 \
  --no-header-files \
  --no-man-pages \
  --module-path /opt/openjdk-*/jmods/ \
  --add-modules \
 java.base\
,java.compiler\
,java.datatransfer\
,java.instrument\
,java.logging\
,java.management\
,java.management.rmi\
,java.naming\
,java.net.http\
,java.prefs\
,java.rmi\
,java.scripting\
,java.se\
,java.security.jgss\
,java.security.sasl\
,java.sql\
,java.sql.rowset\
,java.transaction.xa\
,java.xml\
,java.xml.crypto\
,jdk.compiler\
,jdk.crypto.cryptoki\
,jdk.crypto.ec\
,jdk.hotspot.agent\
,jdk.httpserver\
,jdk.internal.jvmstat\
,jdk.internal.opt\
,jdk.internal.vm.compiler\
,jdk.internal.vm.compiler.management\
,jdk.management\
,jdk.management.agent\
,jdk.naming.dns\
,jdk.naming.rmi\
,jdk.net\
,jdk.scripting.nashorn\
,jdk.security.auth\
,jdk.xml.dom\
,jdk.zipfs


FROM frolvlad/alpine-glibc

COPY --from=source /opt/jre /opt/jre

COPY /app/ /app/

WORKDIR /app

RUN  apk add --no-cache \
       --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ \
       bash \
  && echo "policy.url.3=file:/app/java/jolokia.policy" >> /opt/jre/conf/security/java.security \
  && wget -O /app/java/jolokia-jvm-agent.jar https://repo1.maven.org/maven2/org/jolokia/jolokia-jvm/1.6.2/jolokia-jvm-1.6.2-agent.jar

ENV PATH /app:/app/health:/opt/jre/bin:$PATH

ENTRYPOINT ["entrypoint.sh"]

HEALTHCHECK --interval=30s --timeout=10s --retries=1 CMD ["/app/health/check.sh"]
