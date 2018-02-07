#!/usr/bin/env bash

### extract svm predictions from curation status form and save the results for each data type to a different file

function usage {
    echo "usage: $(basename $0) <output_dir>"
    echo "  -h --help            display help"
    exit 1
}

OUTPUT_DIR=""

while [[ $# -gt 0 ]]
do
key=$1

case $key in
    -h|--help)
    usage
    ;;
    *)
    OUTPUT_DIR="$key"
    shift
    ;;
esac
done

if [[ ${OUTPUT_DIR} == "" ]]
then
    usage
fi

mkdir -p ${OUTPUT_DIR}

datatypes=("antibody" "catalyticact" "expression_cluster" "geneint" "geneprod" "genereg" "newmutant" "otherexpr" \
"overexpr" "rnai" "seqchange" "structcorr")

for datatype in ${datatypes[@]}
do
    wget "http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two736&listDatatype=${datatype}&method=svm%20pos&checkbox_svm=on" -qO- | sed 's/<br\/>/\n/g' | grep "name=\"specific_papers" | grep "name=\"specific_papers" | sed 's/<textarea rows="4" cols="80" name="specific_papers">//g;s/<\/textarea>//g;s/ /\n/g' | awk 'BEGIN{OFS="\t"}{print $0, 1}' > ${OUTPUT_DIR}/${datatype}.txt
    wget "http://tazendra.caltech.edu/~postgres/cgi-bin/curation_status.cgi?action=listCurationStatisticsPapersPage&select_datatypesource=caltech&select_curator=two736&listDatatype=${datatype}&method=svm%20neg&checkbox_svm=on" -qO- | sed 's/<br\/>/\n/g' | grep "name=\"specific_papers" | grep "name=\"specific_papers" | sed 's/<textarea rows="4" cols="80" name="specific_papers">//g;s/<\/textarea>//g;s/ /\n/g' | awk 'BEGIN{OFS="\t"}{print $0, 0}' >> ${OUTPUT_DIR}/${datatype}.txt
    sort -k1,1 ${OUTPUT_DIR}/${datatype}.txt -o ${OUTPUT_DIR}/${datatype}.txt
done