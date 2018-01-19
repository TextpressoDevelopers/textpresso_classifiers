#!/usr/bin/env bash

function usage {
    echo "usage: $(basename $0) [-t] <input_dir>"
    echo "  -t --type                set the file type. Accepted values are pdf or cas"
    echo "  -n --ngram-size          set the n-gram size"
    echo "  -m --max-features        set the maximum number of best features to be kept for feature selection"
    echo "  -z --tokenization-scheme type of tokenization to apply to extract the feature set. Accepted values are TFIDF or BOW (Bag of Words)"
    echo "  -h --help                display help"
    exit 1
}

INPUT_DIR=""
FILE_TYPE="pdf"
NGRAM_SIZE="2"
MAX_FEATURES="20000"
TOKENIZATION="TFIDF"

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
    FILE_TYPE="$1"
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

for datatype in $(ls ${INPUT_DIR})
do
    if [ -d ${INPUT_DIR}/${datatype} ]
    then
        for model in ${models[@]}
        do
            tp_doc_classifier.py -t ${INPUT_DIR}/${datatype} -c ${INPUT_DIR}/${datatype}/${model}.pkl -f ${FILE_TYPE} -m ${model} -n ${NGRAM_SIZE} -b ${MAX_FEATURES} -z ${TOKENIZATION} &
        done
    fi
    wait
done
wait