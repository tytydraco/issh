#!/usr/bin/env bash

# Server options
LOCAL=false
COMMAND="sh -li 2>&1"
PORT=65432

# Client options
INTERACTIVE=false
ADDRESS="localhost"

# Display usage for this script
usage() {
  echo "Insecure shelling via netcat

Usage: $0 [-h] [-l] [-c COMMAND] [-p PORT] [-t] [-C ADDRESS]
  -h            Show this screen

Server options:
  -l            Only allow localhost connections
  -c COMMAND    Command to run when client connects (default: $COMMAND)
  -p PORT       Port to listen on (default: $PORT)

Client options:
  -t            Use raw TTY for interactivity
  -C ADDRESS    Connect to an open session (default: $ADDRESS)"
}

if ! command -v toybox &> /dev/null
then
  echo "Missing toybox binary"
  exit 1
fi

# Parse user arguments
while getopts ":hlc:p:tC:" opt; do
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
  C)
    ADDRESS="$OPTARG"
    [[ "$INTERACTIVE" == true ]] && stty raw -echo icrnl opost
    toybox nc "$ADDRESS" "$PORT"
    [[ "$INTERACTIVE" == true ]] && stty sane
    exit 0
    ;;
  t)
    INTERACTIVE=true
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

# shellcheck disable=SC2068
toybox nc -L -p "$PORT" ${NCARGS[@]} sh -c "$COMMAND"
