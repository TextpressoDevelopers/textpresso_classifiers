#!/usr/bin/env python3

"""Classify Textpresso documents into categories using a svm classifier"""

import argparse
import textpresso_classifiers.fileutils
from textpresso_classifiers import CasType

__author__ = "Valerio Arnaboldi"

__version__ = "1.0.1"


def main():
    parser = argparse.ArgumentParser(description="Convert documents from pdf or CAS format to plain text")
    parser.add_argument("-f", "--from", metavar="type_from", dest="type_from", type=str, default="pdf",
                        choices=["pdf", "cas_pdf", "cas_xml"], help="type of files to be processed")
    parser.add_argument('input_file', help='single document file to be converted')

    args = parser.parse_args()
    if args.type_from == "pdf":
        print(textpresso_classifiers.fileutils.extract_text_from_pdf(args.input_file))
    elif args.type_from == "cas_pdf" or args.type_from == "cas_xml":
        if args.type_from == "cas_pdf":
            cas_type = CasType.PDF
        else:
            cas_type = CasType.XML
        print(textpresso_classifiers.fileutils.extract_text_from_cas_content(textpresso_classifiers.fileutils.read_compressed_cas_content(
            args.input_file), cas_type=cas_type))

    else:
        raise Exception("wrong input file format")


if __name__ == '__main__':
    main()
