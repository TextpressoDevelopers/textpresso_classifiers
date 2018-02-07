"""Utilities to transform pdf and CAS files into feature vectors for the classifiers"""

import html
import re
import gzip
import xml.etree.ElementTree as ET
from enum import Enum
import PyPDF2

__author__ = "Valerio Arnaboldi"

__version__ = "1.0.1"


class CasType(Enum):
    """type of cas file"""
    PDF = 1
    XML = 2


def read_compressed_cas_content(file_path: str):
    """read a compressed cas file and return its content as a string

    :param file_path the path to the compressed cas file
    :type file_path str
    :return the content of the compressed cas file
    :rtype str
    """
    with gzip.open(file_path, 'rt') as file:
        return file.read()


def extract_text_from_cas_content(cas_content: str, cas_type: CasType = 1):
    """extract the fulltext of an article from a Textpresso cas file

    :param cas_content: the content of the cas file
    :type cas_content: str
    :param cas_type: the type of cas file
    :type cas_type: CasType
    :return: the fulltext of the article represented by the cas file
    :rtype: str
    """
    re_res = re.search("sofaString=\"(.*)\"/>", cas_content)
    fulltext = html.unescape(re_res.group(1))
    if cas_type == CasType.PDF:
        fulltext = remove_pdf_tags_from_text(fulltext)
    elif cas_type == CasType.XML:
        fulltext = extract_text_from_article_xml(fulltext)
    fulltext = re.sub("\s+", " ", fulltext).strip()
    return fulltext


def remove_pdf_tags_from_text(text: str):
    """remove pdf tags from text

    :param text: the text of an article possibly containing pdf tags
    :type text: str
    :return: the text of the article without pdf tags
    :rtype: str
    """
    filtered_text = re.sub("<_pdf(.*)/>", "", text)
    return filtered_text


def extract_text_from_article_xml(text: str):
    """extract the text of an article from its xml representation (in pubmed format)

    :param text the xml text of the article in pubmed format
    :type text str
    :return: the fulltext of the article
    :rtype: str
    """
    root = ET.fromstring(text)
    for child in root:
        if child.tag == "body":
            return "".join(child.itertext())


def extract_text_from_pdf(file_path: str):
    """extract the fulltext of an article from a pdf file

    :param file_path: the path to the pdf file
    :type file_path: str
    :return: the fulltext of the article represented by the cas file
    :rtype: str
    """
    fulltext = ""
    pdfFileObj = open(file_path, 'rb')
    try:
        pdfReader = PyPDF2.PdfFileReader(pdfFileObj)
        for i in range(pdfReader.numPages):
            pageObj = pdfReader.getPage(i)
            fulltext += pageObj.extractText()
        return fulltext
    except:
        return None