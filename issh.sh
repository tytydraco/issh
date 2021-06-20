#!/usr/bin/env bash

LOCAL=false
COMMAND="sh -li 2>&1"
PORT=65432

# Display usage for this script
usage() {
  echo "Creates an insecure shell via netcat

Usage: $0 [-h] [-l] [-p PORT]
  -h            Show this screen
  -l            Only allow localhost connections
  -c COMMAND    Command to use when client connects (default: $COMMAND)
  -p PORT       Port to listen for connections on (default: $PORT)"
}

if ! command -v toybox &> /dev/null
then
  echo "Missing toybox binary"
  exit 1
fi

# Parse user arguments
while getopts ":hlc:p:" opt; do
  case "$opt" in
  h)
    usage
    exit 0
    ;;
  l)
    LOCAL=true
    ;;
  c)
    COMMAND="$OPTARG"
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

# Check if port is out of range
if [[ "$PORT" -gt 65535 || "$PORT" -lt 1 ]]
then
  echo "Port is out of range (1-65535): $PORT"
  exit 1
fi

# Check if we can even support this port
if toybox netstat -lpn 2> /dev/null | toybox grep -w ".*:$PORT" &> /dev/null
then
  echo "Port is in use: $PORT"
  exit 1
fi

# Handle arguments that should be given to netcat
NCARGS=()
[[ "$LOCAL" == true ]] && NCARGS+=("-s localhost")

echo -e "Connect with: \e[1mnc localhost $PORT\e[0m"

# shellcheck disable=SC2068
toybox nc -L -p "$PORT" ${NCARGS[@]} sh -c "$COMMAND"
