#!/bin/bash
#set -e

usage="Usage: $0 <input> <outpsf> <outksp>"

if [ $# -lt 3 ] ; then

        echo "$usage" >&2
        exit 1
fi

export PATH=$TOOLBOX_PATH:$PATH


input=$(readlink -f "$1")
outpsf=$(readlink -f "$2")
outksp=$(readlink -f "$3")

if [ ! -e ${input}.cfl ] ; then
        echo "Input file does not exist." >&2
        echo "$usage" >&2
        exit 1
fi

if [ ! -e $TOOLBOX_PATH/bart ] ; then
        echo "\$TOOLBOX_PATH is not set correctly!" >&2
        exit 1
fi


#WORKDIR=$(mktemp -d)
# Mac: http://unix.stackexchange.com/questions/30091/fix-or-alternative-for-mktemp-in-os-x
WORKDIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
trap 'rm -rf "$WORKDIR"' EXIT
cd $WORKDIR


# read data

samples=512
grid=640
GA=9
nf=1
og=1.25
nspokes=1530
nf1=90
nspokes1=17


# reshape data
bart transpose 1 4 $input ksp_4s_trans
bart reshape $(bart bitmask 4 10) $nspokes $nf ksp_4s_trans ksp_4s_reshape
bart transpose 1 4 ksp_4s_reshape ksp2
# data preparation: switch dimensions to work with nufft tools
bart transpose 1 2 ksp2 temp
bart transpose 0 1 temp dataT

bart extract 2 1299 1529 dataT dataT_extract
bart flip $(bart bitmask 2) dataT_extract dataT_extract_flip


bart traj -D -r -x$samples -y$nspokes -s$GA -G -t$nf traj
#bart traj -D -r -x$samples -y$nspokes -n$GA -G -t$nf traj
bart extract 2 1299 1529 traj traj_extract 
bart flip $(bart bitmask 2) traj_extract traj_extract_flip 

# output gradient delays
bart estdelay traj_extract_flip dataT_extract_flip


bart transpose 2 4 dataT dataT_trans
bart reshape $(bart bitmask 4 10) $nspokes1 $nf1 dataT_trans dataT_reshape
bart transpose 2 4 dataT_reshape dataT_final

# compute corrected trajectory
bart traj -D -r -x$samples -y$nspokes1 -s$GA -G -t$nf1 -q $(bart estdelay traj_extract_flip dataT_extract_flip) trajn
#bart traj -D -r -x$samples -y$nspokes1 -n$GA -G -t$nf1 -q $(bart estdelay traj_extract_flip dataT_extract_flip) trajn

# oversampling
bart scale $og trajn trajs

bart transpose 5 10 trajs traj

# gridding of psf
bart ones 6 1 $samples $nspokes1 1 1 $nf1 ones 
bart nufft -d $grid:$grid:1 -a traj ones nufft
bart fft -u 3 nufft psf_tmp
bart scale 0.1 psf_tmp $outpsf

# gridding of the data
beg=0
fin=89
for i in `seq $beg $fin`
do
        bart slice 10 $i dataT_final tempd
        bart slice 5 $i traj tempt
        bart nufft -d $grid:$grid:1 -a tempt tempd nufft_k_tmp
        bart fft -u 3 nufft_k_tmp data_$i
done

bart join 5 `seq -f "data_%g" $beg $fin` ksp_final 

# coil compression
bart cc -A -p 10 ksp_final $outksp 
