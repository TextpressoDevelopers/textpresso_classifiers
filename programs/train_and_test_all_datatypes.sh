#!/usr/bin/env bash

source_dir=$1

# remove previous results
echo -e "datatype\tprecision\trecall\taccuracy" > ${source_dir}/results.txt

for datatype in $(ls ${source_dir})
do
    if [ -d ${source_dir}/${datatype} ]
    then
        paste <(echo ${datatype}) <(./boost_classifier.py -t ${source_dir}/${datatype} -T -c ${source_dir}/${datatype}/model.pkl -f "pdf") >> ${source_dir}/${datatype}/results.txt &
    fi
done
wait
for datatype in $(ls ${source_dir})
do
    cat ${source_dir}/${datatype}/results.txt >> ${source_dir}/results.txt
    rm ${source_dir}/${datatype}/results.txt
done