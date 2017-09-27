FROM towerhawk/alpine-java-base:base-latest

ONBUILD ARG UID=1000
ONBUILD ARG GID=$UID
ONBUILD ARG APP_NAME
ONBUILD ARG USER=$APP_NAME
ONBUILD ARG GROUP=$USER
ONBUILD ARG ADDITIONAL_COMMANDS="echo finishing onbuild"
ONBUILD ARG DEFAULT_JMX_PORT=18080

ONBUILD ENV PATH=/app/$APP_NAME/bin:/app/$APP_NAME:$PATH \
  APP_NAME=$APP_NAME \
  APP_HOME=/app/$APP_NAME \
  USER=$USER \
  GROUP=$GROUP \
  UID=$UID \
  GID=$GID \
  DEFAULT_JMX_PORT=$DEFAULT_JMX_PORT

ONBUILD RUN mkdir -p $APP_HOME \
       $APP_HOME/logs \
       $APP_HOME/etc \
       $APP_HOME/config \
       $APP_HOME/bin \
       $APP_HOME/health \
  && addgroup -g $GID $GROUP \
  && adduser -u $UID -h $APP_HOME -s /bin/sh -D -H -G $GROUP $USER \
  && chown -R $USER:$GROUP /app/*.sh /app/health $APP_HOME $APP_HOME/* \
  && eval $ADDITIONAL_COMMANDS

ONBUILD WORKDIR $APP_HOME/

