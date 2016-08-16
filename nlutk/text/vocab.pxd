# -*- coding: utf-8 -*-
from libc.stdio cimport *

cdef struct vocab_word:
    long long count
    char* word
