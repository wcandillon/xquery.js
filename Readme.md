XQuery Parser written in JavaScript
============================

This project compiles the XQuery grammar to JavaScript using antlr.

Dependencies
-----------
 * Dryice (https://github.com/mozilla/dryice)

```bash
npm install dryice
```

Build
-----------
To generate the parser, simply run the following command:
```bash
./Makefile.dryice
```

Who is using this project?
-----------
ACE, aka the Cloud9 editor (https://github.com/ajaxorg/ace), is using this parser to perform XQuery syntax checking and semantic highlighting of the source code. 

