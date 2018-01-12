Executable programs included in TCM
===================================

In addition to the Python library, TCM includes a set of executable programs to train, test and apply Textpresso
document classifiers directly from the command line. For a more detailed documentation of these programs, and to see
some example use cases, go to the github [wiki of the project](https://github.com/valearna/tpclassifer/wiki).

tp_doc_classifier.py
####################

This program can be used to train a document classifier with a set of positive and a set of negative pdf or CAS
documents. The trained model is stored by the program in a pickle file that can then be used to apply the classifier to
a set of new files.

classifiers_comparison.py
#########################

This program can be used to train different classifiers and test their performances.

