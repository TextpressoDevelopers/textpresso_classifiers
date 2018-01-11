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
from tpclassifier.classifiers import TokenizerType

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
                        help="test the classifier on a test set, which is built as 20 percent of observations randomly "
                             "selected (and removed before training) from the training set")
    parser.add_argument("-p", "--predict", metavar="prediction_dir", dest="prediction_dir", type=str, default=None,
                        help="classify papers in the specified directory")
    parser.add_argument("-c", "--config", metavar="config_file", dest="config_file", type=str, default=".config",
                        help="config file where to store the model or from which to read a previously trained one")
    parser.add_argument("-f", "--file-type", metavar="file_type", dest="file_type", type=str, default="pdf",
                        choices=["pdf", "cas_pdf", "cas_xml"], help="type of files to be processed")
    parser.add_argument("-m", "--model", metavar="model", dest="model", type=str, default="SVM",
                        choices=["KNN", "SVM_LINEAR", "SVM_NONLINEAR", "TREE", "RF", "MLP", "NAIVEB", "GAUSS", "LDA",
                                 "XGBOOST"], help="type of model to use")
    parser.add_argument("-z", "--tokenizer-type", dest="tokenizer_type", metavar="tokenizer_type", type=str,
                        default="TFIDF", choices=["BOW", "TFIDF"], help="type of tokenizer to use for feature "
                                                                        "extraction")
    parser.add_argument("-n", "--ngram-size", metavar="ngram_size", dest="ngram_size", type=int, default=1,
                        help="number of consecutive words to be considered as a single feature")
    parser.add_argument("-b", "--best-features-num", metavar="best_features_size", dest="best_features_size", type=int,
                        default=20000, help="number of top features to be included in the model after feature "
                                            "selection")
    parser.add_argument("-l", "--lemmatize-words", dest="lemmatize", action="store_true", default=False,
                        help="apply lemmatization to text before the analysis "
                             "(https://en.wikipedia.org/wiki/Lemmatisation)")
    parser.add_argument("-e", "--exclude-words", metavar="exclude_words", dest="exclude_words", type=str, default=None,
                        help="exclude words contained in the provided file (separated by newline) from the vocabulary "
                             "used for feature extraction")
    parser.add_argument("-i", "--include-words", metavar="include_words", dest="include_words", type=str, default=None,
                        help="include words contained in the provided file (separated by newline) from the vocabulary "
                             "used for feature extraction")

    args = parser.parse_args()

    tokenizer = TokenizerType.TFIDF
    if args.tokenizer_type == "BOW":
        tokenizer = TokenizerType.BOW

    models = {"KNN": (False, KNeighborsClassifier(3)), "SVM_LINEAR": (False, SVC(kernel="linear")),
              "SVM_NONLINEAR": (False, SVC()), "TREE": (False, DecisionTreeClassifier()),
              "RF": (False, RandomForestClassifier()), "MLP": (False, MLPClassifier(alpha=1)),
              "NAIVEB": (True, GaussianNB()),
              "GAUSS": (True, GaussianProcessClassifier(1.0 * RBF(1.0), warm_start=True)),
              "LDA": (True, QuadraticDiscriminantAnalysis()), "XGBOOST": (True, GradientBoostingClassifier())}

    classifier = None
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
        classifier.extract_features(tokenizer_type=tokenizer, ngram_range=(1, args.ngram_size),
                                    lemmatization=args.lemmatize, stop_words="english",
                                    top_n_feat=args.best_features_size)
        if args.include_words is not None:
            words = [word.strip() for word in open(args.include_words)]
            classifier.add_features(words)
        if args.exclude_words is not None:
            words = [word.strip() for word in open(args.exclude_words)]
            classifier.add_features(words)
        classifier.extract_features(tokenizer_type=tokenizer, ngram_range=(1, args.ngram_size),
                                    lemmatization=args.lemmatize, stop_words="english",
                                    top_n_feat=args.best_features_size)
        classifier.train_classifier(model=models[args.model][1], dense=models[args.model][0])
        if args.test:
            test_res = classifier.test_classifier(dense=models[args.model][0])
            print(test_res.precision, test_res.recall, test_res.accuracy, sep="\t")
        classifier.save_to_file(args.config_file)

    if args.prediction_dir is not None:
        if classifier is None:
            classifier = TextpressoDocumentClassifier.load_from_file(args.config_file)
        results = classifier.predict_files(dir_path=args.prediction_dir, file_type=args.file_type,
                                           dense=models[args.model][0])
        for i in range(len(results[0])):
            print(results[0][i], results[1][i], sep=" ")


if __name__ == '__main__':
    main()
