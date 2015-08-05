j
========

micro json parser in 20 lines of bash

features
--------
- parses correctly all the correct input, garbage in garbage out
- up to 1000 elements (can easily be extended if needed)
- an example pretty printer, just to show how it can be used

notes
--------
- needs bash 4.3 or above
- push simulate stacks with arrays
- most of the state is kept in global variables to save a few expansions
  - list must be a global nameref
  - tr is basically an array to precompute the output of  tr 0-9 a-j <<< "$var"
- list of annoying things:
  - whitespace
  - strings that include whitespace
  - numbers
  - the lack of pcre's non greedy `.*?`
- LANG=C makes string slicing faster and it's needed for the character classes

bugs
--------
- bash is really slow at handling long strings
- it's easy to craft some *invalid* json that will be marked as valid



tests
--------
send json to stdin and j will pretty print it
```
$ ./j <<< '{"1":2,"3":{"4":[null,true,false,{"foo   \\  \"è\u00C8":[{},[]]}]}}'
{
  "1": 2,
  "3": {
    "4": [
      null,
      true,
      false,
      {
        "foo   \  \"èÈ": [
          {},
          []
        ]
      }
    ]
  }
}
```
