"""Unit tests for cas utils"""

import unittest
import os
from tpclassifier.casutils import *


__author__ = "Valerio Arnaboldi"
__license__ = "MIT"
__version__ = "1.0.1"


class TestCasUtils(unittest.TestCase):

    def setUp(self):
        this_dir, this_filename = os.path.split(__file__)
        self.training_dir_path = os.path.join(this_dir, "datasets")
        self.test_dir_path = os.path.join(this_dir, "datasets")

    def test_read_compressed_cas_content(self):
        self.assertGreater(len(read_compressed_cas_content(
            os.path.join(self.training_dir_path, "animals", "animals-03-00606.tpcas.gz"))), 0)

    def test_extract_text_from_cas_content(self):
        cas_content = read_compressed_cas_content(os.path.join(self.training_dir_path, "c_elegans",
                                                               "WBPaper00035071.tpcas.gz"))
        fulltext = extract_text_from_cas_content(cas_content=cas_content, cas_type=CasType.PDF)
        self.assertTrue(len(fulltext) > 0)
        cas_content = read_compressed_cas_content(os.path.join(self.training_dir_path, "animals",
                                                               "animals-03-00606.tpcas.gz"))
        fulltext = extract_text_from_cas_content(cas_content=cas_content, cas_type=CasType.XML)
        self.assertTrue(len(fulltext) > 0)


if __name__ == "__main__":
    unittest.main()
