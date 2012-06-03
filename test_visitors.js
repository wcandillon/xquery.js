var fs = require('fs');
var requirejs = require('requirejs');
var xquery = requirejs('./build/xquery');
var tree = requirejs('./treehugger/tree');

"use strict";

function convert(ast)
{
  if(ast.children !== undefined)
  {
    var children = [];
    var child;
    for(child in ast.children)
    {
      var r = convert(ast.children[child]);
      if(r !== null) {
        children.push(r);
      }
    }
    return tree.cons(ast.token.text, children);
  } else if(ast.token.text !== null) {
    return tree.string(ast.token.text);
  } else if(ast.token.text === null) {
    return tree.string(ast.token.input.substring(ast.token.start, ast.token.stop));
  } else {
    return null;
  }
}

function parseFile(filename)
{
  console.log("Parse: " + filename);
  var code = fs.readFileSync(filename, "UTF-8");
  var parser = xquery.getParser(code);
  var ast = parser.p_Module();
 if(parser.hasErrors()) {
    var errors = parser.getErrors();
    var i;
    for(i in errors) {
      var error = errors[i];
      console.log(error);
      var problem = {
        row: error.line,
        column: error.column,
        text: error.message,
        type: "error"
      };
      console.log(problem);
    }
    return;
  } else {
    var t = convert(ast.getTree());
    console.log(ast.getTree().toStringTree());
    console.log(t.toString());
  }
}

function main(args)
{
  var file = args.indexOf("-f");
  if(file != -1)
  {
    if(args.length <= (file + 1)) {
      throw "Missing argument to -f: -f <filename>"; 
    }
    var filename = args[file + 1];
    path = "./" + filename;
    parseFile(filename);
  } else {
    throw "Missing argument to -f: -f <filename>"; 
  }
}

main(process.argv);
