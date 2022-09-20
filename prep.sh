#!/bin/bash
set -e

if [ ! -e $TOOLBOX_PATH/bart ] ; then
        echo "\$TOOLBOX_PATH is not set correctly!" >&2
        exit 1
fi
export PATH=$TOOLBOX_PATH:$PATH
export BART_COMPAT_VERSION="v0.5.00"

usage="Usage: $0 <index> <ipsf> <iksp> <TI> <psf> <ksp>"

if [ $# -lt 6 ] ; then

        echo "$usage" >&2
        exit 1
fi

index=$(readlink -f "$1")
ipsf=$(readlink -f "$2")
iksp=$(readlink -f "$3")
TI=$(readlink -f "$4")
psf=$(readlink -f "$5")
ksp=$(readlink -f "$6")


if [ ! -e $index ] ; then
        echo "Input file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e $ipsf ] ; then
        echo "Input file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e $iksp ] ; then
        echo "Input file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

dir=$(pwd)

#WORKDIR=$(mktemp -d)
# Mac: http://unix.stackexchange.com/questions/30091/fix-or-alternative-for-mktemp-in-os-x
WORKDIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
trap 'rm -rf "$WORKDIR"' EXIT
cd $WORKDIR


# calculate inversion times

TR=2670
num=90
spokes=17

bart index 5 $num tmp1.coo
# use local index from newer bart with older bart
#./index 5 $num tmp1.coo
bart scale $(($spokes * $TR)) tmp1.coo tmp2.coo
bart ones 6 1 1 1 1 1 $num tmp1.coo 
bart saxpy $((($spokes / 2) * $TR)) tmp1.coo tmp2.coo tmp3.coo
bart scale 0.000001 tmp3.coo TI1.coo
rm tmp1.coo tmp2.coo tmp3.coo

# extract the frames of interest

n=0

while read line ; do
	bart slice 5 $line $ipsf psf-${n}.coo
	bart slice 5 $line $iksp ksp-${n}.coo
	bart slice 5 $line TI1.coo TI-${n}.coo
	n=$(($n+1))
done < $index

bart join 5 $(seq -f "psf-%g.coo" 0 $(($n-1))) psf_i
bart join 5 $(seq -f "ksp-%g.coo" 0 $(($n-1))) $ksp
bart join 5 $(seq -f "TI-%g.coo" 0 $(($n-1))) $TI

rm TI-*.coo ksp-*.coo psf-*.coo

bart scale 2. psf_i $psf



