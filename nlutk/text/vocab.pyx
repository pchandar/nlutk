# -*- coding: utf-8 -*-
# cython: c_string_type=str, c_string_encoding=ascii, embedsignature=True, linetrace=True
# distutils: define_macros=CYTHON_TRACE_NOGIL=1

from __future__ import print_function
from cython.operator cimport dereference as deref
from libc.stdio cimport fclose, FILE, getline, fopen
from libc.string cimport strlen, strncpy
from libc.stdlib cimport calloc, realloc, free
from .vocab cimport vocab_word
import numpy as np


cdef class Vocab:
    cdef int vocab_hash_size
    cdef long long vocab_max_size
    cdef long long vocab_size
    cdef int min_reduce

    cdef int* vocab_hash
    cdef vocab_word* vocab
    cdef weights

    def __cinit__(Vocab self):
        self.vocab = NULL
        self.vocab_hash = NULL
        cdef long long a
        self.vocab_hash_size = 30000000  # Maximum 30 * 0.7 = 21M words in the vocabulary
        self.vocab_max_size = 10000
        self.vocab_size = 0
        self.min_reduce = 1

        self.vocab_hash = <int*> calloc(self.vocab_hash_size, sizeof(int))
        self.vocab = <vocab_word *> calloc(self.vocab_max_size, sizeof(vocab_word))


        for a in range(0, self.vocab_hash_size):
            self.vocab_hash[a] = -1
        self.vocab_size = 0
        self.weights = None

    cdef int _check_alive(Vocab self) except -1:
        if self.vocab == NULL or self.vocab_hash == NULL:
            raise RuntimeError("Wrapped C++ object is deleted")
        else:
            return 0

    def __dealloc__(Vocab self):
        cdef long long a
        for a  in range(0, self.vocab_size):
            if self.vocab[a].word != NULL:
                free(self.vocab[a].word)
        free(self.vocab[self.vocab_size].word)
        free(self.vocab)

    def count(Vocab self, str word):
        cdef long long idx = self.index(word)
        if idx == -1:
            return None
        else:
            return self.vocab[idx].count

    def index(Vocab self, str word):
        py_byte_string = word.encode('UTF-8', errors='ignore')
        cdef char* c_string = py_byte_string
        cdef unsigned int hash_val = self.get_hash_for_word(c_string)
        while True:
            if self.vocab_hash[hash_val] == -1:
                return -1
            if not self.str_compare(c_string, self.vocab[self.vocab_hash[hash_val]].word):
                return self.vocab_hash[hash_val]
            hash_val = (hash_val + 1) % self.vocab_hash_size


    cdef get_hash_for_word(Vocab self, const char *word):
        cdef unsigned long long a = 0
        cdef unsigned long long hash_val = 0
        for a in range(0, strlen(word)):
            hash_val = hash_val * 257 + word[a]
        hash_val %= self.vocab_hash_size
        return hash_val


    cdef str_compare(Vocab self, const char *s1, const char *s2):
        while deref(s1) != b'\0' and deref(s1) == deref(s2):
            s1 += 1
            s2 += 1
        return deref(s1) - deref(s2)


    def size(Vocab self):
        return self.vocab_size

    def add(Vocab self, str word, long long set_count = 0):
        py_byte_string = word.encode('UTF-8', errors='ignore')
        cdef char* c_string = py_byte_string
        cdef unsigned int hash_val
        cdef unsigned int length
        cdef long long idx = self.index(word);
        # Update the Counts
        if idx == -1:
            length = strlen(c_string) + 1

            self.vocab[self.vocab_size].word = <char*> calloc(length, sizeof(char))
            strncpy(self.vocab[self.vocab_size].word, word, length)
            self.vocab[self.vocab_size].count = 0
            self.vocab_size += 1

            # Reallocate memory if needed
            if self.vocab_size + 2 >= self.vocab_max_size:
                self.vocab_max_size += 10000
                self.vocab = <vocab_word *> realloc(self.vocab, self.vocab_max_size * sizeof(vocab_word))

            hash_val = self.get_hash_for_word(word)
            while self.vocab_hash[hash_val] != -1:
                hash_val = (hash_val + 1) % self.vocab_hash_size

            self.vocab_hash[hash_val] = self.vocab_size - 1

            # set the word count
            if set_count == 0:
                self.vocab[self.vocab_size - 1].count = 1
            else:
                self.vocab[self.vocab_size - 1].count = set_count
            if self.vocab_size > self.vocab_hash_size * 0.7:
                self.shrink_vocab()
            return self.vocab_size - 1
        else:
            self.vocab[idx].count += 1
            return idx


    # Reduces the vocabulary by removing infrequent tokens
    cdef shrink_vocab(Vocab self):
        cdef int a = 0
        cdef int b = 0
        cdef unsigned int hash_val
        for a in range(0, self.vocab_size):
            if self.vocab[a].count > self.min_reduce:
                self.vocab[b].count = self.vocab[a].count
                self.vocab[b].word = self.vocab[a].word
                b += 1
            else:
                free(self.vocab[a].word)
        self.vocab_size = b
        for a in range(0, self.vocab_hash_size):
            self.vocab_hash[a] = -1
        for a in range(0, self.vocab_size):
            # Hash will be re-computed, as it is not actual
            hash_val = self.get_hash_for_word(self.vocab[a].word)
            while self.vocab_hash[hash_val] != -1:
                hash_val = (hash_val + 1) % self.vocab_hash_size
                self.vocab_hash[hash_val] = a

        fflush(stdout)
        self.min_reduce += 1




    def save(Vocab self, str filepath):
        cdef long long i = 0
        with open(filepath, 'wb') as fout:
            for i in range(0, self.vocab_size):
                fout.write(self.vocab[i].word + " "  + self.vocab[i].count + "\n")


    def load(Vocab self, str filepath):
        py_byte_string = filepath.encode('UTF-8')
        cdef char* filename = py_byte_string

        cdef FILE* cfile
        cfile = fopen(filename, "rb")
        if cfile == NULL:
            raise FileNotFoundError(2, "No such file or directory: '%s'" % filename)

        cdef char * line = NULL
        cdef size_t l = 0
        cdef ssize_t cur_line

        while True:
            cur_line = getline(&line, &l, cfile)
            if cur_line == -1: break
            cur_word = cur_line.split(' ')[0]
            cur_word_count  = int(cur_line.split(' ')[1])
            self.add(cur_word.c_str(), cur_word_count)
        fclose(cfile)

    def get_weights(Vocab self):
        if self.size() > self.weights.shape[0]:
            size_diff = self.size() - self.weights.shape[0]
            self.weights = np.concatenate((self.weights, np.random.rand(size_diff, self.weights.shape[1])), axis=0)
        return self.weights

    def load_word2vec(Vocab self, str filepath):
        first = True
        cdef long rowid = 0

        filename_byte_string = filepath.encode("UTF-8")
        cdef char*fname = filename_byte_string

        cdef FILE*cfile
        cfile = fopen(fname, "rb")
        if cfile == NULL:
            raise FileNotFoundError(2, "No such file or directory: '%s'" % filepath)

        cdef char *line = NULL
        cdef size_t l = 0
        cdef ssize_t read

        while True:
            read = getline(&line, &l, cfile)

            if read == -1: break

            if first:
                num_row = int(line.split(' ')[0])
                dim = int(line.split(' ')[1])
                self.weights = np.zeros(shape=(num_row, dim), dtype=float)
                first = False
            else:
                line_utf = (<bytes> line).decode('utf8', errors='strict')
                word = line_utf.split()[0].rstrip()
                self.add(word)
                self.weights[self.index(word)] = list(map(float, line_utf.split()[1:]))
                rowid += 1
        fclose(cfile)

    def __enter__(Vocab self):
        self._check_alive()
        return self

    def __exit__(Vocab self, exc_tp, exc_val, exc_tb):
        if self.vocab_hash != NULL:
            self.vocab_hash = NULL  # inform __dealloc__
        if self.vocab != NULL:
            self.vocab = NULL  # inform __dealloc__
        return False  # propagate exceptions