#!/usr/bin/env bash

# Constants
MODE_SERVER="server"
MODE_CLIENT="client"

# Global options
MODE="$MODE_SERVER"
PORT=65432

# Server options
LOCAL=false
DAEMON=false
COMMAND="sh 2>&1"

# Client options
INTERACTIVE=false
ADDRESS="localhost"

# Display usage for this script
usage() {
  echo "Insecure shelling via netcat

Usage: $0 [-h] [-p PORT] [-l] [-d] [-c COMMAND] [-t] [-C ADDRESS]
  -h            Show this screen
  -p PORT       Port to listen/connect on (default: $PORT)

Server options:
  -l            Only allow localhost connections
  -d            Fork to background; run as daemon
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
is_port_within_range() {
  [[ "$1" -gt 1 && "$1" -lt 65535 ]]
}

# Bail if port is out of range
assert_port_within_range() {
  if ! is_port_within_range "$1"
  then
    echo "Port is out of range (1-65535): $1"
    exit 1
  fi
}

# Check if port is in use currently
is_port_available() {
  ! toybox netstat -lpn 2>/dev/null | toybox grep -w ".*:$1" &>/dev/null
}

# Bail if port is taken
assert_port_available() {
  if ! is_port_available "$1"
  then
    echo "Port is in use: $1"
    exit 1
  fi
}

# Parse arguments passed to us and set relevant variables
parse_options() {
  while getopts ":hp:ldc:tC:" opt
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
    d)
      DAEMON=true
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
# shellcheck disable=SC2068
server() {
  assert_port_within_range "$PORT"
  assert_port_available "$PORT"

  # Handle arguments that should be given to netcat
  nc_args=(
    "-L"
    "-p $PORT"
  )
  [[ "$LOCAL" == true ]] && nc_args+=("-s localhost")

  if [[ "$DAEMON" == true ]]
  then
    toybox setsid toybox nc ${nc_args[@]} sh -c "$COMMAND" &
  else
    toybox nc ${nc_args[@]} sh -c "$COMMAND"
  fi
}

# Connect to a client
client() {
  assert_port_within_range "$PORT"

  [[ "$INTERACTIVE" == true ]] && stty raw -echo icrnl opost
  toybox nc "$ADDRESS" "$PORT"
  [[ "$INTERACTIVE" == true ]] && stty sane
}

parse_options "$@"
assert_dependencies

if [[ "$MODE" == "$MODE_SERVER" ]]
then
  server
elif [[ "$MODE" == "$MODE_CLIENT" ]]
then
  client
fi
