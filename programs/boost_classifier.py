#!/usr/bin/env python3

"""Classify Textpresso documents into categories using a svm classifier"""

import argparse

import os

import pickle
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from tpclassifydocs import TextpressoDocumentClassifier, CasType

__author__ = "Valerio Arnaboldi"
__license__ = "MIT"
__version__ = "1.0.1"


def main():
    parser = argparse.ArgumentParser(description="Train a classifier and use it to classify documents")
    parser.add_argument("-t", "--train", metavar="training_dir", dest="training_dir", type=str, default=None,
                        help="train the classifier with the data in the provided directory (there must be two subdirs, "
                             "one named 'positive' containing positive observations and one named 'negative' for "
                             "negative ones")
    parser.add_argument("-p", "--predict", metavar="prediction_dir", dest="prediction_dir", type=str, default=None,
                        help="classify papers in the specified directory")
    parser.add_argument("-c", "--config", metavar="config_file", dest="config_file", type=str, default=".config",
                        help="config file where to store the model or from which to read a previously trained one")
    parser.add_argument("-f", "--file-type", metavar="file_type", dest="file_type", type=str, default="pdf",
                        choices=["pdf", "cas_pdf", "cas_xml"], help="type of files to be processed")

    args = parser.parse_args()

    if args.training_dir is not None:
        classifier = TextpressoDocumentClassifier()
        classifier.add_classified_docs_to_dataset(dir_path=os.path.join(args.training_dir, "positive"), recursive=True,
                                                  file_type=args.file_type, category=1)
        classifier.add_classified_docs_to_dataset(dir_path=os.path.join(args.training_dir, "negative"), recursive=True,
                                                  file_type=args.file_type, category=0)
        classifier.generate_training_and_test_sets(percentage_training=0.8)
        classifier.extract_features(use_hashing=False, ngram_range=(1, 2), lemmatization=False, stop_words="english",
                                    top_n_feat=50000)
        classifier.train_classifier(model=GradientBoostingClassifier(), dense=True)
        test_res = classifier.test_classifier(dense=True)

        classifier.dataset.data = []
        classifier.training_set.data = []
        classifier.test_set.data = []
        pickle.dump(classifier, open(args.config_file, "wb"))
        print(test_res.precision, test_res.recall, test_res.accuracy, sep="\t")

    if args.prediction_dir is not None:
        classifier = pickle.load(open(args.config_file, "rb"))
        results = classifier.predict_files(dir_path=args.prediction_dir, file_type=args.file_type)
        for i in range(results):
            print(results[0][i], results[1][i], sep=" ")


if __name__ == '__main__':
    main()
