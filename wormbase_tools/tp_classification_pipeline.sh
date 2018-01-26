#!/usr/bin/env bash

function usage {
    echo "classify cas files into different data types. Models dir must contain a model for each data type, named "
    echo "<datatype>.pkl (lowercase). The data dir must contain two sub-folders: 'PMCOA' and 'C. elegans', "
    echo "each of which must contain sub-forlders with paper names, with cas files in them."
    echo ""
    echo "usage: $(basename $0)      <models_dir> <data_dir> <output_dir>"
    echo "  -h --help                display help"
    exit 1
}

MODELS_DIR=""
DATA_DIR=""
OUTPUT_DIR=""

datatypes=("antibody" "catalyticact" "expression_cluster" "geneint" "geneprod" "genereg" "newmutant" "otherexpr" \
"overexpr" "rnai" "seqchange" "structcorr")
filetypes=("C. elegans" "PMCOA")

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
    if [[ -d $key ]]
    then
        OUTPUT_DIR="$key"
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

mkdir -p "${OUTPUT_DIR}/C. elegans/tmp"
touch "${OUTPUT_DIR}/C. elegans/already_classified.csv"
mkdir -p "${OUTPUT_DIR}/PMCOA/tmp"
touch "${OUTPUT_DIR}/PMCOA/already_classified.csv"

for filetype in $filetypes[@]
do
    if [[ ${filetype} == "C. elegans" ]]
    then
        cas_type="cas_pdf"
    else
        cas_type="cas_xml"
    fi
    for datatype in $datatypes[@]
    do
        diff <(ls "${DATA_DIR}/${filetype}") <(cat "${OUTPUT_DIR}/${filetype}/already_classified.csv") | grep "^< " | sed 's/< //g' > "${OUTPUT_DIR}/${filetype}/tobeclassified.csv"
        num_papers=0
        cat "${OUTPUT_DIR}/${filetype}/tobeclassified.csv" | while read line
        do
            find "${DATA_DIR}/${filetype}/${line}/" -name "*.tpcas.gz" | xargs -I {} cp {} "${OUTPUT_DIR}/${filetype}/tmp/${line}.tpcas.gz"
            if [[ ${filetype} == "C. elegans" ]]
            then
                ls "${DATA_DIR}/C. elegans Supplementals/${line}"* | while read sup
                do
                    find "$sup" -name "*.tpcas.gz" | xargs -I {} cp {} "${OUTPUT_DIR}/${filetype}/tmp/${sup}.tpcas.gz"
                done
            fi
            find "${OUTPUT_DIR}/${filetype}/tmp/" -name "${line}*.tpcas.gz" | xargs -I {} sh -c 'convert_to_txt.py -f ${cas_type} "{}" > "${OUTPUT_DIR}/${filetype}/tmp/$(echo {} | sed 's/.tpcas.gz/.txt/g')"'
            find "${OUTPUT_DIR}/${filetype}/tmp/" -name "${line}*.tpcas.gz" | xargs rm
            cat "${OUTPUT_DIR}/${filetype}/tmp/${line}"* > "${OUTPUT_DIR}/${filetype}/tmp/${line}.concat.txt"
            find "${OUTPUT_DIR}/${filetype}/tmp/" -name "${line}*.txt" | grep -v ".concat.txt" | xargs rm
            if [[ $(echo "${num_papers}%1000" | bc) == "0" ]]
            echo ${line} >> "${OUTPUT_DIR}/${filetype}/already_classified.csv"
            then
                tp_doc_classifier.py -c ${MODELS_DIR}/${datatype}.pkl -p "${OUTPUT_DIR}/${filetype}/tmp" -f ${cas_type} >> "${OUTPUT_DIR}/${filetype}/$(date "+%m-%d-%Y").csv"
                rm -rf "${OUTPUT_DIR}/${filetype}/tmp"
            fi
        done
        tp_doc_classifier.py -c ${MODELS_DIR}/${datatype}.pkl -p "${DATA_DIR}/${filetype}/tmp" -f ${cas_type} >> "${OUTPUT_DIR}/${filetype}/$(date "+%m-%d-%Y").csv"
        rm -rf "${OUTPUT_DIR}/${filetype}/tmp"
    done
done