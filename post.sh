#!/bin/bash
#set -e

export PATH=$TOOLBOX_PATH:$PATH

if [ ! -e $TOOLBOX_PATH/bart ] ; then
        echo "\$TOOLBOX_PATH is not set correctly!" >&2
        exit 1
fi

usage="Usage: $0 <reco> <t1map>"

if [ $# -lt 2 ] ; then

        echo "$usage" >&2
        exit 1
fi


reco=$(readlink -f "$1")
t1map=$(readlink -f "$2")


if [ ! -e $reco ] ; then
        echo "Input file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e $TOOLBOX_PATH/bart ] ; then
        echo "\$TOOLBOX_PATH is not set correctly!" >&2
        exit 1
fi


bart looklocker -t0.2 -D0.0153 $reco $t1map

