#!/usr/bin/env bash

# Android standard ToyBox binary
toybox() {
	/system/bin/toybox "$@"
}
export -f toybox

# Execute script with Android raw shell script
exec /system/bin/sh issh.sh "$@"
