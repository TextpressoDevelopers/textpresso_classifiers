#!/usr/bin/env bash

model_dir=$1
prediction_dir=$2

for datatype in $(ls ${model_dir})
do
    if [ -d ${model_dir}/${datatype} ]
    then
        ./boost_classifier.py -p ${prediction_dir}/${datatype}/vpos_tp -c ${model_dir}/${datatype}/model.pkl -f "cas_pdf" > ${prediction_dir}/${datatype}/prediction_vpos_tp.csv &
        ./boost_classifier.py -p ${prediction_dir}/${datatype}/vpos_fp -c ${model_dir}/${datatype}/model.pkl -f "cas_pdf" > ${prediction_dir}/${datatype}/prediction_vpos_fp.csv &
        ./boost_classifier.py -p ${prediction_dir}/${datatype}/vneg_tn -c ${model_dir}/${datatype}/model.pkl -f "cas_pdf" > ${prediction_dir}/${datatype}/prediction_vneg_tn.csv &
        ./boost_classifier.py -p ${prediction_dir}/${datatype}/vneg_fn -c ${model_dir}/${datatype}/model.pkl -f "cas_pdf" > ${prediction_dir}/${datatype}/prediction_vneg_fn.csv &
    fi
done
wait