#!/usr/bin/env bash

function usage {
    echo "usage: $(basename $0) [-t] <models_dir> <data_dir> <list_of_filenames_to_classify>"
    echo "  -t --type                set the file type. Accepted values are pdf, cas_pdf or cas_xml"
    echo "  -h --help                display help"
    exit 1
}

MODELS_DIR=""
DATA_DIR=""
LIST_FILENAMES=""
FILE_TYPE="pdf"


models=("KNN" "SVM_LINEAR" "SVM_NONLINEAR" "TREE" "RF" "MLP" "NAIVEB" "GAUSS" "LDA" "XGBOOST")

while [[ $# -gt 0 ]]
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
    -n|--ngram-size)
    shift
    NGRAM_SIZE="$1"
    shift
    ;;
    -m|--max-features)
    shift
    MAX_FEATURES="$1"
    shift
    ;;
    -z|--tokenization-scheme)
    shift
    TOKENIZATION="$1"
    shift
    ;;
    -h|--help)
    usage
    ;;
    *)
    if [[ -d $key ]]
    then
        INPUT_DIR="$key"
    else
        usage
    fi
    shift
    ;;
esac
done

if [[ ${INPUT_DIR} == "" ]]
then
    usage
fi