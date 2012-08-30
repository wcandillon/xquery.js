var fs = require('fs');
var requirejs = require('requirejs');
var xquery = requirejs('./build/xquery');
var tree = requirejs('./treehugger/tree');

"use strict";

function getPosition(input, start, stop)
{
  var lines = input.split("\n");
  var i = 0, startline, startcolumn, endline, endcolumn, cursor = 0;
  for(i in lines)
  {
    var line = lines[i];
    if(startline === undefined && (cursor + line.length) > start && cursor < start)
    {
      startline = i;
      startcolumn = start - cursor;
    }
    if(endline === undefined && (cursor + line.length) > stop && cursor < stop)
    {
      endline = i;
      endcolumn = stop - cursor;
      return {sl: startline, sc: startcolumn, el: endline, ec: endcolumn};
    }    
    cursor += line.length;
  }
}

function showSource(input, pos)
{
  var lines = input.split("\n");
  var i = 0;
  console.log(lines[pos.sl].substring(pos.sc));
  for(i in lines)
  {
    if(i > pos.sl && i < pos.el)
    {
      console.log(lines[i]);   
    }
  }
  console.log(lines[pos.el].substring(0, pos.ec));
}

function convert(input, ast)
{
  if(ast.children !== undefined)
  {
    var children = [];
    var child;
    for(child in ast.children)
    {
      var r = convert(input, ast.children[child]);
      if(r !== null) {
        children.push(r);
      }
    }
    var node = tree.cons(ast.token.text, children);
    var pos = getPosition(input, ast.startIndex, ast.stopIndex);
    console.log(ast.token.text);
    showSource(input, pos);
    node.setAnnotation("pos", pos);
    return node;
  } else if(ast.token.text !== null) {
    var node = tree.string(ast.token.text);
    var pos = getPosition(input, ast.startIndex, ast.stopIndex);
    console.log(ast.token.text);
    showSource(input, pos);
    node.setAnnotation("pos", pos);
    return node;
  } else if(ast.token.text === null) {
    var terminal = ast.token.input.substring(ast.token.start, ast.token.stop);
    var node = tree.string(terminal);
    var pos = getPosition(input, ast.startIndex, ast.stopIndex);
    console.log(terminal);
    showSource(input, pos);
    node.setAnnotation("pos", pos);
    return node;
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
    var t = convert(code, ast.getTree());
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
