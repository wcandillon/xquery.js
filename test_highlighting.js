var walk = require('walk');
var fs = require('fs');
var requirejs = require('requirejs');

String.prototype.endsWith = function(suffix) {
  return this.indexOf(suffix, this.length - suffix.length) !== -1;
};

String.prototype.encodeHTML = function () {
   return this.replace(/&/g, '&amp;')
              .replace(/</g, '&lt;')
              .replace(/>/g, '&gt;')
              .replace(/"/g, '&quot;');
};

function main(args) {
  // Walker options
  var walker  = walk.walk('./highlightingQueries', { followLinks: false });
  var xquery = requirejs('./build/xquery');
  var output = "<html><head>" +
    "<link media='all' rel='stylesheet'  href='main.css'></link>" +
    "<script type='text/javascript' src='require.js'></script>" +
    "<script type='text/javascript' src='jquery-1.7.2.js'></script>" +
    "<script type='text/javascript' src='main.js'></script>" + 
    "<style type='text/css'>body { font-family: Monaco, Menlo, 'Ubuntu Mono', 'Droid Sans Mono', Consolas, monospace; font-size: 14px; }</style></head><body>";

  walker.on('file', function(root, stat, next) {
    // Add this file to the list of files
    var filename = root + '/' + stat.name;
    if(filename.endsWith(".xq")) {
      console.log(filename);
      var code = fs.readFileSync(filename, "UTF-8");
      //output += "<pre><![CDATA[" + code + "]]></pre>";
      var parser = xquery.getParser(code);
      var ast = parser.p_Module();
      //console.log(parser.highlighter.getTokens());
      output += "<pre class='ace-tm'>";
      var lines = parser.highlighter.getTokens().lines;
      for(i in lines)
      {
        output += "<span class='ace_line'>";
        var line = lines[i];
        for(j in line)
        {
          var token = line[j];
          var types = token.type.split(".");
          output += "<span class='ace_" + types.join(" ace_") + "'>" + token.value.encodeHTML() + "</span>";
        }
        output += "<span><br />";
      }
      output += "</pre>";
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
    output += "</body></html>";
    var fd = fs.openSync("html/index.html", "w+"); 
    fs.writeSync(fd, output, 0, "UTF-8");    
    //console.log(files);
  });
};

main(process.argv);

