#!/usr/bin/env bash

LOCAL=false     # Shall we only allow localhost connections?
PORT=65432      # Port to open with netcat

# Display usage for this script
usage() {
  echo "Usage: $0 [-h] [-k] [-l] [-p PORT]
  -h          Show this screen
  -k          Kill any open netcat sessions
  -l          Only allow localhost connections
  -p PORT     Port to listen for connections on (default: $PORT)"
}

# Return which flavor of netcat we have (Busybox or Toybox)
nc_flavor() {
  for flavor in busybox toybox
  do
    if command -v "$flavor" &> /dev/null
    then
      echo "$flavor"
      return
    fi
  done
}
flavor="$(nc_flavor)"

# Parse user arguments
while getopts ":lhkp:" opt
do
  case "$opt" in
    h)
      usage
      exit 0
      ;;
    k)
      pkill "$flavor"
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
if ss -l 2> /dev/null | grep -q ":$PORT"
then
  echo "Port is in use: $PORT"
  exit 1
fi

# Depending on the netcat flavor, we need different arguments
NCARGS=()
case "$flavor" in
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
setsid "$flavor" nc ${NCARGS[@]} sh -c "sh -i 2>&1" &

echo -e "Done! Use: \e[1mnc localhost $PORT\e[0m"