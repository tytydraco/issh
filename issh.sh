#!/usr/bin/env bash

LOCAL=false
PORT=65432

# Detect if we have netcat at all
if ! command -v nc &> /dev/null
then
  echo "Netcat backend not found"
  exit 1
fi

usage() {
  echo "Usage: $0 [-h] [-k] [-l] [-p PORT]
  -h          Show this screen
  -k          Kill any open netcat sessions
  -l          Only allow localhost connections
  -p PORT     Port to listen for connections on (default: $PORT)"
}

while getopts ":lhkp:" opt
do
  case "$opt" in
    h)
      usage
      exit 0
      ;;
    k)
      pkill netcat
      exit 0
      ;;
    l)
      LOCAL=true
      ;;
    p)
      PORT="$OPTARG"
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

ARGS=()
[[ "$LOCAL" == true ]] && ARGS+=("-s localhost")

# shellcheck disable=SC2068
setsid netcat -p "$PORT" -L ${ARGS[@]} sh &

echo -e "Done! Use: \e[1mnc localhost $PORT\e[0m"