#!/usr/bin/env bash

function usage {
    echo "usage: $(basename $0) <model_dir> <data_dir>"
    echo "  -h --help                display help"
    exit 1
}

if [[ "${#}" < 2 ]]
then
    usage
fi

model_dir=""
data_dir=""

while [[ $# -gt 1 ]]
do
key=$1

case $key in
    -h|--help)
    usage
    ;;
    *)
    if [[ -d $key ]]
    then
        model_dir="$key"
    else
        usage
    fi
    shift
    if [ -d $1 ]
    then
        data_dir=$1
    else
        usage
    fi
    shift
    ;;
esac
done

if [[ ${model_dir} == "" || ${data_dir} == "" ]]
then
    usage
fi

for datatype in $(ls ${model_dir})
do
    if [ -d ${model_dir}/${datatype} ]
    then
        ./boost_classifier.py -p ${data_dir}/${datatype}/vpos_tp -c ${model_dir}/${datatype}/model.pkl -f "cas_pdf" > ${data_dir}/${datatype}/prediction_vpos_tp.csv &
        ./boost_classifier.py -p ${data_dir}/${datatype}/vpos_fp -c ${model_dir}/${datatype}/model.pkl -f "cas_pdf" > ${data_dir}/${datatype}/prediction_vpos_fp.csv &
        ./boost_classifier.py -p ${data_dir}/${datatype}/vneg_tn -c ${model_dir}/${datatype}/model.pkl -f "cas_pdf" > ${data_dir}/${datatype}/prediction_vneg_tn.csv &
        ./boost_classifier.py -p ${data_dir}/${datatype}/vneg_fn -c ${model_dir}/${datatype}/model.pkl -f "cas_pdf" > ${data_dir}/${datatype}/prediction_vneg_fn.csv &
    fi
done
wait