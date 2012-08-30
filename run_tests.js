var walk = require('walk');
var fs = require('fs');
var requirejs = require('requirejs');
var xquery = requirejs('./build/xquery');

String.prototype.endsWith = function(suffix) {
  return this.indexOf(suffix, this.length - suffix.length) !== -1;
};

var successes = [];
var failures  = [];

function parseFile(filename, failOnError)
{
  console.log("Parse: " + filename);
  var code = fs.readFileSync(filename, "UTF-8");
  var parser = xquery.getParser(code);
  var ast = parser.p_Module();
  parser.highlighter.getTokens();
 if(parser.hasErrors() && !failOnError) {
    var errors = parser.getErrors();
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
      failures.push(filename);
    }
    return;
  } else if(parser.hasErrors()) {
    failures.push(filename);
  } else {
    successes.push(filename);
  }
}

function main(args) {
  var keepGoing =  args.indexOf("--keep-going") != -1;
  var file      =  args.indexOf("-f");
  var path      = "./queries";
  if(file != -1)
  {
    if(args.length <= (file + 1)) {
      throw "Missing argument to -f: -f <filename>"; 
    }
    var filename = args[file + 1];
    path = "./" + filename;
    parseFile(filename, keepGoing);
  } else {
    var walker  = walk.walk(path, { followLinks: false });
    
    walker.on('file', function(root, stat, next) {
      // Add this file to the list of files
      var filename = root + '/' + stat.name;
      if(filename.endsWith(".xq")) {
        parseFile(filename, keepGoing);
      }
      next();
    });

    walker.on('end', function() {
      console.log("Parsed " + (failures.length + successes.length) + " files.");
      console.log(successes.length + " succeeded, " + failures.length + " failed.");
      console.log("The following files didn't parse: ");
      var i;
      for(i in failures)
      {
        console.log(failures[i]);
      }
    });
  }
};

main(process.argv);

