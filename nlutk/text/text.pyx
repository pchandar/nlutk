# -*- coding: utf-8 -*-
# cython: c_string_type=str, c_string_encoding=ascii, embedsignature=True, linetrace=True
# distutils: define_macros=CYTHON_TRACE_NOGIL=1

from libcpp.string cimport string
from libcpp.vector cimport vector
from cython.operator cimport dereference as deref, preincrement as inc
from .vocab import Vocab


def tokenize(str sentence, str tokenizer_type= "conll"):
    cdef vector[Token*] tokens = conll_tokenize(sentence, 0)
    cdef vector[Token*].iterator it = tokens.begin()
    output = []
    while it != tokens.end():
        output.append((deref(it).text, deref(it).offset))
        inc(it)
    return output

def stem(str word):
    return word[0: porter_stem(word.encode('UTF-8', errors='ignore'), len(word)) + 1 ]

def text_to_word_sequence(vocab: Vocab,
                          text: str,
                          stem=False,
                          normalize_url=False,
                          normalize_number=False,
                          lower = True):
    if lower:
        text = text.lower()
    return [vocab.add(_f[0]) for _f in tokenize(text) if _f]

