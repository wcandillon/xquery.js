var walk = require('walk');
var fs = require('fs');
var requirejs = require('requirejs');

String.prototype.endsWith = function(suffix) {
  return this.indexOf(suffix, this.length - suffix.length) !== -1;
};

function main(args) {
  // Walker options
  var walker  = walk.walk('./queries', { followLinks: false });
  var xquery = requirejs('./build/xquery');

  walker.on('file', function(root, stat, next) {
    // Add this file to the list of files
    var filename = root + '/' + stat.name;
    if(filename.endsWith(".xq")) {
      console.log(filename);
      var code = fs.readFileSync(filename, "UTF-8");
      //output += "<pre><![CDATA[" + code + "]]></pre>";
      var parser = xquery.getParser(code);
      var ast = parser.p_Module();
      parser.highlighter.getTokens();
      //console.log(parser.highlighter.getTokens());
     if(parser.hasErrors()) {
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
        }
      }   
    }
    next();
  });

  walker.on('end', function() {
    //console.log(files);
  });
};

main(process.argv);

