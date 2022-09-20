#!/bin/bash
set -e

if [ ! -e $TOOLBOX_PATH/bart ] ; then
        echo "\$TOOLBOX_PATH is not set correctly!" >&2
        exit 1
fi
export PATH=$TOOLBOX_PATH:$PATH
export BART_COMPAT_VERSION="v0.5.00"

usage="Usage: $0 <TI> <psf> <ksp> <output>"

if [ $# -lt 4 ] ; then

        echo "$usage" >&2
        exit 1
fi


TI=$(readlink -f "$1")
psf=$(readlink -f "$2")
ksp=$(readlink -f "$3")
reco=$(readlink -f "$4")

lambda=0.0015

if [ ! -e $TI ] ; then
        echo "Input file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e $psf ] ; then
        echo "Input file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e $ksp ] ; then
        echo "Input file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if ./utils/version_check.sh ; then
	ADD_OPTS="--normalize_scaling --other pinit=1:1:1.5:1 --scale_data 5000 --scale_psf 1000 --no_alpha_min_exp_decay"
else
	ADD_OPTS=""
fi
echo $ADD_OPTS

NONEXP_FLAG=""
if bart version -t v0.7.00 ; then
	NONEXP_FLAG="--no_alpha_min_exp_decay"
fi

#WORKDIR=$(mktemp -d)
# Mac: http://unix.stackexchange.com/questions/30091/fix-or-alternative-for-mktemp-in-os-x
WORKDIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
trap 'rm -rf "$WORKDIR"' EXIT
cd $WORKDIR


# model-based T1 reconstruction:

START=$(date +%s)

NONEXP_FLAG=""
if bart version -t v0.7.00 ; then
	NONEXP_FLAG="--no_alpha_min_exp_decay"
fi

which bart
bart version
#bart moba $NONEXP_FLAG $ADD_OPTS   -L -i10 -C300 -s0.475 -B0.3 -d4 -R3 -j$lambda -N -p $psf $ksp $TI reco sens

# GPU:
bart moba $NONEXP_FLAG $ADD_OPTS -g -L -i10 -C300 -s0.475 -B0.3 -d4 -R3 -j$lambda -N -p $psf $ksp $TI reco sens

END=$(date +%s)
DIFF=$(($END - $START))
echo "It took $DIFF seconds"

bart resize -c 0 256 1 256 reco $reco


