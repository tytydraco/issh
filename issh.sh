#!/usr/bin/env bash

LOCAL=false # Shall we only allow localhost connections?
PORT=65432  # Port to open with netcat

# Display usage for this script
usage() {
  echo "Usage: $0 [-h] [-l] [-p PORT]
  -h          Show this screen
  -l          Only allow localhost connections
  -p PORT     Port to listen for connections on (default: $PORT)

  Set environmental variable 'KEY' to require a login key.
  Example: KEY=mypassword123 $0"
}

# Gets called when user attempts to connect to us
login() {
  local key

  # If server didn't specify a key, launch shell
  if [[ -z "$KEY" ]]
  then
    sh -i
    exit
  fi

  # Verify authentication attempts
  echo -n "Key: "
  read -r key
  if [[ "$key" == "$KEY" ]]
  then
    clear
    sh -i
    exit
  else
    echo "Incorrect key."
    exit 1
  fi
}
export -f login

if ! command -v toybox &> /dev/null
then
  echo "Missing toybox binary"
  exit 1
fi

# Parse user arguments
while getopts ":hlp:" opt; do
  case "$opt" in
  h)
    usage
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
toybox nc -L -p "$PORT" ${NCARGS[@]} sh -c "login 2>&1"
