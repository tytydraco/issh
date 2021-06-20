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

# Return which flavor of toolbox we have (busybox or toybox)
box_flavor() {
  local flavor
  for flavor in busybox toybox; do
    if command -v "$flavor" &>/dev/null; then
      echo "$flavor"
      return
    fi
  done
}
box="$(box_flavor)"

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
if ss -l 2>/dev/null | grep -q ":$PORT"; then
  echo "Port is in use: $PORT"
  exit 1
fi

# Depending on the box flavor, we need different arguments
NCARGS=()
case "$box" in
  busybox)
    NCARGS+=(
      "-l"
      "-k"
      "-p $PORT"
    )
    [[ "$LOCAL" == true ]] && NCARGS+=("-s localhost")
    NCARGS+=("-e")
    ;;
  toybox)
    NCARGS+=(
      "-L"
      "-p $PORT"
    )
    [[ "$LOCAL" == true ]] && NCARGS+=("-s localhost")
    ;;
  *)
    echo "Neither Busybox nor Toybox detected"
    exit 1
    ;;
esac

# Execute netcat and fork it
# shellcheck disable=SC2068
setsid "$box" nc ${NCARGS[@]} sh -c "sh -i 2>&1" &

echo -e "Done! Use: \e[1mnc localhost $PORT\e[0m"
