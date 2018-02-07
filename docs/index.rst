.. tpclassifier documentation master file, created by
   sphinx-quickstart on Mon Dec 11 12:51:43 2017.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

Welcome to Textpresso Classifiers Module documentation!
=============================================================

textpresso_classifiers is a Python package to train and apply
document classifiers to scientific papers, both in the form of pdf files and
Textpresso Central documents
(`CAS <https://uima.apache.org/d/uimaj-2.4.0/tutorials_and_users_guides.html#ugr.tug.aae>`_
format).

The package contains a Python library with classes to create and manage
classifiers based on several supervised learning models. Specifically, the
library provides a simplified interface to the models and gives a set of
utilities to process the data needed to feed the models. For example, the
library exposes functions to perform feature extraction and feature selection
from data obtained from different file formats (pdf and CAS), which are
automatically converted to plain text and used to create the feature sets.

The library currently supports the following classifiers:

- SVM (both linear and non-linear)
- Linear Discriminant Analysis
- Gaussian process
- Naive Bayes
- XGBoost
- Decision Tree
- Random Forest
- K-Nearest Neighbors
- Multi-Layer Perceptrons (Neural Network)
- Radial Basis Function Neural Network

Feature extraction in TCM allows the user to apply several text pre-processing
phases (e.g., lemmatization, n-gram extraction). Feature selection is based
on the chi-squared method.
  
TCM is based on `scikit-learn <http://scikit-learn.org/stable/>`_ Python
library.

.. toctree::
   :maxdepth: 2

   classifiers
   utilities
   programs

