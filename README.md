[![Build Status](https://travis-ci.org/valearna/tpclassifier.svg?branch=master)](https://travis-ci.org/valearna/tpclassifier) [![Coverage Status](https://coveralls.io/repos/github/valearna/tpclassifier/badge.svg?branch=master&service=github)](https://coveralls.io/github/valearna/tpclassifier?branch=master&service=github)

## Introduction

Tpclassifier is a Python library that contains functions to train and apply classifiers for textual documents. It is
based on Python scikit-learn library, and it provides an easy interface to train and use its classifiers. In addition,
tpclassifier includes functions to transform documents from pdf and Textpresso CAS files (both generated from pdf or xml
files) into text and simplify the way they are imported in the library and used by the classifiers for training,
testing, and prediction.

## Installing tpclassifier library

To install tpclassifier, run the following command from the root directory of the project:

pip3 install .

The installation requires Python3 and pip3 to be installed in the system.

## Using the library from Python

The library can be imported as a regular Python package:
```python
from tpclassifier import TextpressoDocumentClassifier

classifier = TextpressoDocumentClassifier()
```

The complete documentation of the classes and functions provided by the library can be found
[here](http://tpclassifier.readthedocs.io/en/latest/).

## Using the executable scripts provided by the library

tpclassifier comes with a set of executable programs that use the library as a backend to provide an easy interface
to train, test, and apply classifiers for pdf or CAS documents. Go to the project
[wiki](https://github.com/valearna/tpclassifer/wiki) to see the complete documentation of these programs and for some
example use cases.
