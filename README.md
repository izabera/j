j
========

micro json parser in 20 lines of bash

features
--------
- parses correctly all the correct input, garbage in garbage out
- up to 1000 elements (can easily be extended if needed)
- field extraction (the syntax is easy, example below)
- pretty printing

faq (questions i've been asked 1+ times)
--------
- how does it work?

  we extract blocks from the json string, put them in arrays and replace them
  with a "pointer" to that element.

  here's a simplified example:

  ```
  json='{"x":"y"}'                                  original json string
  "x"                                               identify first string
  strings_array=([0]='"x"')                         put it into an array
  json='{string0:"y"}'                              replace with pointer
  "y"                                               identify second string
  strings_array=([0]='"x"' [1]='"y"')               goes into array
  json='{string0:string1}'                          replaced with pointer
  {string0:string1}                                 identify object
  objects_array=([0]='{string0:string1}')           put object into array
  json='object0'                                    replace with pointer
  ```
  
- why do you claim it's 20 lines?  i count more

  the *parser* is 20 lines.  then there's a `print` function (which of course
  is not part of the parser) then there's a small loop to select what to print.

notes
--------
- needs bash 4.3 or above
- push simulates stacks with arrays
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

fields can be extracted this way:
```
$ ./j 'obj->"foo"' 'arr->1' 'obj->"baz"' <<< '{"foo":["bar",{"baz":"bat"}]}'
"bat"
```
