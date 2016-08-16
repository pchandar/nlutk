import pytest
import pkg_resources
from nlutk.text import Vocab

datapath = lambda fname: pkg_resources.resource_filename('tests', 'data/' + fname)


def test_add():
    v = Vocab()
    assert v.add('dummy') == 0

def test_get_count():
    v = Vocab()
    v.add('test')
    v.add('test1')
    v.add('test34')
    v.add('test')
    assert v.count('test1') == 1
    assert v.size() == 3
    assert v.count('test') == 2


def test_loadvec():
    v = Vocab()
    v.load_word2vec(datapath('word2vec.data'))
    assert v.count('the') == 1
    assert v.size() == 9

