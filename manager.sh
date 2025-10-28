#!/bin/bash

read_vmoptions() {
  vmoptions_file=`eval echo "$1" 2>/dev/null`
  if [ ! -r "$vmoptions_file" ]; then
    vmoptions_file="$prg_dir/$vmoptions_file"
  fi
  if [ -r "$vmoptions_file" ] && [ -f "$vmoptions_file" ]; then
    exec 8< "$vmoptions_file"
    while read cur_option<&8; do
      is_comment=`expr "W$cur_option" : 'W *#.*'`
      if [ "$is_comment" = "0" ]; then
        vmo_classpath=`expr "W$cur_option" : 'W *-classpath \(.*\)'`
        vmo_classpath_a=`expr "W$cur_option" : 'W *-classpath/a \(.*\)'`
        vmo_classpath_p=`expr "W$cur_option" : 'W *-classpath/p \(.*\)'`
        vmo_include=`expr "W$cur_option" : 'W *-include-options \(.*\)'`
        if [ ! "W$vmo_include" = "W" ]; then
            if [ "W$vmo_include_1" = "W" ]; then
              vmo_include_1="$vmo_include"
            elif [ "W$vmo_include_2" = "W" ]; then
              vmo_include_2="$vmo_include"
            elif [ "W$vmo_include_3" = "W" ]; then
              vmo_include_3="$vmo_include"
            fi
        fi
        if [ ! "$vmo_classpath" = "" ]; then
          local_classpath="$i4j_classpath:$vmo_classpath"
        elif [ ! "$vmo_classpath_a" = "" ]; then
          local_classpath="${local_classpath}:${vmo_classpath_a}"
        elif [ ! "$vmo_classpath_p" = "" ]; then
          local_classpath="${vmo_classpath_p}:${local_classpath}"
        elif [ "W$vmo_include" = "W" ]; then
          needs_quotes=`expr "W$cur_option" : 'W.* .*'`
          if [ "$needs_quotes" = "0" ]; then
            vmoptions_val="$vmoptions_val $cur_option"
          else
            if [ "W$vmov_1" = "W" ]; then
              vmov_1="$cur_option"
            elif [ "W$vmov_2" = "W" ]; then
              vmov_2="$cur_option"
            elif [ "W$vmov_3" = "W" ]; then
              vmov_3="$cur_option"
            elif [ "W$vmov_4" = "W" ]; then
              vmov_4="$cur_option"
            elif [ "W$vmov_5" = "W" ]; then
              vmov_5="$cur_option"
            fi
          fi
        fi
      fi
    done
    exec 8<&-
    if [ ! "W$vmo_include_1" = "W" ]; then
      vmo_include="$vmo_include_1"
      unset vmo_include_1
      read_vmoptions "$vmo_include"
    fi
    if [ ! "W$vmo_include_2" = "W" ]; then
      vmo_include="$vmo_include_2"
      unset vmo_include_2
      read_vmoptions "$vmo_include"
    fi
    if [ ! "W$vmo_include_3" = "W" ]; then
      vmo_include="$vmo_include_3"
      unset vmo_include_3
      read_vmoptions "$vmo_include"
    fi
  fi
}

##########################################################

# detect if execute as root user
run_as_user=''
run_as_root=true
user_id=$(id -u)
user_name=$(id -u -n)
if [ -z "$run_as_user" -a "$user_id" -ne 0 ]; then
  run_as_root=false
elif [ -n "$run_as_user" -a "$run_as_user" != 'root' ]; then
  run_as_root=false
fi

# complain if root execution is detected
if $run_as_root; then
  echo 'WARNING: ************************************************************'
  echo 'WARNING: Detected execution as "root" user.  This is NOT recommended!'
  echo 'WARNING: ************************************************************'
  exit 1
elif [ -n "$run_as_user" -a "$run_as_user" != "$user_name" ]; then
  # re-execute launcher script as specified user
  exec su - "$run_as_user" "$prg_dir/$progname" "$@"
fi

##########################################################

# execute command
app_java_home=/usr/local/java

APP_DIR=/data/service/xxl-job-admin-3.2.1
CUR_DIR=$(pwd)

BIN_DIR=$APP_DIR/bin
CONF_DIR=$APP_DIR/conf
LIB_DIR=$APP_DIR/lib

WORK_DIR=$APP_DIR/work
PID_FILE=$WORK_DIR/pid
LOG_DIR=$WORK_DIR/log
DATA_DIR=$WORK_DIR/data

# re-execute launcher script as specified cwd
if [[ "$CUR_DIR" != "$APP_DIR" ]]; then
  echo "Change the process current working directory"
  cd $APP_DIR && exec "$BIN_DIR/manager.sh" $@
fi

echo $APP_DIR
echo $CUR_DIR

start() {
    echo "Starting application"
    # read jvm.options config file
    vmoptions_val=""
    read_vmoptions "$BIN_DIR/jvm.options"
    export LOG_HOME=work/log
    nohup $app_java_home/bin/java $vmoptions_val -jar $LIB_DIR/xxl-job-admin-3.2.1-SNAPSHOT.jar \
     --spring.config.additional-location=$CONF_DIR/ --spring.profiles.active="${APP_ENV:-dev}" > $LOG_HOME/stdout.log 2>&1 &
    echo "$app_java_home/bin/java $vmoptions_val -jar $LIB_DIR/xxl-job-admin-3.2.1-SNAPSHOT.jar --spring.config.additional-location=$CONF_DIR/ --spring.profiles.active=${APP_ENV:-dev}"
    echo $! >"$PID_FILE"
    cat $PID_FILE 2>/dev/null
}

stop() {
    echo "Shutting down application"
    PID=$(cat $PID_FILE 2>/dev/null)
    if kill -0 $PID; then
      kill -s TERM $PID && rm $PID_FILE 2>/dev/null
    else
      rm $PID_FILE 2>/dev/null
    fi
}

case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        stop
        sleep 3
        start
    ;;
    *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
    ;;
esac
exit $?
