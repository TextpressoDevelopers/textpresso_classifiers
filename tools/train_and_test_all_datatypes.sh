#!/usr/bin/env bash

function usage {
    echo "usage: $(basename $0) [-t] <input_dir>"
    echo "  -t --type                set the file type. Accepted values are pdf or cas"
    echo "  -h --help                display help"
    exit 1
}

INPUT_DIR=""
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
echo -e "datatype\tprecision\trecall\taccuracy" > ${INPUT_DIR}/results.txt

for datatype in $(ls ${INPUT_DIR})
do
    if [ -d ${INPUT_DIR}/${datatype} ]
    then
        paste <(echo ${datatype}) <(../programs/tpclassifier.py -t ${INPUT_DIR}/${datatype} -T -c ${INPUT_DIR}/${datatype}/model.pkl -f ${FILE_TYPE}) >> ${INPUT_DIR}/${datatype}/results.txt &
    fi
done
wait
for datatype in $(ls ${INPUT_DIR})
do
    cat ${INPUT_DIR}/${datatype}/results.txt >> ${INPUT_DIR}/results.txt
    rm ${INPUT_DIR}/${datatype}/results.txt
done