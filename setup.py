#!/usr/bin/env python3

from setuptools import setup

setup(name='textpresso_classifiers',
      version='0.1',
      description='Classify Textpresso documents into categories',
      url='',
      author='Valerio Arnaboldi',
      author_email='valearna@caltech.edu',
      license='MIT',
      packages=['textpresso_classifiers'],
      setup_requires=['numpy'],
      install_requires=[
          'sklearn',
          'scipy',
          'numpy',
          'typing',
          'namedlist',
          'PyPDF2',
          'nltk'
      ],
      scripts=['bin/tp_doc_classifier.py', 'bin/classifiers_comparison.py', 'bin/convert_doc_to_txt.py',
               'wormbase_tools/tp_classification_pipeline.sh'],
      test_suite='nose.collector',
      tests_require=['nose'],
      zip_safe=False)
