/*
 *    The detection that an identifer is actually an Ada reserved
 *  word is done via a hash function.  See SIGAda Letters V4 N1
 *  pages 40-44 for more information regarding the hash technique.
 */

#include <ctype.h>
#include <string.h>
#include "y.tab.h"

#define ERROR_TOKEN 0

typedef struct reserved_word_entry
        {
         char *text_value;
         int token_value;
        } reserved_word_entry;

static reserved_word_entry reserved_word_table[ 71 ] =
  { { "else"     , ELSE_ },
    { "exit"     , EXIT_ },
    { "end"      , END_ },
    { "at"       , AT_ },
    { "then"     , THEN_ },
    { "range"    , RANGE_ },
    { "abs"      , ABS_ },
    { "do"       , DO_ },
    { "exception", EXCEPTION_ },
    { "delay"    , DELAY_ },
    { "use"      , USE_ },
    { "xor"      , XOR_ },
    { "select"   , SELECT_ },
    { ""         , ERROR_TOKEN },
    { "declare"  , DECLARE_ },
    { "type"     , TYPE_ },
    { "array"    , ARRAY_ },
    { "limited"  , LIMITED_ },
    { "subtype"  , SUBTYPE_ },
    { "elsif"    , ELSIF_ },
    { "case"     , CASE_ },
    { "generic"  , GENERIC_ },
    { "and"      , AND_ },
    { "not"      , NOT_ },
    { "renames"  , RENAMES_ },
    { "package"  , PACKAGE_ },
    { "null"     , NULL_ },
    { "separate" , SEPARATE_ },
    { "terminate", TERMINATE_ },
    { "raise"    , RAISE_ },
    { "entry"    , ENTRY_ },
    { "reverse"  , REVERSE_ },
    { "task"     , TASK_ },
    { ""         , ERROR_TOKEN },
    { "all"      , ALL_ },
    { "constant" , CONSTANT_ },
    { "delta"    , DELTA_ },
    { "accept"   , ACCEPT_ },
    { "digits"   , DIGITS_ },
    { "return"   , RETURN_ },
    { "abort"    , ABORT_ },
    { "record"   , RECORD_ },
    { "in"       , IN_ },
    { "access"   , ACCESS_ },
    { "or"       , OR_ },
    { "function" , FUNCTION_ },
    { "goto"     , GOTO_ },
    { "others"   , OTHERS_ },
    { "rem"      , REM_ },
    { "procedure", PROCEDURE_ },
    { "out"      , OUT_ },
    { "private"  , PRIVATE_ },
    { "is"       , IS_ },
    { "mod"      , MOD_ },
    { "of"       , OF_ },
    { ""         , ERROR_TOKEN },
    { "pragma"   , PRAGMA_ },
    { "for"      , FOR_ },
    { "new"      , NEW_ },
    { "when"     , WHEN_ },
    { "with"     , WITH_ },
    { "begin"    , BEGIN_ },
    { ""         , ERROR_TOKEN },
    { "while"    , WHILE_ },
    { ""         , ERROR_TOKEN },
    { ""         , ERROR_TOKEN },
    { ""         , ERROR_TOKEN },
    { "loop"     , LOOP_ },
    { ""         , ERROR_TOKEN },
    { "if"       , IF_ },
    { "body"     , BODY_ } };

static int magic_table[ 26 ] =
  { 0, 49,   0,  -7, -20,  18,  -2, -38,  33,   0,  -9,   9,  29,
   -9,  6,  26,   0,   8,   1,   1,  -9,   0,  56, -28,  11,   0 };

int reserved_word (char *word)
{
 int    index, hash_value, word_length = strlen (word);
 char   canonical_word [1024];

 /* Check some simple things first:
      - it has the correct length, must be >= 2 and <= 9
      - it doesn't have any digits in important (for the hash) places */
  
 if ((word_length < 2) || (word_length > 9) || (isdigit (word [0]))
        || (isdigit (word [word_length - 1]))
        || (isdigit (word [word_length - 2])))
                return identifier;

  /* convert the identifier to all lower case characters */
  for ( index = 0; *word; word++, index++ )
        canonical_word[index] = tolower(*word);

  /* compute the magic hash value */
  hash_value = magic_table [canonical_word [0] - 'a'] +
               magic_table [canonical_word [word_length - 1] - 'a'] +
               (2 * (canonical_word [word_length - 2] - 'a')) + word_length;

  if ((hash_value >= 0) && (hash_value <= 70) &&
        (strncmp (canonical_word, reserved_word_table [hash_value].text_value,
                word_length) == 0))
                        return reserved_word_table[hash_value].token_value;
  else 
        return identifier;
}
