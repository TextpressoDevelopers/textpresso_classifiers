#!/usr/bin/env bash

source_dir=$1

for datatype in $(ls ${source_dir})
do
    if [ -d ${source_dir}/${datatype} ]
    then
        ./boost_classifier.py -t ${source_dir}/${datatype} -c ${source_dir}/${datatype}/model.pkl -f "cas_pdf"
    fi
done