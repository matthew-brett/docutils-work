#! /usr/bin/env python

# Author: Felix Wiemann
# Contact: Felix_Wiemann@ososo.de
# Revision: $Revision$
# Date: $Date$
# Copyright: This module has been placed in the public domain.

"""
Test module for io.py.
"""

import unittest
from docutils import io


class InputTests(unittest.TestCase):

    def test_bom(self):
        input = io.StringInput(source='\xef\xbb\xbf foo \xef\xbb\xbf bar',
                               encoding='utf8')
        # Assert BOMs are gone.
        self.assertEquals(input.read(), u' foo  bar')


if __name__ == '__main__':
    unittest.main()