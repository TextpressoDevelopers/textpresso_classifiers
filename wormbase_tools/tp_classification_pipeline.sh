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
"overexpr" "rnai" "seqchange")
filetypes=("C. elegans")

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
    OUTPUT_DIR="$key"
    shift
    ;;
esac
done

if [[ ${MODELS_DIR} == "" || ${DATA_DIR} == "" ]]
then
    usage
fi

for filetype in "${filetypes[@]}"
do
    mkdir -p "${OUTPUT_DIR}/${filetype}/tmp"
    touch "${OUTPUT_DIR}/${filetype}/already_classified.csv"
    if [[ ${filetype} == "C. elegans" ]]
    then
        cas_type="cas_pdf"
    else
        cas_type="cas_xml"
    fi
    diff <(ls "${DATA_DIR}/${filetype}") <(cat "${OUTPUT_DIR}/${filetype}/already_classified.csv") | grep "^< " | sed 's/< //g' > "${OUTPUT_DIR}/${filetype}/tobeclassified.csv"
    num_papers=1
    cat "${OUTPUT_DIR}/${filetype}/tobeclassified.csv" | while read line
    do
        mkdir -p "${OUTPUT_DIR}/${filetype}/tmp"
        find "${DATA_DIR}/${filetype}/${line}/" -name "*.tpcas.gz" | xargs -I {} cp {} "${OUTPUT_DIR}/${filetype}/tmp/${line}.tpcas.gz"
        if [[ ${filetype} == "C. elegans" ]]
        then
            find "${DATA_DIR}/C. elegans Supplementals/" -mindepth 1 -maxdepth 1 -name "${line}*" | while read sup
            do
                find "$sup" -name "*.tpcas.gz" | xargs -I {} cp "{}" "${OUTPUT_DIR}/${filetype}/tmp/"
            done
        fi
        find "${OUTPUT_DIR}/${filetype}/tmp/" -name "${line}*.tpcas.gz" | xargs -I {} sh -c 'filename=$(echo {} | rev | cut -d "/" -f 1 | rev); convert_doc_to_txt.py -f $1 "{}" > "$0/$2/tmp/$(echo $filename | sed 's/.tpcas.gz/.txt/g')"' "${OUTPUT_DIR}" "${cas_type}" "${filetype}"
        find "${OUTPUT_DIR}/${filetype}/tmp/" -name "${line}*.tpcas.gz" | xargs -I {} rm "{}"
        cat "${OUTPUT_DIR}/${filetype}/tmp/${line}"* > "${OUTPUT_DIR}/${filetype}/tmp/${line}.concat.txt"
        find "${OUTPUT_DIR}/${filetype}/tmp/" -name "${line}*.txt" | grep -v ".concat.txt" | xargs -I {} rm "{}"
        echo ${line} >> "${OUTPUT_DIR}/${filetype}/already_classified.csv"
        if [[ $(echo "${num_papers}%1000" | bc) == "0" ]]
        then
            today_dir=$(echo "${OUTPUT_DIR}/${filetype}/"$(date "+%m-%d-%Y"))
            mkdir -p "${today_dir}"
            for datatype in "${datatypes[@]}"
            do
                model_type=$(ls "${MODELS_DIR}/${datatype}"*.pkl | head -n1 | awk -F "/" '{print $NF}' | sed "s/${datatype}_//g;s/.pkl//g")
                tp_doc_classifier.py -c "${MODELS_DIR}/${datatype}_${model_type}.pkl" -p "${OUTPUT_DIR}/${filetype}/tmp" -f txt -m "${model_type}" >> "${OUTPUT_DIR}/${filetype}/"$(date "+%Y-%W")"/${datatype}.csv"
            done
            rm -rf "${OUTPUT_DIR}/${filetype}/tmp"
        fi
        num_papers=$((num_papers + 1))
    done
    for datatype in "${datatypes[@]}"
    do
        model_type=$(ls "${MODELS_DIR}/${datatype}"*.pkl | head -n1 | awk -F "/" '{print $NF}' | sed "s/${datatype}_//g;s/.pkl//g")
        tp_doc_classifier.py -c "${MODELS_DIR}/${datatype}_${model_type}.pkl" -p "${OUTPUT_DIR}/${filetype}/tmp" -f txt -m "${model_type}" >> "${OUTPUT_DIR}/${filetype}/"$(date "+%Y-%W")"/${datatype}.csv"
    done
    rm -rf "${OUTPUT_DIR}/${filetype}/tmp"
    rm "${OUTPUT_DIR}/${filetype}/tobeclassified.csv"
done