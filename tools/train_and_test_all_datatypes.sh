#!/usr/bin/env bash

function usage {
    echo "usage: $(basename $0) [-t] <input_dir>"
    echo "  -t --type                set the file type. Accepted values are pdf or cas"
    echo "  -h --help                display help"
    echo "  -n --ngram-size          set the n-gram size"
    echo "  -m --max-features        set the maximum number of best features to be kept for feature selection"
    exit 1
}

INPUT_DIR=""
FILE_TYPE="pdf"
NGRAM_SIZE="2"
MAX_FEATURES="20000"

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
    NGRAM_SIZE="$key"
    shift
    ;;
    -m|--max-features)
    shift
    MAX_FEATURES="$key"
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

# remove previous results
echo -e "DATATYPE\tMODEL\tPRECISION\tRECALL\tACCURACY"

for datatype in $(ls ${INPUT_DIR})
do
    if [ -d ${INPUT_DIR}/${datatype} ]
    then
        for model in ${models[@]}
        do
          echo -e ${datatype}"\t"${model}"\t"$(tp_doc_classifier.py -t ${INPUT_DIR}/${datatype} -T -c ${INPUT_DIR}/${datatype}/${model}_test.pkl -f ${FILE_TYPE} -m ${model} -n ${NGRAM_SIZE} -b ${MAX_FEATURES} -z TFIDF)
        done
    fi
done