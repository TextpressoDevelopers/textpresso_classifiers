"""Unit tests for Textpresso document classifiers"""

import unittest
import os
from tpclassifier.classifiers import TextpressoDocumentClassifier, CasType
from sklearn import svm

__author__ = "Valerio Arnaboldi"
__license__ = "MIT"
__version__ = "1.0.1"


class TestTextpressoDocumentClassifier(unittest.TestCase):

    def setUp(self):
        this_dir, this_filename = os.path.split(__file__)
        self.training_dir_path = os.path.join(this_dir, "datasets")
        self.tpDocClassifier = TextpressoDocumentClassifier()

    def test_add_classified_docs_to_dataset(self):
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "c_elegans"),
                                                            file_type=CasType.PDF, category=1)
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "animals"),
                                                            file_type=CasType.XML, category=2)
        self.assertTrue(len(self.tpDocClassifier.dataset.data) == 10)
        self.assertTrue(len(self.tpDocClassifier.dataset.target) == 10)

    def test_generate_training_and_test_sets(self):
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "c_elegans"),
                                                            file_type=CasType.PDF, category=1)
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "animals"),
                                                            file_type=CasType.XML, category=2)
        self.tpDocClassifier.generate_training_and_test_sets(percentage_training=0.8)
        self.assertEqual(len(self.tpDocClassifier.training_set.data),
                         int(len(self.tpDocClassifier.dataset.data) * 0.8))

    def test_extract_features(self):
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "c_elegans"),
                                                            file_type=CasType.PDF, category=1)
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "animals"),
                                                            file_type=CasType.XML, category=2)
        self.tpDocClassifier.generate_training_and_test_sets(percentage_training=0.8)
        self.tpDocClassifier.extract_features()
        self.assertTrue(self.tpDocClassifier.dataset.tr_features is not None)
        self.assertTrue(self.tpDocClassifier.test_set.tr_features is not None)

    def test_train_classifier(self):
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "c_elegans"),
                                                            file_type=CasType.PDF, category=1)
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "animals"),
                                                            file_type=CasType.XML, category=2)
        self.tpDocClassifier.generate_training_and_test_sets(percentage_training=0.8)
        self.tpDocClassifier.extract_features(use_hashing=False, ngram_range=(1, 2))
        self.tpDocClassifier.train_classifier(model=svm.SVC)
        self.assertEqual(len(self.tpDocClassifier.classifier.predict(self.tpDocClassifier.test_set.tr_features)),
                         len(self.tpDocClassifier.test_set.data))

if __name__ == "__main__":
    unittest.main()
