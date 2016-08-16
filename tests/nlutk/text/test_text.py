from nlutk.text import text_to_word_sequence, tokenize, stem, Vocab


def test_tokenize():
    assert [('test', 0), ('string', 5)] == tokenize("test string")


def test_tokenize_punct():
    assert [('Mr', 0), ('X', 4), (',', 5), ('or', 7), ('y', 10)] == tokenize("Mr. X, or y")


def test_porter_stemmer():
    assert stem('testing') == 'test'


def test_text_to_word_sequence():
    v = Vocab()
    seq = text_to_word_sequence(v, 'sample text', stem=False, normalize_url=False,
                                normalize_number=False, lower=True)
    assert seq[0] == 0
    assert seq[2] == 1
