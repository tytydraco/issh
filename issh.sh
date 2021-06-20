#!/usr/bin/env bash

LOCAL=false # Shall we only allow localhost connections?
PORT=65432  # Port to open with netcat

# Display usage for this script
usage() {
  echo "Usage: $0 [-h] [-k] [-l] [-p PORT]
  -h          Show this screen
  -l          Only allow localhost connections
  -p PORT     Port to listen for connections on (default: $PORT)"
}

if ! command -v toybox &> /dev/null
then
  echo "Missing toybox binary"
  exit 1
fi

# Parse user arguments
while getopts ":lhp:" opt; do
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

# Check if we can even support this port
if toybox netstat -lpn 2> /dev/null | toybox grep 65432 &> /dev/null
then
  echo "Port is in use: $PORT"
  exit 1
fi

# Depending on the box flavor, we need different arguments
NCARGS=(
  "-L"
  "-p $PORT"
)
[[ "$LOCAL" == true ]] && NCARGS+=("-s localhost")

# Execute netcat and fork it
# shellcheck disable=SC2068
toybox setsid toybox nc ${NCARGS[@]} sh -c "sh -i 2>&1" &

echo -e "Done! Use: \e[1mnc localhost $PORT\e[0m"
