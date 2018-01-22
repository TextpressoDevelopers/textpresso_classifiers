#!/usr/bin/env python3

"""Classify Textpresso documents into categories using a svm classifier"""

import argparse

import numpy as np
from sklearn.discriminant_analysis import QuadraticDiscriminantAnalysis

from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.gaussian_process import GaussianProcessClassifier
from sklearn.gaussian_process.kernels import RBF
from sklearn.linear_model import LogisticRegression, SGDClassifier
from sklearn.naive_bayes import GaussianNB
from sklearn.neighbors import KNeighborsClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.tree import DecisionTreeClassifier

from tpclassifier import TextpressoDocumentClassifier, CasType
from sklearn.svm import SVC

from tpclassifier.classifiers import TokenizerType

__author__ = "Valerio Arnaboldi"

__version__ = "1.0.1"


def main():
    parser = argparse.ArgumentParser(description="Train and test a set of classifiers for the classification of "
                                                 "Textpresso documents and compare their prediction accuracy")
    parser.add_argument("-f", "--file-type", metavar="file_type", dest="file_type", type=str, default="pdf",
                        choices=["pdf", "cas_pdf", "cas_xml", "txt"], help="type of files to be processed")
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
    parser.add_argument("positive_dataset_dir", metavar="positive_dataset_dir", type=str,
                        help="directory containing the CAS files from which to get data for positive observations")
    parser.add_argument("negative_dataset_dir", metavar="negative_dataset_dir", type=str,
                        help="directory containing the CAS files from which to get data for negative observations")
    args = parser.parse_args()

    classifier = TextpressoDocumentClassifier()
    classifier.add_classified_docs_to_dataset(dir_path=args.positive_dataset_dir, recursive=True,
                                              file_type=args.file_type, category=1)
    classifier.add_classified_docs_to_dataset(dir_path=args.negative_dataset_dir, recursive=True,
                                              file_type=args.file_type, category=0)
    precision = []
    recall = []
    accuracy = []

    sparse_models = [KNeighborsClassifier(3), SVC(kernel="linear"), SVC(gamma=0.05),
                     DecisionTreeClassifier(), RandomForestClassifier(), MLPClassifier(alpha=1)]

    dense_models = [GaussianProcessClassifier(1.0 * RBF(1.0), warm_start=True), GaussianNB(),
                    QuadraticDiscriminantAnalysis(), GradientBoostingClassifier()]

    models_names = ["knn", "linear svm", "svm", "decision tree", "random forest", "mlp", "naive bayes",
                    "gaussian process", "quad disc analysis", "xgboost"]

    def train_model(model, densify):
        precision.append([])
        recall.append([])
        accuracy.append([])
        for _ in range(10):
            classifier.generate_training_and_test_sets(percentage_training=0.8)
            if args.tokenizer_type == "BOW":
                tokenizer_type = TokenizerType.BOW
            else:
                tokenizer_type = TokenizerType.TFIDF
            classifier.extract_features(ngram_range=(1, args.ngram_size), lemmatization=args.lemmatize,
                                        stop_words="english", top_n_feat=args.best_features_size,
                                        tokenizer_type=tokenizer_type)
            classifier.train_classifier(model=model, dense=densify)
            test_res = classifier.test_classifier(dense=densify)
            precision[-1].append(test_res.precision)
            recall[-1].append(test_res.recall)
            accuracy[-1].append(test_res.accuracy)

    for model in sparse_models:
        train_model(model, False)
    for model in dense_models:
        train_model(model, True)

    print("avg results on 10 random combinations of training and test sets")
    for i in range(len(models_names)):
        print(models_names[i])
        print("avg precision:", np.mean(precision[i]), "var:", np.var(precision[i]), sep=" ")
        print("avg recall:", np.mean(recall[i]), "var:", np.var(recall[i]), sep=" ")
        print("avg accuracy:", np.mean(accuracy[i]), "var:", np.var(accuracy[i]), sep=" ")
        print()


if __name__ == '__main__':
    main()
