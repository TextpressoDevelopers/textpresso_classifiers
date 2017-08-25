#!/usr/bin/env bash

source_dir=$1

# remove previous results
echo -e "datatype\tprecision\trecall\taccuracy" > ${source_dir}/results.txt

for datatype in $(ls ${source_dir})
do
    if [ -d ${source_dir}/${datatype} ]
    then
        paste <(echo ${datatype}) <(./boost_classifier.py -t ${source_dir}/${datatype} -T -c ${source_dir}/${datatype}/model.pkl -f "cas_pdf") >> ${source_dir}/results.txt
    fi
done