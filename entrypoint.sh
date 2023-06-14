#!/bin/bash
set -e

# For all ENV vars with name "$prefix$name_$suffix" write out file
# lc($name-$suffix)=$value
#
# If $suffix == _FILE
# remove it from name and read value from file
env_config() {
  local prefix=$1
  local out=$2

  if [ -s $out ] ; then
    echo "$out exists already"
    return
  fi
  env |
    while read -r var ; do
      if [[ $var != ${var#$prefix} ]] ; then
        local name=${var%%=*}   # rm '=...' suffix

        val="${!name:-}"

        if [[ $name != ${name%_FILE} ]] ; then
          val="$(< "${!name}")" # read value from file
          name=${name%_FILE}    # rm suffix _FILE
          export "$name"="$val"
        fi

        local v=${name#$prefix} # rm prefix
        v=${v//_/-}             # replace _ with -
        v=${v,,}                # lowercase

        echo "$v=$val" >> $out
      fi
  done
}

setup_mysql_db() {
  MYSQLCMD="mysql --host=${PDNS_GMYSQL_HOST} --user=${PDNS_GMYSQL_USER} --password=${PDNS_GMYSQL_PASSWORD} --port=${PDNS_GMYSQL_PORT} -r -N"

  # wait for Database come ready
  isDBup () {
    echo "SHOW STATUS" | $MYSQLCMD 1>/dev/null
    echo $?
  }

  RETRY=10
  until [ `isDBup` -eq 0 ] || [ $RETRY -le 0 ] ; do
    echo "Waiting for database to come up"
    sleep 5
    RETRY=$(expr $RETRY - 1)
  done
  if [ $RETRY -le 0 ]; then
    >&2 echo Error: Could not connect to Database on $PDNS_GMYSQL_HOST:$PDNS_GMYSQL_PORT
    exit 1
  fi

  # init database if necessary
  echo "CREATE DATABASE IF NOT EXISTS $PDNS_GMYSQL_DBNAME;" | $MYSQLCMD
  MYSQLCMD="$MYSQLCMD $PDNS_GMYSQL_DBNAME"

  if [ "$(echo "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = \"$PDNS_GMYSQL_DBNAME\";" | $MYSQLCMD)" -le 1 ]; then
    echo Initializing Database #"
    cat /etc/pdns/schema.sql | $MYSQLCMD

    # Run custom mysql post-init sql scripts
    if [ -d "/etc/pdns/mysql-postinit" ]; then
      for SQLFILE in $(ls -1 /etc/pdns/mysql-postinit/*.sql | sort) ; do
        echo Source $SQLFILE
        cat $SQLFILE | $MYSQLCMD
      done
    fi
  fi

  unset -v PDNS_GMYSQL_PASSWORD
}

env_config "PDNS_" /etc/pdns/pdns.conf

# --help, --version
[ "$1" = "--help" ] || [ "$1" = "--version" ] && exec pdns_server $1
# treat everything except -- as exec cmd
[ "${1:0:2}" != "--" ] && exec "$@"

if [[ "$MYSQL_AUTOCONF" == "true" ]] ; then
  setup_mysql_db
fi

# Run pdns server
trap "pdns_control quit" SIGHUP SIGINT SIGTERM

pdns_server "$@" &

wait
