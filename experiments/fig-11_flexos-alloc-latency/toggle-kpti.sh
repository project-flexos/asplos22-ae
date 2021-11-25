#!/bin/bash

function check_who {
	echo "unimplemented"
	# TODO
}

function on {
	echo "unimplemented"
	# TODO
}

function off {
	echo "unimplemented"
	# TODO
}

die() { echo "$*" 1>&2 ; exit 1; }

case "$1" in
    on)
        on
        ;;
    off)
        off
        ;;
    *)
        die "'$1': unsupported argument. Usage: $0 {on, off}"
        ;;
esac
