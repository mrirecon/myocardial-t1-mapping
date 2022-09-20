#!/bin/bash
set -e

if [ ! -e $TOOLBOX_PATH/bart ] ; then
        echo "\$TOOLBOX_PATH is not set correctly!" >&2
        exit 1
fi
export PATH=$TOOLBOX_PATH:$PATH
export BART_COMPAT_VERSION="v0.5.00"

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

if ./utils/version_check.sh ; then
	RESCALE_LL=1
else
	RESCALE_LL=0
fi

# Mac: http://unix.stackexchange.com/questions/30091/fix-or-alternative-for-mktemp-in-os-x
WORKDIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
trap 'rm -rf "$WORKDIR"' EXIT
cd $WORKDIR


if [ $RESCALE_LL -eq 1 ] ; then
	# work around scaling in looklocker:
	printf "%s\n" "Rescaling looklocker"
	bart slice 6 0 $reco tmp_Ms
	bart slice 6 1 $reco tmp_M0
	bart slice 6 2 $reco tmp_R1s
	bart scale 2.0 tmp_M0 tmp_M0 # this scaling used to be bart of bart looklocker
	bart join 6 tmp_Ms tmp_M0 tmp_R1s tmp_reco_rescaled
else
	bart copy $reco tmp_reco_rescaled
fi



bart looklocker -t0.2 -D0.0153 tmp_reco_rescaled $t1map

