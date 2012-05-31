XQuery Parser written in JavaScript
============================

This project compiles the XQuery grammar to JavaScript using antlr.

Dependencies
-----------
* Required
    * Dryice (https://github.com/mozilla/dryice)

```bash
npm install dryice
```
* Optionals (to run tests)
    * Walk (https://github.com/coolaj86/node-walk)
    * Require.js (https://github.com/jrburke/requirejs)

```bash
npm install walk requirejs
```

Build
-----------
To generate the parser, simply run the following command:
```bash
./Makefile.dryice
```
How to run the test suite?
-----------
```bash
node run_tests.js --keep-going
```

To parse a particular XQuery file:

```bash
node run_tests.js -f filename
```
For instance:
```bash
node run_tests.js -f queries/zorba/boolean/compare0.xq
```

Who is using this project?
-----------
ACE, aka the Cloud9 editor (https://github.com/ajaxorg/ace), is using this parser to perform XQuery syntax checking and semantic highlighting of the source code. 

