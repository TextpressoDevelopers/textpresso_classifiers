#!/usr/bin/env bash

function usage {
    echo "usage: $(basename $0) [-t] <model_dir> <data_dir>"
    echo "  -t --type                set the file type. Accepted values are pdf, cas or txt"
    echo "  -h --help                display help"
    echo "  -w --wait-after-model    parallelize execution only for one model at a time"
    exit 1
}

if [[ "${#}" < 2 ]]
then
    usage
fi

model_dir=""
data_dir=""
FILE_TYPE="pdf"
models=("KNN" "SVM_LINEAR" "SVM_NONLINEAR" "TREE" "RF" "MLP" "NAIVEB" "GAUSS" "LDA" "XGBOOST")
wait_after_model="false"

while [[ $# -gt 1 ]]
do
key=$1

case $key in
    -h|--help)
    usage
    ;;
    -t|--type)
    shift
    FILE_TYPE="$1"
    shift
    ;;
    -w|--wait-after-model)
    wait_after_model="true"
    shift
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
        for model in ${models[@]}
        do
            mkdir -p ${data_dir}/${datatype}/${model}
            tp_doc_classifier.py -p ${data_dir}/${datatype}/valp_tp -c ${model_dir}/${datatype}/${model}.pkl -m ${model} -f ${FILE_TYPE} > ${data_dir}/${datatype}/${model}/prediction_valp_tp.csv &
            tp_doc_classifier.py -p ${data_dir}/${datatype}/valp_fp -c ${model_dir}/${datatype}/${model}.pkl -m ${model} -f ${FILE_TYPE} > ${data_dir}/${datatype}/${model}/prediction_valp_fp.csv &
            tp_doc_classifier.py -p ${data_dir}/${datatype}/valn_tn -c ${model_dir}/${datatype}/${model}.pkl -m ${model} -f ${FILE_TYPE} > ${data_dir}/${datatype}/${model}/prediction_valn_tn.csv &
            tp_doc_classifier.py -p ${data_dir}/${datatype}/valn_fn -c ${model_dir}/${datatype}/${model}.pkl -m ${model} -f ${FILE_TYPE} > ${data_dir}/${datatype}/${model}/prediction_valn_fn.csv &
            if [[ ${wait_after_model} == "true" ]]
            then
                wait
            fi
        done
    fi
done
wait