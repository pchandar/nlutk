import pytest

from nlutk.text import tokenize, stem


def test_tokenize():
    assert [('test', 0), ('string', 5)] == tokenize("test string")


def test_tokenize_punct():
    #print('\n' + ' '.join(list(map(lambda x: x[0], tokenize("Mr. X, or y $1.99 ")))))
    assert [('Mr', 0), ('X', 4), (',', 5), ('or', 7), ('y', 10)] == tokenize("Mr. X, or y")


def test_porter_stemmer():
    assert stem('testing') == 'test'
