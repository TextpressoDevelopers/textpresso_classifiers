#!/usr/bin/env bash

model_dir=$1
prediction_dir=$2

for datatype in $(ls ${model_dir})
do
    if [ -d ${model_dir}/${datatype} ]
    then
        ./boost_classifier.py -p ${prediction_dir}/${datatype}/positive -c ${model_dir}/${datatype}/model.pkl -f "cas_pdf" > ${prediction_dir}/${datatype}/prediction_positive.csv &
        ./boost_classifier.py -p ${prediction_dir}/${datatype}/negative -c ${model_dir}/${datatype}/model.pkl -f "cas_pdf" > ${prediction_dir}/${datatype}/prediction_negative.csv &
    fi
done
wait