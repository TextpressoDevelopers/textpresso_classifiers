#!/usr/bin/env bash

function usage {
    echo "usage: $(basename $0) [-t] <model_dir> <data_dir>"
    echo "  -t --type                set the file type. Accepted values are pdf or cas"
    echo "  -h --help                display help"
    exit 1
}

if [[ "${#}" < 2 ]]
then
    usage
fi

model_dir=""
data_dir=""
FILE_TYPE="pdf"

while [[ $# -gt 1 ]]
do
key=$1

case $key in
    -h|--help)
    usage
    ;;
    -t|--type)
    shift
    if [[ $1 == "pdf" ]]
    then
        FILE_TYPE="pdf"
    elif [[ $1 == "cas_pdf" ]]
    then
        FILE_TYPE="cas_pdf"
    elif [[ $1 == "cas_xml" ]]
    then
        FILE_TYPE="cas_xml"
    fi
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
        ./boost_classifier.py -p ${data_dir}/${datatype}/valp_tp -c ${model_dir}/${datatype}/model.pkl -f ${FILE_TYPE} > ${data_dir}/${datatype}/prediction_valp_tp.csv &
        ./boost_classifier.py -p ${data_dir}/${datatype}/valp_fp -c ${model_dir}/${datatype}/model.pkl -f ${FILE_TYPE} > ${data_dir}/${datatype}/prediction_valp_fp.csv &
        ./boost_classifier.py -p ${data_dir}/${datatype}/valn_tn -c ${model_dir}/${datatype}/model.pkl -f ${FILE_TYPE} > ${data_dir}/${datatype}/prediction_valn_tn.csv &
        ./boost_classifier.py -p ${data_dir}/${datatype}/valn_fn -c ${model_dir}/${datatype}/model.pkl -f ${FILE_TYPE} > ${data_dir}/${datatype}/prediction_valn_fn.csv &
    fi
done
wait