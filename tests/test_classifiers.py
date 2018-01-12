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
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "c_elegans"),
                                                            file_type="cas_pdf", category=1)
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "animals"),
                                                            file_type="cas_xml", category=2)
        self.assertTrue(len(self.tpDocClassifier.dataset.data) == 10)
        self.assertTrue(len(self.tpDocClassifier.dataset.target) == 10)

    def test_generate_training_and_test_sets(self):
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "c_elegans"),
                                                            file_type="cas_pdf", category=1)
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "animals"),
                                                            file_type="cas_xml", category=2)
        self.tpDocClassifier.generate_training_and_test_sets(percentage_training=0.8)
        self.assertEqual(len(self.tpDocClassifier.training_set.data),
                         int(len(self.tpDocClassifier.test_set.data) * 4))

    def test_extract_features(self):
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "c_elegans"),
                                                            file_type="cas_pdf", category=1)
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "animals"),
                                                            file_type="cas_xml", category=2)
        self.tpDocClassifier.generate_training_and_test_sets(percentage_training=0.8)
        self.tpDocClassifier.extract_features()
        self.assertTrue(self.tpDocClassifier.dataset is None)
        self.assertTrue(self.tpDocClassifier.test_set.tr_features is not None)

    def test_train_classifier(self):
        model = svm.SVC()
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "c_elegans"),
                                                            file_type="cas_pdf", category=1)
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "animals"),
                                                            file_type="cas_xml", category=2)
        self.tpDocClassifier.generate_training_and_test_sets(percentage_training=0.8)
        self.tpDocClassifier.extract_features(ngram_range=(1, 2))
        self.tpDocClassifier.train_classifier(model=model)
        self.assertEqual(len(self.tpDocClassifier.classifier.predict(self.tpDocClassifier.test_set.tr_features)),
                         len(self.tpDocClassifier.test_set.data))

    def test_remove_features(self):
        model = svm.SVC()
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "c_elegans"),
                                                            file_type="cas_pdf", category=1)
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "animals"),
                                                            file_type="cas_xml", category=2)
        self.tpDocClassifier.generate_training_and_test_sets(percentage_training=0.8)
        self.tpDocClassifier.extract_features(ngram_range=(1, 2), fit_vocabulary=True, transform_features=False)
        self.tpDocClassifier.remove_features([list(self.tpDocClassifier.vocabulary.keys())[0]])
        self.tpDocClassifier.extract_features(ngram_range=(1, 2), fit_vocabulary=False, transform_features=True)
        self.tpDocClassifier.train_classifier(model=model)
        self.assertEqual(len(self.tpDocClassifier.classifier.predict(self.tpDocClassifier.test_set.tr_features)),
                         len(self.tpDocClassifier.test_set.data))

    def test_prediction_single_file_none(self):
        model = svm.SVC()
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "c_elegans"),
                                                            file_type="cas_pdf", category=1)
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "animals"),
                                                            file_type="cas_xml", category=2)
        self.tpDocClassifier.generate_training_and_test_sets()
        self.tpDocClassifier.extract_features(ngram_range=(1, 1), fit_vocabulary=True, transform_features=True)
        self.tpDocClassifier.train_classifier(model=model)
        prediction = self.tpDocClassifier.predict_file(file_path=os.path.join(self.training_dir_path, "pdf",
                                                                              "c_elegans", "WBPaper00004781.pdf"),
                                                       file_type="pdf")
        self.assertIsNone(prediction)

    def test_prediction_multiple_files_with_none(self):
        model = svm.SVC()
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "c_elegans"),
                                                            file_type="cas_pdf", category=1)
        self.tpDocClassifier.add_classified_docs_to_dataset(os.path.join(self.training_dir_path, "cas", "animals"),
                                                            file_type="cas_xml", category=2)
        self.tpDocClassifier.generate_training_and_test_sets()
        self.tpDocClassifier.extract_features(ngram_range=(1, 1), fit_vocabulary=True, transform_features=True)
        self.tpDocClassifier.train_classifier(model=model)
        predictions = self.tpDocClassifier.predict_files(dir_path=os.path.join(self.training_dir_path, "pdf",
                                                                               "c_elegans"), file_type="pdf")
        self.assertFalse(all(predictions[1]))


if __name__ == "__main__":
    unittest.main()
