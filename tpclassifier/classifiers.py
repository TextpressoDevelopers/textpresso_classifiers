"""Train and apply document classifiers for Textpresso literature"""

import os
import pickle
import random
from sklearn import metrics, feature_selection
from namedlist import namedlist
from tpclassifier.fileutils import *
from sklearn.feature_extraction.text import TfidfVectorizer, HashingVectorizer, TfidfTransformer, CountVectorizer
from typing import Tuple, List
from nltk import word_tokenize
from nltk.stem import WordNetLemmatizer

__author__ = "Valerio Arnaboldi"

__version__ = "1.0.1"


DatasetStruct_ = namedlist("DatasetStruct", "data, filenames, target, tr_features")
TestResults_ = namedlist("TestResults", "precision, recall, accuracy")


class TokenizerType(Enum):
    BOW = 1
    TFIDF = 2


class DatasetStruct(DatasetStruct_):
    """structure that defines fields of a dataset

    This data structure is used to store the properties of training sets and test sets within the models, so that the
    textual content and the file names of the documents used to create the classifiers are included with them and they
    can be easily retrieved.
    """
    pass


class TestResults(TestResults_):
    """List that contains the different values obtained while testing a classifier"""
    pass


class LemmaTokenizer(object):
    def __init__(self):
        self.wnl = WordNetLemmatizer()

    def __call__(self, doc):
        return [self.wnl.lemmatize(t) for t in word_tokenize(doc)]


