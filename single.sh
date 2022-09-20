#!/bin/bash
set -e

if [ $# -eq 0 ]; then
	vols=1
else
	vols=$*
fi

scans=(a b c)

REPO_NAME=myocardial-t1-mapping

if [ ! -d ${DATA_ARCHIVE}/${REPO_NAME} ] ; then

	for i in ${vols[@]} ; do
		for j in ${scans[@]} ; do

			prefix=vol_${i}-${j}
			./load.sh 3362387 ${prefix} ./data/
		done
	done
	export DATA_LOC=./data
else
	export DATA_LOC=${DATA_ARCHIVE}/${REPO_NAME}
fi

for i in ${vols[@]} ; do
	for j in ${scans[@]} ; do

		prefix=vol_${i}-${j}

		echo $prefix

		./grid.sh ${DATA_LOC}/${prefix} ${prefix}_psf2.coo ${prefix}_ksp2.coo > $prefix.log
		./prep.sh ind/${prefix}.txt ${prefix}_psf2.coo ${prefix}_ksp2.coo ${prefix}_TI.coo ${prefix}_psf.coo ${prefix}_ksp.coo
		./reco.sh ${prefix}_TI.coo ${prefix}_psf.coo ${prefix}_ksp.coo ${prefix}_reco.coo | tee -a $prefix.log
		./post.sh ${prefix}_reco.coo ${prefix}_t1map.coo

	done
done

