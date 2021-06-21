#!/usr/bin/env bash

# Constants
MODE_SERVER="server"
MODE_CLIENT="client"

# Global options
MODE="$MODE_SERVER"
PORT=65432

# Server options
LOCAL=false
COMMAND="sh -li 2>&1"

# Client options
INTERACTIVE=false
ADDRESS="localhost"

# Display usage for this script
usage() {
  echo "Insecure shelling via netcat

Usage: $0 [-h] [-p PORT] [-l] [-c COMMAND] [-t] [-C ADDRESS]
  -h            Show this screen
  -p PORT       Port to listen/connect on (default: $PORT)

Server options:
  -l            Only allow localhost connections
  -c COMMAND    Command to run when client connects (default: $COMMAND)

Client options:
  -t            Use raw TTY for interactivity
  -C ADDRESS    Connect to an open session (default: $ADDRESS)"
}

# Make sure we have everything we need to run
assert_dependencies() {
  if ! command -v toybox &>/dev/null
  then
    echo "Missing toybox binary"
    exit 1
  fi
}

# Check if port is out of range
assert_port_within_range() {
  if [[ "$PORT" -gt 65535 || "$PORT" -lt 1 ]]
  then
    echo "Port is out of range (1-65535): $PORT"
    exit 1
  fi
}

# Check if port is in use currently
assert_port_available() {
  if toybox netstat -lpn 2>/dev/null | toybox grep -w ".*:$PORT" &>/dev/null
  then
    echo "Port is in use: $PORT"
    exit 1
  fi
}

# Parse arguments passed to us and set relevant variables
parse_options() {
  while getopts ":hp:lc:tC:" opt
  do
    case "$opt" in
    h)
      usage
      exit 0
      ;;
    p)
      PORT="$OPTARG"
      ;;
    l)
      LOCAL=true
      ;;
    c)
      COMMAND="$OPTARG"
      ;;
    C)
      MODE="$MODE_CLIENT"
      ADDRESS="$OPTARG"
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
}

# Host a server
server() {
  assert_port_available

  # Handle arguments that should be given to netcat
  NC_ARGS=()
  [[ "$LOCAL" == true ]] && NC_ARGS+=("-s localhost")

  # shellcheck disable=SC2068
  toybox nc -L -p "$PORT" ${NC_ARGS[@]} sh -c "$COMMAND"
}

# Connect to a client
client() {
  [[ "$INTERACTIVE" == true ]] && stty raw -echo icrnl opost
  toybox nc "$ADDRESS" "$PORT"
  [[ "$INTERACTIVE" == true ]] && stty sane
}

parse_options "$@"
assert_dependencies
assert_port_within_range

if [[ "$MODE" == "$MODE_SERVER" ]]
then
  server
elif [[ "$MODE" == "$MODE_CLIENT" ]]
then
  client
fi