class TextpressoDocumentClassifier:

    def __init__(self):
        self.dataset = DatasetStruct(data=[], filenames=[], target=[], tr_features=None)
        self.training_set = DatasetStruct(data=[], filenames=[], target=[], tr_features=None)
        self.test_set = DatasetStruct(data=[], filenames=[], target=[], tr_features=None)
        self.classifier = None
        self.vectorizer = None
        self.feature_selector = None
        self.vocabulary = None
        self.top_n_feat = 0

    def add_classified_docs_to_dataset(self, dir_path: str = None, recursive: bool = True,
                                       file_type: str = "pdf", category: int = 1):
        """load the text from the cas files in the specified directory and add them to the dataset,
        assigning them to the specified category (class)

        Note that only files with .tpcas.gz extension will be loaded

        :param dir_path: the path to the directory containing the text files to be added to the dataset
        :type dir_path: str
        :param recursive: scan directory recursively
        :type recursive: bool
        :param file_type: the type of cas files from which to extract the fulltext
        :type file_type: str
        :param category: the category value to be associated with the documents
        :type category: int
        """
        for file in os.listdir(dir_path):
            if not os.path.isdir(os.path.join(dir_path, file)):
                if file_type == "pdf":
                    data = extract_text_from_pdf(file_path=os.path.join(dir_path, file))
                    if data is None:
                        continue
                    self.dataset.data.append(data)
                elif file_type == "cas_pdf" or file_type == "cas_xml":
                    if file_type == "cas_pdf":
                        cas_type = CasType.PDF
                    else:
                        cas_type = CasType.XML
                    self.dataset.data.append(extract_text_from_cas_content(
                        cas_content=read_compressed_cas_content(file_path=os.path.join(dir_path, file)),
                        cas_type=cas_type))
                elif file_type == "txt":
                    with open(os.path.join(dir_path, file)) as input_file:
                        self.dataset.data.append(input_file.read())
                self.dataset.filenames.append(file)
                self.dataset.target.append(category)
            elif recursive:
                self.add_classified_docs_to_dataset(dir_path=os.path.join(dir_path, file), recursive=True,
                                                    file_type=file_type, category=category)

    def generate_training_and_test_sets(self, percentage_training: float = 0.8):
        """split the dataset into training and test sets, storing the results in separate *training_set* and *test_set*
            fields and clearing the original *dataset* variable. If training and test sets have already been populated,
            the method automatically re-construct the dataset by merging the two sets before re-splitting it into the
            new training and test sets.

        :param percentage_training: the percentage of observations to be placed in the training set
        :type percentage_training: float
        """
        if len(self.training_set.data) + len(self.test_set.data) > 0 and (self.dataset is None
                                                                          or len(self.dataset.data) == 0):
            self.dataset = DatasetStruct(data=[], filenames=[], target=[], tr_features=None)
            self.dataset.data = self.training_set.data
            self.dataset.data.extend(self.test_set.data)
            self.dataset.filenames = self.training_set.filenames
            self.dataset.filenames.extend(self.test_set.filenames)
            self.dataset.target = self.training_set.target
            self.dataset.target.extend(self.test_set.target)
        if len(self.dataset.data) > 0:
            idx_rand_order = list(range(len(self.dataset.data)))
            random.shuffle(idx_rand_order)
            training_set_idx = idx_rand_order[:int(len(idx_rand_order) * percentage_training)]
            test_set_idx = idx_rand_order[int(len(idx_rand_order) * percentage_training):]
            self.training_set.data = [self.dataset.data[i] for i in training_set_idx]
            self.training_set.filenames = [self.dataset.filenames[i] for i in training_set_idx]
            self.training_set.target = [self.dataset.target[i] for i in training_set_idx]
            self.test_set.data = [self.dataset.data[i] for i in test_set_idx]
            self.test_set.filenames = [self.dataset.filenames[i] for i in test_set_idx]
            self.test_set.target = [self.dataset.target[i] for i in test_set_idx]
            self.dataset = None

    def extract_features(self, tokenizer_type: TokenizerType = TokenizerType.BOW, ngram_range: Tuple[int, int] = (1, 1),
                         lemmatization: bool = False, top_n_feat: int = None, stop_words = "english",
                         max_df: float = 1.0, max_features: int = None, fit_vocabulary: bool = True,
                         transform_features: bool = True):
        """perform feature extraction on training and test sets and store the transformed features. By default, the
        method uses the vocabulary stored in the *vocabulary* field. If the vocabulary is None, a new vocabulary is
        built from the corpus.

        :param tokenizer_type: the type of tokenizer to use for feature extraction
        :type tokenizer_type: TokenizerType
        :param ngram_range: The lower and upper boundary of the range of n-values for different n-grams to be extracted.
            All values of n such that min_n <= n <= max_n will be used.
        :type ngram_range: Tuple[int, int]
        :param lemmatization: whether to apply lemmatization to the text
        :type lemmatization: bool
        :param top_n_feat: select the best n features through feature selection
        :type top_n_feat: int
        :param stop_words: stop words to use
        :param max_df: max_df to use
        :type max_df: float
        :param max_features: consider only the best n features sorted by tfidf
        :type max_features: int
        :param fit_vocabulary: whether to fit the vocabulary of the vectorizer
        :type fit_vocabulary: bool
        :param transform_features: whether to transform the text in the documents into feature vectors
        :type transform_features: bool
        """
        if len(self.training_set.data) > 0:
            if tokenizer_type == TokenizerType.BOW:
                if lemmatization:
                    self.vectorizer = CountVectorizer(stop_words=stop_words, ngram_range=ngram_range,
                                                      tokenizer=LemmaTokenizer(), max_df=max_df, max_features=max_features,
                                                      vocabulary=self.vocabulary)
                else:
                    self.vectorizer = CountVectorizer(stop_words=stop_words, ngram_range=ngram_range, max_df=max_df,
                                                      max_features=max_features, vocabulary=self.vocabulary)
            elif tokenizer_type == TokenizerType.TFIDF:
                if lemmatization:
                    self.vectorizer = TfidfVectorizer(stop_words=stop_words, ngram_range=ngram_range,
                                                      tokenizer=LemmaTokenizer(), max_df=max_df, max_features=max_features,
                                                      vocabulary=self.vocabulary)
                else:
                    self.vectorizer = TfidfVectorizer(stop_words=stop_words, ngram_range=ngram_range, max_df=max_df,
                                                      max_features=max_features, vocabulary=self.vocabulary)
            if fit_vocabulary:
                self.training_set.tr_features = self.vectorizer.fit(self.training_set.data)
            if transform_features:
                self.training_set.tr_features = self.vectorizer.transform(self.training_set.data)
                if len(self.test_set.data) > 0:
                    self.test_set.tr_features = self.vectorizer.transform(self.test_set.data)
            if top_n_feat is not None and transform_features:
                fs = feature_selection.chi2(self.training_set.tr_features, self.training_set.target)
                best_features_idx = sorted(range(len(fs[0])), key=lambda k: fs[0][k], reverse=True)[:top_n_feat]
                self.training_set.tr_features = self.training_set.tr_features[:, best_features_idx]
                if len(self.test_set.data) > 0:
                    self.test_set.tr_features = self.test_set.tr_features[:, best_features_idx]
                self.feature_selector = fs
                self.top_n_feat = top_n_feat
                inv_vocabulary = {v: k for k, v in self.vectorizer.vocabulary_.items()}
                # store best features in vocabulary
                self.vocabulary = dict([(inv_vocabulary[best_idx], new_idx) for best_idx, new_idx in
                                        zip(best_features_idx, range(top_n_feat))])
            else:
                self.vocabulary = self.vectorizer.vocabulary_
                self.feature_selector = None
        else:
            raise Exception('training set is empty')

    def train_classifier(self, model, dense: bool = False):
        """train a classifier using the sample documents in the training set and save the trained model

        :param model: the model to train
        :param dense: whether to transform the sparse matrix of features to a dense structure (required by some models)
        :type dense: bool
        :raise: Exception in case the training set features have not been extracted yet
        """
        if self.training_set.tr_features is not None:
            self.classifier = model
            if dense:
                self.classifier.fit(self.training_set.tr_features.todense(), self.training_set.target)
            else:
                self.classifier.fit(self.training_set.tr_features, self.training_set.target)
        else:
            raise Exception('training set features have not been extracted yet')

    def test_classifier(self, test_on_training: bool = False, dense: bool = False):
        """test the classifier on the test set and return the results

        :param test_on_training: whether to test the classifier on the training set instead of the test set
        :type test_on_training: bool
        :param dense: whether to transform the sparse matrix of features to a dense structure (required by some models)
        :type dense: bool
        :return: the test results of the classifier
        :rtype: TestResults"""
        if test_on_training:
            test_set = self.training_set
        else:
            test_set = self.test_set
        if test_set.tr_features is not None:
            if dense:
                pred = self.classifier.predict(test_set.tr_features.todense())
            else:
                pred = self.classifier.predict(test_set.tr_features)
            precision = metrics.precision_score(test_set.target, pred)
            recall = metrics.recall_score(test_set.target, pred)
            accuracy = metrics.accuracy_score(test_set.target, pred)
            return TestResults(precision, recall, accuracy)
        else:
            raise Exception('features have not been extracted yet')

    def predict_file(self, file_path: str, file_type: str = "pdf", dense: bool = False):
        """predict the class of a single file

        :param file_path: the path to the file
        :type file_path: str
        :param file_type: the type of file
        :type file_type: str
        :param dense: whether to transform the sparse matrix of features to a dense structure (required by some models)
        :type dense: bool
        :return: the class predicted by the classifier or None if the class cannot be predicted (e.g., the input file
            cannot be converted)
        :rtype: int
        """
        if file_type == "pdf":
            fulltext = extract_text_from_pdf(file_path)
        else:
            if file_type == "cas_pdf":
                cas_type = CasType.PDF
            else:
                cas_type = CasType.XML
            fulltext = extract_text_from_cas_content(read_compressed_cas_content(file_path=file_path),
                                                     cas_type=cas_type)
        if fulltext is not None:
            tr_features = self.vectorizer.transform([fulltext])
            if self.feature_selector is not None:
                best_features_idx = sorted(range(len(self.feature_selector[0])), key=lambda k: self.feature_selector[0][k],
                                           reverse=True)
                tr_features = tr_features[:, best_features_idx[:self.top_n_feat]]
            if dense:
                return self.classifier.predict(tr_features.todense())
            else:
                return self.classifier.predict(tr_features)
        else:
            return None

    def predict_files(self, dir_path: str, file_type: str = "pdf", dense: bool = False):
        """predict the class of a set of files in a directory

        :param dir_path: the path to the directory containing the files to be classified
        :type dir_path: str
        :param file_type: the type of files
        :type file_type: str
        :param dense: whether to transform the sparse matrix of features to a dense structure (required by some models)
        :type dense: bool
        :return: the file names of the classified documents along with the classes predicted by the classifier or None
            if the class cannot be predicted (e.g., the input file cannot be converted)
        :rtype: Tuple[List[str], List[int]]
        """
        data = []
        filenames = []
        failed_filenames = []
        for file in os.listdir(dir_path):
            file_path = os.path.join(dir_path, file)
            if file_type == "pdf":
                text = extract_text_from_pdf(file_path)
                if text is None:
                    failed_filenames.append(file)
                    continue
                data.append(extract_text_from_pdf(file_path))
            else:
                if file_type == "cas_pdf":
                    cas_type = CasType.PDF
                else:
                    cas_type = CasType.XML
                data.append(extract_text_from_cas_content(read_compressed_cas_content(file_path=file_path),
                            cas_type=cas_type))
            filenames.append(file)
        tr_features = self.vectorizer.transform(data)
        if self.feature_selector is not None:
            best_features_idx = sorted(range(len(self.feature_selector[0])), key=lambda k: self.feature_selector[0][k],
                                       reverse=True)
            tr_features = tr_features[:, best_features_idx[:self.top_n_feat]]
        filenames.extend(failed_filenames)
        if dense:
            predictions = self.classifier.predict(tr_features.todense()).tolist()
        else:
            predictions = self.classifier.predict(tr_features).tolist()
        predictions.extend([None] * len(failed_filenames))
        return filenames, predictions

    def get_features_with_importance(self):
        """retrieve the list of features of the classifier together with their chi-squared score. The score is set to 0
        in case the importance of the features has not been calculated

        :return: the list of features of the classifier with their importance score
        :rtype: List[Tuple[str, float]]"""
        inv_vocabulary = {v: k for k, v in self.vectorizer.vocabulary_.items()}
        if self.feature_selector is not None:
            best_features_idx = sorted(range(len(self.feature_selector[0])), key=lambda k: self.feature_selector[0][k],
                                       reverse=True)[:self.top_n_feat]
            best_features_score = self.feature_selector[0][:self.top_n_feat]
            return sorted([(inv_vocabulary[idx], score) for idx, score in zip(best_features_idx, best_features_score)],
                          key=lambda x: x[1], reverse=True)
        else:
            return [(v, 0) for v in self.vectorizer.vocabulary_.keys()]

    def save_to_file(self, file_path: str, compact: bool = True):
        """save the classifier to file

        :param file_path: path to the location where to store the classifier
        :type file_path: str
        :param compact: whether to save the classifier in compact mode. If True, the raw data used to train the
            classifier is deleted and the classifier cannot be further modified by adding or removing features and
            cannot be re-trained.
        :type compact: bool
        """
        if compact:
            self.dataset = None
            self.training_set.data = []
            self.training_set.tr_features = []
            self.test_set.data = []
            self.test_set.tr_features = []
            self.feature_selector = None
        pickle.dump(self, open(file_path, "wb"))

    @staticmethod
    def load_from_file(file_path: str):
        """load a classifier from file

        :param file_path: the path to the pickle file containing the classifier
        :type file_path: str
        :return: the classifier object
        :rtype: TextpressoDocumentClassifier
        """
        return pickle.load(open(file_path, "rb"))

    def remove_features(self, features: List[str]):
        """remove a list of features from the current vocabulary of the classifier, if not empty. The classifier must
        be re-trained to apply the new vocabulary.

        :param features: the list of features to be removed
        :type features: List[str]
        """
        if self.vocabulary is not None:
            for feature in features:
                self.vocabulary.pop(feature, None)
            curr_features_list = self.vocabulary.keys()
            self.vocabulary = dict([(feature, feat_id) for feature, feat_id in
                                    zip(curr_features_list, range(len(curr_features_list)))])

    def add_features(self, features: List[str], delete_old_vocabulary: bool = False):
        """add a list of features to the current vocabulary. The classifier must be re-trained to apply the new
        vocabulary

        :param features: the list of features to be added to the current vocabulary
        :type features: List[str]
        :param delete_old_vocabulary: whether to delete the old vocabulary before adding the new features
        :type delete_old_vocabulary: bool
        """
        curr_features_set = set()
        if self.vocabulary is not None and not delete_old_vocabulary:
            curr_features_set = set(self.vocabulary.keys())
        curr_features_set.update(features)
        self.vocabulary = dict([(feature, feat_id) for feature, feat_id in
                                zip(curr_features_set, range(len(curr_features_set)))])
