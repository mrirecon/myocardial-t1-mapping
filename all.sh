#!/bin/bash
set -e

for i in `seq 1 8` ; do
	for j in a b c ; do

	prefix=vol_${i}-${j}

	echo $prefix

	./load.sh 3362387 ${prefix} ./data/
	./grid.sh data/${prefix} ${prefix}_psf2.coo ${prefix}_ksp2.coo > $prefix.log
	./prep.sh ind/${prefix}.txt ${prefix}_psf2.coo ${prefix}_ksp2.coo ${prefix}_TI.coo ${prefix}_psf.coo ${prefix}_ksp.coo
	./reco.sh ${prefix}_TI.coo ${prefix}_psf.coo ${prefix}_ksp.coo ${prefix}_reco.coo | tee -a $prefix.log
	./post.sh ${prefix}_reco.coo ${prefix}_t1map.coo

	done
done

