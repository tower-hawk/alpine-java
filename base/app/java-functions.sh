#!/bin/bash
# This script is meant to be sourced by entrypoint.sh scripts or be referenced directly

thisDir=$(cd $(dirname $(realpath ${BASH_SOURCE[0]})) && pwd)
appDir=${thisDir}

if [ ${#BASH_SOURCE[@]} -ge 1 ]; then
  appDir=$(cd $(dirname ${BASH_SOURCE[1]}) && pwd)
fi

export APP_NAME="${APP_NAME:-app}"
export SERVICE_NAME="${SERVICE_NAME:-${APP_NAME}}"
if [ "x${appDir}" == "x/app" ] && [ -d "/app/${APP_NAME}" ]; then
  appDir="/app/${APP_NAME}"
fi
export APP_HOME="${APP_HOME:-${appDir}}"

function debug () {
  [ "x${DEBUG}" == "xtrue" ] && echo $@
}

export LOG_DIR="${LOG_DIR:-${APP_HOME}/logs}"

function run_commands() {
  for command in $(compgen -A variable | grep -e "^${1}_" | sort)
  do
    debug "${command}=${!command}"
    eval "${!command}"
  done
}

function file_settings() {
  [ -f "${ENV_FILE}" ] && . ${ENV_FILE}
  for file in $(compgen -A variable | grep -e "^ENV_FILE_" | sort)
  do
    debug "${file}=${!file}"
    . ${!file}
  done

  [ -f "${SETTINGS_FILE}" ] && export FILE_SETTINGS="$(cat ${SETTINGS_FILE} | xargs)"
  for file in $(compgen -A variable | grep -e "^SETTINGS_FILE_" | sort)
  do
    debug "${file}=${!file}"
    # grep -v ignores any lines that start with # or spaces then #. xargs takes care of empty lines
    export FILE_SETTINGS="${FILE_SETTINGS} $(cat "${!file}" | grep -v "^[[:space:]]*#" | xargs)"
  done
  debug FILE_SETTINGS="${FILE_SETTINGS}"

  [ -f "${ARGUMENTS_FILE}" ] && export FILE_ARGUMENTS="$(cat ${ARGUMENTS_FILE} | xargs)"
  for file in $(compgen -A variable | grep -e "^ARGUMENTS_FILE_" | sort)
  do
    debug "${file}=${!file}"
    export FILE_ARGUMENTS="${FILE_ARGUMENTS} $(cat "${!file}" | grep -v "^[[:space:]]*#" | xargs)"
  done
  debug FILE_ARGUMENTS="${FILE_ARGUMENTS}"
}

function app_settings() {
  for opt in $(compgen -A variable | grep -e "^APP_OPT_" | sort)
  do
    debug "${opt}=${!opt}"
    export APP_OPTS="${APP_OPTS} ${!opt}"
  done
  debug "APP_OPTS=${APP_OPTS}"
}

function log_settings() {
  : ${LOG_OPT_LOG_DIR="-Dlog.dir=${LOG_DIR}"}
  for opt in $(compgen -A variable | grep -e "^LOG_OPT_" | sort)
  do
    debug "${opt}=${!opt}"
    export LOG_OPTS="${LOG_OPTS} ${!opt}"
  done
  debug "LOG_OPTS=${LOG_OPTS}"
}

function jmx_settings() {
  DEFAULT_JMX_PORT="${DEFAULT_JMX_PORT:-18080}"
  export JMX_PORT="${JMX_PORT:-$DEFAULT_JMX_PORT}"

  JMX_HOSTNAME=${JMX_HOSTNAME:-$(hostname -f)}

  if [ "x${ENABLE_JMX:-true}" == "xtrue" ]; then
    : ${JMX_OPT_REMOTE="-Dcom.sun.management.jmxremote"}
    : ${JMX_OPT_LOCAL_ONLY="-Dcom.sun.management.jmxremote.local.only=${JMX_LOCAL_ONLY:-false}"}
    : ${JMX_OPT_RMI_PORT="-Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}"}
    : ${JMX_OPT_REMOTE_PORT="-Dcom.sun.management.jmxremote.port=${JMX_PORT}"}
    : ${JMX_OPT_SERVER_HOSTNAME="-Djava.rmi.server.hostname=${JMX_HOSTNAME}"}

    if [ "x${JMX_USE_SSL:-false}" == "xtrue" ]; then
      : ${JMX_KEYSTORE="${JMX_KEYSTORE:-/app/jmx/ssl/private/default.keystore}"}
      : ${JMX_KEYSTORE_PASSWORD="${JMX_KEYSTORE_PASSWORD:-default}"}
      : ${JMX_OPT_SSL="-Dcom.sun.management.jmxremote.ssl=true"}
      : ${JMX_OPT_SSL_NEED_CLIENT_AUTH="-Dcom.sun.management.jmxremote.ssl.need.client.auth=${JMX_SSL_CLIENT_AUTH:-true}"}
      : ${JMX_OPT_REGISTRY_SSL="-Dcom.sun.management.jmxremote.registry.ssl=${JMX_SSL_REGISTRY:-true}"}
      : ${JMX_OPT_SSL_KEYSTORE="-Djavax.net.ssl.keyStore=${JMX_KEYSTORE}"}
      : ${JMX_OPT_SSL_KEYSTORE_PASSWORD="-Djavax.net.ssl.keyStorePassword=${JMX_KEYSTORE_PASSWORD}"}
      : ${JMX_OPT_SSL_TRUSTSTORE="-Djavax.net.ssl.trustStore=${JMX_TRUSTSTORE:-${JMX_KEYSTORE}}"}
      : ${JMX_OPT_SSL_TRUSTSTORE_PASSWORD="-Djavax.net.ssl.trustStorePassword=${JMX_TRUSTSTORE_PASSWORD:-${JMX_KEYSTORE_PASSWORD}}"}
      : ${JMX_OPT_SSL_ENABLED_PROTOCOLS="-Djavax.rmi.ssl.client.enabledProtocols=${JMX_ENABLED_PROTOCOLS:-TLSv1.2}"}
      : ${JMX_OPT_SSL_ENABLED_CIPHER_SUITES="-Djavax.rmi.ssl.client.enabledCipherSuites=${JMX_ENABLED_CIPHER_SUITES:-TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256,TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA384,TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384}"}
    else
      : ${JMX_OPT_SSL="-Dcom.sun.management.jmxremote.ssl=false"}
    fi

    if [ "x${JMX_USE_AUTH:-false}" == "xtrue" ]; then
      JMX_PASSWORD_FILE="${JMX_PASSWORD_FILE:-/app/jmx/ssl/password/jmxremote.password}"
      JMX_ACCESS_FILE="${JMX_ACCESS_FILE:-/app/jmx/ssl/access/jmxremote.access}"
      sed -i "s/monitorRolePassword/${JMX_MONITOR_ROLE_PASSWORD:-monitor}/" ${JMX_PASSWORD_FILE}
      sed -i "s/controlRolePassword/${JMX_CONTROL_ROLE_PASSWORD:-control}/" ${JMX_PASSWORD_FILE}
      : ${JMX_OPT_AUTHENTICATE="-Dcom.sun.management.jmxremote.authenticate=true"}
      : ${JMX_OPT_PASSWORD_FILE="-Dcom.sun.management.jmxremote.password.file=${JMX_PASSWORD_FILE}"}
      : ${JMX_OPT_ACCESS_FILE="-Dcom.sun.management.jmxremote.access.file=${JMX_ACCESS_FILE}"}
    else
      : ${JMX_OPT_AUTHENTICATE="-Dcom.sun.management.jmxremote.authenticate=false"}
    fi
  fi

  for opt in $(compgen -A variable | grep -e "^JMX_OPT_" | sort)
  do
    debug "${opt}=${!opt}"
    export JMX_OPTS="${JMX_OPTS} ${!opt}"
  done
  debug "JMX_OPTS=${JMX_OPTS}"
}

function heap_settings() {
  MIN_HEAP=-Xms${MIN_HEAP_SIZE:-64m}
  MAX_HEAP=-Xmx${MAX_HEAP_SIZE:-256m}
  : ${HEAP_OPTS="${MIN_HEAP} ${MAX_HEAP}"}

  export HEAP_OPTS
  for opt in $(compgen -A variable | grep -e "^HEAP_OPT_" | sort)
  do
    debug "${opt}=${!opt}"
    export HEAP_OPTS="${HEAP_OPTS} ${!opt}"
  done

  debug HEAP_OPTS="${HEAP_OPTS}"
}

function gc_log_settings() {
  if [ "x${LOGGC}" != "xfalse" ]; then
    : ${GC_LOG_FILE="${LOG_DIR}/${SERVICE_NAME}-gc.log"}
    : ${GC_NUMBER_LOG_FILES="5"}
    : ${GC_LOG_FILE_SIZE="5M"}
    : ${GC_REF_LEVEL="debug"}
    : ${GC_HEAP_LEVEL="debug"}
    : ${GC_AGE_LEVEL="trace"}
    : ${GC_DECORATORS="tags,uptime,time,level"}
    : ${GC_LOG_OPT_OPTIONS="-Xlog:gc*,gc+ref=${GC_REF_LEVEL},gc+heap=${GC_HEAP_LEVEL},gc+age=${GC_AGE_LEVEL}:file=${GC_LOG_FILE}:${GC_DECORATORS}:filecount=${GC_NUMBER_LOG_FILES},filesize=${GC_LOG_FILE_SIZE}"}
  fi

  for opt in $(compgen -A variable | grep -e "^GC_LOG_OPT_" | sort)
  do
    debug "${opt}=${!opt}"
    export GC_LOG_OPTS="${GC_LOG_OPTS} ${!opt}"
  done
  debug GC_LOG_OPTS="${GC_LOG_OPTS}"
}

function gc_settings() {

  GC_TYPE="${GC_TYPE:-G1}"
  if [ "$GC_TYPE" == "G1" ]; then
    : ${GC_OPT_G1="-XX:+UseG1GC"}
    : ${GC_OPT_MAX_GC_PAUSE_MILLIS="-XX:MaxGCPauseMillis=${MAX_GC_PAUSE_MILLIS:-20}"}
  elif [ "$GC_TYPE" == "CMS" ]; then
    : ${GC_OPT_PAR_NEW="-XX:+UseParNewGC"}
    : ${GC_OPT_CONC_MARK_SWEEP="-XX:+UseConcMarkSweepGC"}
    : ${GC_OPT_CMS_INITIATING_OCCUPANCY_FRACTION="-XX:CMSInitiatingOccupancyFraction=75"}
    : ${GC_OPT_CMS_USE_INITIATING_OCCUPANCY_ONLY="-XX:+UseCMSInitiatingOccupancyOnly"}
  fi

  : ${GC_OPT_HEAP_DUMP_ON_OOME="-XX:+HeapDumpOnOutOfMemoryError"}
  : ${GC_OPT_HEAP_DUMP_PATH="-XX:HeapDumpPath=${HEAP_DUMP_PATH:-${LOG_DIR}/}"}

  : ${GC_OPT_INITIATING_HEAP_OCCUPANCY_PERCENT="-XX:InitiatingHeapOccupancyPercent=35"}
  : ${GC_OPT_DISABLE_EXPLICIT_GC="-XX:+DisableExplicitGC"}

  for opt in $(compgen -A variable | grep -e "^GC_OPT_" | sort)
  do
    debug "${opt}=${!opt}"
    export GC_OPTS="${GC_OPTS} ${!opt}"
  done
  debug GC_OPTS="${GC_OPTS}"
}

function jvm_settings() {
  DEFAULT_JOLOKIA_PORT=${DEFAULT_JOLOKIA_PORT:-$((${JMX_PORT} + 10000))}
#  : ${JVM_OPT_LARGE_PAGES="-XX:+UseLargePages"}
#  : ${JVM_OPT_AGGRESSIVE_OPTS="-XX:+AggressiveOpts"}
  if [ "x${JVM_OVERRIDES}" == "x" ] ; then
    JAVA_IO_TMPDIR="${JAVA_IO_TMPDIR:-/tmp/${SERVICE_NAME}}"
    mkdir -p ${JAVA_IO_TMPDIR}
    : ${JVM_OPT_SERVER="-server"}
    : ${JVM_OPT_AWT_HEADLESS="-Djava.awt.headless=${JAVA_AWT_HEADLESS:-true}"}
    : ${JVM_OPT_USER_TIMEZONE="-Duser.timezone=${USER_TIMEZONE:-UTC}"}
    : ${JVM_OPT_NETWORKADDRESS_CACHE_TTL="-Dnetworkaddress.cache.ttl=${DNS_TTL:-300}"}
    : ${JVM_OPT_FILE_ENCODING="-Dfile.encoding=${FILE_ENCODING:-UTF-8}"}
    : ${JVM_OPT_IO_TMPDIR="-Djava.io.tmpdir=${JAVA_IO_TMPDIR}"}
    : ${JVM_OPT_SECURITY_EGD="-Djava.security.egd=${JAVA_SECURITY_EGD:-file:/dev/urandom}"}
  else
    export JVM_OPTS="${JVM_OVERRIDES} ${JVM_OPTS}"
  fi

  for opt in $(compgen -A variable | grep -e "^JVM_OPT_" | sort)
  do
    debug "${opt}=${!opt}"
    export JVM_OPTS="${JVM_OPTS} ${!opt}"
  done
  debug JVM_OPTS="${JVM_OPTS}"
}

function jvm_agents() {
  [[ "x${JOLOKIA_USER}" != "x" ]] && JOLOKIA_USER_OPT=",user=${JOLOKIA_USER}"
  [[ "x${JOLOKIA_PASSWORD}" != "x" ]] && JOLOKIA_PASSWORD_OPT=",password=${JOLOKIA_PASSWORD}"
  JOLOKIA_CONFIG="${JOLOKIA_CONFIG:-${JOLOKIA_USER_OPT}${JOLOKIA_PASSWORD_OPT}port=${JOLOKIA_PORT:-$DEFAULT_JOLOKIA_PORT},host=${JOLOKIA_HOST:-0.0.0.0},discoveryEnabled=${JOLOKIA_DISCOVERY_ENABLED:-false},agentContext=${JOLOKIA_AGENT_CONTEXT:-/jmx} }"
  : ${JVM_AGENT_OPT_JOLOKIA="${JOLOKIA_AGENT:- -javaagent:${thisDir}/java/jolokia-jvm-agent.jar=${JOLOKIA_CONFIG}}"}
  for agent in $(compgen -A variable | grep -e "^JVM_AGENT_OPT_")
  do
    debug "${agent}=${!agent}"
    export JVM_AGENTS="${JVM_AGENTS} ${!agent}"
  done
  debug "JVM_AGENTS=${JVM_AGENTS}"
}

function add_user_libs() {
  if [ "x${USER_LIB_DIRS}" != "x" ]; then
    for path in ${USER_LIB_DIRS}
    do
      if [ -d ${path} ]; then
        for file in ${path}/*
        do
          export CLASSPATH="$(realpath ${file}):${CLASSPATH}"
        done
      fi
    done
  fi

  unset USER_LIB_DIRS
  for path in $(compgen -A variable | grep -e "^USER_LIB_" | sort)
  do
    debug "${path}=${!path}"
    [[ "x${!path}" != "x" ]] && export CLASSPATH="${!path}:${CLASSPATH}"
  done

  [ "x${USER_LIBS}" != "x" ] && export CLASSPATH="${USER_LIBS}:${CLASSPATH}"
}

function set_classpath() {
  if [ "x${CLASSPATH_DIRS}" != "x" ]; then
    for path in ${CLASSPATH_DIRS}
    do
      if [ -d ${path} ]; then
        for file in ${path}/*
        do
          export CLASSPATH="${CLASSPATH}:$(realpath ${file})"
        done
      fi
    done
    unset CLASSPATH_DIRS
  fi

  for path in $(compgen -A variable | grep -e "^CLASSPATH_DIR_" | sort)
  do
    debug "${path}=${!path}"
    if [ -d ${!path} ]; then
      for file in ${!path}/*
      do
        export CLASSPATH="${CLASSPATH}:$(realpath ${file})"
      done
    fi
    unset ${path}
  done

  for path in $(compgen -A variable | grep -e "^CLASSPATH_" | sort)
  do
    debug "${path}=${!path}"
    [[ "x${!path}" != "x" ]] && export CLASSPATH="${CLASSPATH}:${!path}"
  done

  add_user_libs

  #Echo the classpath because it can't be found by using ps
  echo "CLASSPATH=${CLASSPATH}"
}

function resolve_args_overrides() {
  for arg in $(compgen -A variable | grep -e "^ARG_")
  do
    debug "${arg}=${!arg}"
    export ARGS="${ARGS} ${!arg}"
  done
  debug "ARGS=${ARGS}"
  for override in $(compgen -A variable | grep -e "^OVERRIDE_")
  do
    debug "${override}=${!override}"
    export OVERRIDES="${OVERRIDES} ${!override}"
  done
  debug "OVERRIDES=${OVERRIDES}"
}

function run_settings() {
  run_commands RUN_PRE
  file_settings
  run_commands RUN_MID
  app_settings
  log_settings
  jmx_settings
  heap_settings
  gc_log_settings
  gc_settings
  jvm_settings
  jvm_agents
  set_classpath
  resolve_args_overrides
  run_commands RUN_POST
  export JAVA_PARAMS="${JAVA_PARAMS} ${JVM_AGENTS} ${JMX_OPTS} ${HEAP_OPTS} ${GC_LOG_OPTS} ${GC_OPTS} ${JVM_OPTS} ${FILE_SETTINGS} ${LOG_OPTS} ${APP_OPTS}"
  debug JAVA_PARAMS=${JAVA_PARAMS}
}

function trapExec() {
  echo "Trapped signal"
  if [[ "x${PREKILL_CMD}" != "x" ]]; then
    [[ "x${DEBUG}" == "xtrue" ]] && eval "${PREKILL_DEBUG}"
    echo "Evaluating '${PREKILL_CMD}'"
    eval "${PREKILL_CMD}"
  fi
  : ${KILL_SIGNAL="TERM"}
  echo "Sending ${KILL_SIGNAL} to ${PID}"
  kill -${KILL_SIGNAL} ${PID}
}

function run() {
  : ${USE_EXEC=true}
  if [ "x${1:-$APP_NAME}" == "x$APP_NAME" ]; then
    shift
    #Used for images that can run multiple services with a single build
    : ${MAIN_CLASS="-jar *.jar"}
    : ${APP_WORKDIR=${APP_HOME}}
    cd ${APP_WORKDIR}

    run_settings
    [ "x${DEBUG}" == "xtrue" ] && echo "Environment variables: " && echo && env | sort && echo

    CMD="java -Dapp.${SERVICE_NAME} ${JAVA_PARAMS} ${MAIN_CLASS} ${ARGS} $@ ${OVERRIDES} ${FILE_ARGUMENTS}"
    debug "CMD=${CMD}"
    if [[ "x${USE_EXEC}" == "xfalse" ]]; then
      : ${TRAP_SIGNALS="TERM INT"}
      trap trapExec ${TRAP_SIGNALS}
      ${CMD} &
      export PID=$!
      echo -e "##################################\nWaiting on pid ${PID}\n##################################"
      wait ${PID}
      trap - ${TRAP_SIGNALS}
      echo "waiting for pid ${PID}"
      wait ${PID}
      echo "pid ${PID} stopped"
      # RUN_AFTER only available for processes that run in the background since exec always terminates pid 1
      run_commands RUN_AFTER
      echo "exiting"
    else
      exec ${CMD}
    fi
  else
    if [[ "x${USE_EXEC}" == "xfalse" ]]; then
      $@
    else
      exec $@
    fi
  fi
}
