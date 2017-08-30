"""Utilities to manage PDF files"""

import PyPDF2

__author__ = "Valerio Arnaboldi"

__version__ = "1.0.1"


def extract_text_from_pdf(file_path: str):
    """extract the fulltext of an article from a Textpresso cas file

    :param file_path: the path to the pdf file
    :type file_path: str
    :return: the fulltext of the article represented by the cas file
    :rtype: str
    """
    fulltext = ""
    pdfFileObj = open(file_path, 'rb')
    try:
        pdfReader = PyPDF2.PdfFileReader(pdfFileObj)
    except:
        return None
    for i in range(pdfReader.numPages):
        pageObj = pdfReader.getPage(i)
        try:
            fulltext += pageObj.extractText()
        except:
            pass
    return fulltext
