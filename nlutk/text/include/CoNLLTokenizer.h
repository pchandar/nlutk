#ifndef CONLL_TOKENIZER_H
#define CONLL_TOKENIZER_H

#include <string>
#include <iostream>
#include <sstream>
#include <fstream>
#include <ctype.h>


using namespace std;

namespace nlutk {

class Token {
 public:
  Token(std::string _text, long _offset) : text(_text), offset(_offset) { }

  std::string text;
  unsigned long offset;
};

class conll_tokenizer {
 public:
  typedef std::string token_type;

  conll_tokenizer() : in(0), current_stream_offset(0) { }

  conll_tokenizer(std::istream &in_) : in(&in_), current_stream_offset(0) { }


  bool operator()(std::string &token) {
    unsigned long ignored;
    return (*this)(token, ignored);
  }

  bool operator()(std::string &token, unsigned long &token_offset) {
    bool result = get_next_token(token, token_offset);
    // Check if token has a UTF-8 ’ character in it and if so then split it into
    // two tokens based on that.
    for (unsigned long i = 1; i < token.size(); ++i) {
      if ((unsigned char) token[i] == 0xE2 &&
          i + 2 < token.size() &&
          (unsigned char) token[i + 1] == 0x80 &&
          (unsigned char) token[i + 2] == 0x99) {
        // Save the second half of the string as the next token and return the
        // first half.
        next_token_offset = token_offset + i;
        next_token = token.substr(i + 2);
        next_token[0] = '\'';
        token.resize(i);
        return result;
      }
    }

    return result;
  }

 private:

  bool get_next_token(std::string &token, unsigned long &token_offset) {
    if (next_token.size() != 0) {
      token.swap(next_token);
      next_token.clear();
      token_offset = next_token_offset;
      return true;
    }
    token_offset = current_stream_offset;
    token.clear();
    if (!in)
      return false;

    while (in->peek() != EOF) {
      const char ch = (char) in->peek();
      if (ch == '\'') {
        if (token.size() != 0) {
          return true;
        }
        else {
          token += get_next_char();
        }
      }
      else if (ch == '[' ||
          ch == ']' ||
          ch == '.' ||
          ch == '(' ||
          ch == ')' ||
          ch == '!' ||
          ch == ',' ||
          ch == '"' ||
          ch == ':' ||
          ch == '|' ||
          ch == '?') {
        if (token.size() == 0) {
          token += get_next_char();
          return true;
        }
        else if (ch == '.' && (token.size() == 1 ||
            (token.size() >= 1 && token[token.size() - 1] == '.') ||
            (token.size() >= 2 && token[token.size() - 2] == '.'))) {
          token += get_next_char();
        }
          // catch stuff like Jr.  or St.
        else if (ch == '.' && token.size() == 2 && isupper(token[0]) && islower(token[1])) {
          get_next_char(); // but drop the trailing .
          return true;
        }
        else {
          // if this is a number followed by a comma or period then just keep
          // accumulating the token.
          const char last = token[token.size() - 1];
          if ((ch == ',' || ch == '.') && '0' <= last && last <= '9') {
            token += get_next_char();
          }
          else {
            return true;
          }
        }
      }
      else if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
        // discard whitespace
        get_next_char();
        if (token.size() != 0)
          return true;
        else
          ++token_offset;
      }
      else {
        token += get_next_char();
      }
    }

    if (token.size() != 0) {
      return true;
    }
    return false;
  }

  inline char get_next_char() {
    ++current_stream_offset;
    return (char) in->get();
  }

  std::istream *in;
  std::string next_token;
  unsigned long current_stream_offset;
  unsigned long next_token_offset;
};

std::vector<Token*> conll_tokenize(const std::string text, unsigned long **token_offsets) {
  assert(text);
  assert(token_offsets);

  // first tokenize the text
  std::istringstream sin(text);
  conll_tokenizer tok(sin);
  std::vector <Token*> tokens;
  string word;
  unsigned long offset;
  while (tok(word, offset))
    tokens.push_back(new Token(word, offset));
  return tokens;
}
}


#endif // CONLL_TOKENIZER_H_
