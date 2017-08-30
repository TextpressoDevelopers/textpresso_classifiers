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
    else
        usage
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

for datatype in $(ls ${INPUT_DIR})
do
    if [ -d ${INPUT_DIR}/${datatype} ]
    then
        ./boost_classifier.py -t ${INPUT_DIR}/${datatype} -c ${INPUT_DIR}/${datatype}/model.pkl -f ${FILE_TYPE} &
    fi
done
wait