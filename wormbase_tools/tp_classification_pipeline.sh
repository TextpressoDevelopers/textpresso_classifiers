#!/usr/bin/env bash

function usage {
    echo "classify cas files into different data types. Models dir must contain a model for each data type, named "
    echo "<datatype>.pkl (lowercase). The data dir must contain two sub-folders: 'PMCOA' and 'C. elegans', "
    echo "each of which must contain sub-forlders with paper names, with cas files in them."
    echo ""
    echo "usage: $(basename $0)      <models_dir> <data_dir>"
    echo "  -h --help                display help"
    exit 1
}

MODELS_DIR=""
DATA_DIR=""
FILE_TYPE=""

datatypes=("antibody" "catalyticact" "expression_cluster" "geneint" "geneprod" "genereg" "newmutant" "otherexpr" \
"overexpr" "rnai" "seqchange" "structcorr")

while [[ $# -gt 0 ]]
do
key=$1

case $key in
    -h|--help)
    usage
    ;;
    *)
    if [[ -d $key ]]
    then
        MODELS_DIR="$key"
    else
        usage
    fi
    shift
    if [[ -d $key ]]
    then
        DATA_DIR="$key"
    else
        usage
    fi
    shift
    ;;
esac
done

if [[ ${MODELS_DIR} == "" || ${DATA_DIR} == "" ]]
then
    usage
fi

#

for datatype in $datatypes[@]
do
    tp_doc_classifier.py -c ${MODELS_DIR}/${datatype}.pkl -p /
done