#!/bin/bash
# This script is meant to be sourced by entrypoint.sh scripts or be referenced directly

thisDir=$(cd $(dirname ${BASH_SOURCE[0]}) && pwd)
appDir=${thisDir}

if [ ${#BASH_SOURCE[@]} -ge 1 ]; then
  appDir=$(cd $(dirname ${BASH_SOURCE[1]}) && pwd)
fi

if [ "x${appDir}" == "x/app" ] && [ -d "/app/$APP_NAME" ]; then
  appDir="/app/$APP_NAME"
fi

function debug () {
  [ "x${DEBUG}" == "xtrue" ] && echo $@
}

DEFAULT_JMX_PORT=${DEFAULT_JMX_PORT:-18080}

export APP_NAME="${APP_NAME:-app}"
export APP_HOME="${APP_HOME:-${appDir}}"
[ "x${LOG_DIR}" = "x" ] && export LOG_DIR=${APP_HOME}/logs

function app_settings() {
export APP_OPTS="-Dlog.dir=${LOG_DIR} \
${APP_OPTS}"
debug "APP_OPTS=${APP_OPTS}"
}

function jmx_settings() {
export JMX_PORT="${JMX_PORT:-$DEFAULT_JMX_PORT}"

JMX_HOSTNAME=${JMX_HOSTNAME:-$(hostname -f)}

export JMX_OPTS="-Dcom.sun.management.jmxremote \
-Dcom.sun.management.jmxremote.authenticate=false \
-Dcom.sun.management.jmxremote.ssl=false \
-Djava.rmi.server.hostname=${JMX_HOSTNAME} \
-Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT} \
-Dcom.sun.management.jmxremote.port=${JMX_PORT} \
${JMX_OPTS}"
debug JMX_OPTS="${JMX_OPTS}"
}

function heap_settings() {
MIN_HEAP=-Xms${MIN_HEAP_SIZE:-64m}

MAX_HEAP=-Xmx${MAX_HEAP_SIZE:-256m}

JAVA_HEAP_OPTS="${MIN_HEAP} ${MAX_HEAP}"

if [ "x${HEAP_OPTS}" == "x" ]; then
  export HEAP_OPTS="${JAVA_HEAP_OPTS}"
else
  export HEAP_OPTS
fi
debug HEAP_OPTS="${HEAP_OPTS}"
}

function gc_log_settings() {
[ "x${LOGGC}" != "xfalse" ] && [ "x${GC_LOG_OPTS}" == "x" ] && \
export GC_LOG_OPTS="-Xloggc:${LOG_DIR}/${SERVICE_NAME}-gc.log \
-verbose:gc \
-XX:+PrintGCDetails \
-XX:+PrintGCDateStamps \
-XX:+PrintGCTimeStamps \
-XX:+UseGCLogFileRotation \
-XX:NumberOfGCLogFiles=${NUMBEROFGCLOGFILES:-5} \
-XX:GCLogFileSize=${GCLOGFILESIZE:-5M}"
debug GC_LOG_OPTS="${GC_LOG_OPTS}"
}

function gc_settings() {

GC_TYPE="${GC_TYPE:-G1}"
if [ "$GC_TYPE" == "G1" ]; then
  GC_OPTS="${GC_OPTS} -XX:+UseG1GC \
-XX:MaxGCPauseMillis=20"
else
  GC_OPTS="${GC_OPTS} -XX:+UseParNewGC \
-XX:+UseConcMarkSweepGC \
-XX:CMSInitiatingOccupancyFraction=75 \
-XX:+UseCMSInitiatingOccupancyOnly"
fi

HEAP_DUMP_ON_OOME=${HEAP_DUMP_ON_OOME:-" \
-XX:+HeapDumpOnOutOfMemoryError \
-XX:HeapDumpPath=${HEAP_DUMP_PATH:-${LOG_DIR}/} "}

export GC_OPTS="${GC_OPTS} \
${HEAP_DUMP_ON_OOME} \
-XX:InitiatingHeapOccupancyPercent=35 \
-XX:+DisableExplicitGC"
}

function jvm_settings() {
DEFAULT_JOLOKIA_PORT=${DEFAULT_JOLOKIA_PORT:-$(($JMX_PORT + 10000))}
[ "x$DISABLE_LARGE_PAGES" != "x" ] && LARGE_PAGES="${LARGE_PAGES:- -XX:+UseLargePages}"
if [ "x${JVM_OVERRIDES}" == "x" ] ; then
  export JVM_OPTS="-server \
-XX:+AggressiveOpts \
-XX:MaxMetaspaceSize=256m \
-Djava.awt.headless=true \
-Duser.timezone=${USER_TIMEZONE:-UTC} \
-Dnetworkaddress.cache.ttl=${DNS_TTL:-300} \
${LARGE_PAGES} \
-javaagent:${thisDir}/java/jolokia-jvm-agent.jar=${JOLOKIA_CONFIG:-port=${JOLOKIA_PORT:-$DEFAULT_JOLOKIA_PORT},host=0.0.0.0,discoveryEnabled=false,agentContext=/jmx} \
${JVM_OPTS}"
else
  export JVM_OPTS="${JVM_OVERRIDES} ${JVM_OPTS}"
fi
debug JVM_OPTS="${JVM_OPTS}"
}

function add_user_libs() {
[ "x${USER_LIBS}" != "x" ] && export CLASSPATH="${CLASSPATH}:${USER_LIBS}"

debug CLASSPATH="${CLASSPATH}"
}

function run_settings() {
  app_settings
  jmx_settings
  heap_settings
  gc_log_settings
  gc_settings
  jvm_settings
  add_user_libs
  export JAVA_PARAMS="${JAVA_PARAMS} ${JMX_OPTS} ${HEAP_OPTS} ${GC_LOG_OPTS} ${GC_OPTS} ${JVM_OPTS} ${APP_OPTS}"
  debug JAVA_PARAMS=${JAVA_PARAMS}
}

function run() {
  # Hack to get the entrypoint to work without specifying a command because of Dockerfile CMD issues
  app="${1:-$APP_NAME}"
  if [ "x$app" == "x$APP_NAME" ]; then
    shift
    SERVICE_NAME=${SERVICE_NAME:-$app}
    MAIN_CLASS=${MAIN_CLASS:-"-jar *.jar"}
    cd ${APP_WORKDIR:-$APP_HOME}

    run_settings

    #Echo the classpath because it can't be found by using ps
    echo CLASSPATH="${CLASSPATH}"
    CMD="java -Dapp.${app} ${JAVA_PARAMS} ${MAIN_CLASS} ${ARGS} $@ ${OVERRIDES}"
    debug CMD="${CMD}"
    exec ${CMD}
  else
    exec $@
  fi
}
