#!/usr/bin/env python3

"""Classify Textpresso documents into categories using a svm classifier"""

import argparse

import os

import pickle
from sklearn.discriminant_analysis import QuadraticDiscriminantAnalysis
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.gaussian_process import GaussianProcessClassifier
from sklearn.gaussian_process.kernels import RBF
from sklearn.linear_model import LogisticRegression, SGDClassifier
from sklearn.naive_bayes import GaussianNB
from sklearn.neighbors import KNeighborsClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.tree import DecisionTreeClassifier
from sklearn.svm import SVC
from tpclassifier import TextpressoDocumentClassifier, CasType

__author__ = "Valerio Arnaboldi"

__version__ = "1.0.1"


def main():
    parser = argparse.ArgumentParser(description="Train a binary classifier and use it to classify Textpresso documents"
                                     " in pdf or CAS format")
    parser.add_argument("-t", "--train", metavar="training_dir", dest="training_dir", type=str, default=None,
                        help="train the classifier with the data in the provided directory (there must be two subdirs, "
                             "one named 'positive' containing positive observations and one named 'negative' for "
                             "negative ones")
    parser.add_argument("-T", "--test", dest="test", action="store_true", default=False,
                        help="test the classifier on a test set, which is built as 80 percent of observations randomly "
                             "selected (and removed) from the training set")
    parser.add_argument("-p", "--predict", metavar="prediction_dir", dest="prediction_dir", type=str, default=None,
                        help="classify papers in the specified directory")
    parser.add_argument("-c", "--config", metavar="config_file", dest="config_file", type=str, default=".config",
                        help="config file where to store the model or from which to read a previously trained one")
    parser.add_argument("-f", "--file-type", metavar="file_type", dest="file_type", type=str, default="pdf",
                        choices=["pdf", "cas_pdf", "cas_xml"], help="type of files to be processed")
    parser.add_argument("-m", "--model", metavar="model", dest="model", type=str, default="SVM",
                        choices=["KNN", "SVM_LINEAR", "SVM_NONLINEAR", "TREE", "RF", "MLP", "NAIVEB", "GAUSS", "LDA",
                                 "XGBOOST"])
    parser.add_argument("-H", "--hash-trick", dest="hash_trick", action="store_true", default=False,
                        help="use the hash trick to vectorize features (https://en.wikipedia.org/wiki/Feature_hashing)")
    parser.add_argument("-n", "--ngram-size", metavar="ngram_size", dest="ngram_size", type=int, default=1,
                        help="number of consecutive words to be considered as a single feature")
    parser.add_argument("-b", "--best-features-num", metavar="best_features_size", dest="best_features_size", type=int,
                        default=20000, help="number of top features to be included in the model after feature "
                                            "selection")
    parser.add_argument("-l", "--lemmatize-words", dest="lemmatize", action="store_true", default=False,
                        help="apply lemmatization to text before the analysis "
                             "(https://en.wikipedia.org/wiki/Lemmatisation)")

    args = parser.parse_args()

    models = {"KNN": (False, KNeighborsClassifier(3)), "SVM_LINEAR": (False, SVC(kernel="linear")),
              "SVM_NONLINEAR": (False, SVC()), "TREE": (False, DecisionTreeClassifier()),
              "RF": (False, RandomForestClassifier()), "MLP": (False, MLPClassifier(alpha=1)),
              "NAIVEB": (True, GaussianNB()),
              "GAUSS": (True, GaussianProcessClassifier(1.0 * RBF(1.0), warm_start=True)),
              "LDA": (True, QuadraticDiscriminantAnalysis()), "XGBOOST": (True, GradientBoostingClassifier())}

    if args.training_dir is not None:
        classifier = TextpressoDocumentClassifier()
        classifier.add_classified_docs_to_dataset(dir_path=os.path.join(args.training_dir, "positive"), recursive=True,
                                                  file_type=args.file_type, category=1)
        classifier.add_classified_docs_to_dataset(dir_path=os.path.join(args.training_dir, "negative"), recursive=True,
                                                  file_type=args.file_type, category=0)
        if args.test:
            classifier.generate_training_and_test_sets(percentage_training=0.8)
        else:
            classifier.generate_training_and_test_sets(percentage_training=1)
        classifier.extract_features(use_hashing=args.hash_trick, ngram_range=(1, args.ngram_size),
                                    lemmatization=args.lemmatize, stop_words="english",
                                    top_n_feat=args.best_features_size)
        classifier.train_classifier(model=models[args.model][1], dense=models[args.model][0])
        if args.test:
            test_res = classifier.test_classifier(dense=models[args.model][0])
            print(test_res.precision, test_res.recall, test_res.accuracy, sep="\t")

        classifier.dataset.data = []
        classifier.training_set.data = []
        classifier.test_set.data = []
        pickle.dump(classifier, open(args.config_file, "wb"))

    if args.prediction_dir is not None:
        classifier = pickle.load(open(args.config_file, "rb"))
        results = classifier.predict_files(dir_path=args.prediction_dir, file_type=args.file_type)
        for i in range(len(results[0])):
            print(results[0][i], results[1][i], sep=" ")


if __name__ == '__main__':
    main()
