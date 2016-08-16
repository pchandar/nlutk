from libcpp.string cimport string
from libcpp.vector cimport vector


cdef extern from "CoNLLTokenizer.h" namespace "nlutk":
    cdef cppclass Token:
        Token(string, long)
        string text
        long offset
    vector[Token*] conll_tokenize(string, long) except +RuntimeError


cdef extern from "PorterStemmer.h":
    int porter_stem(char*, int) except +RuntimeError