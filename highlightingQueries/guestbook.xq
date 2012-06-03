(:
 : Copyright 2010 28msec Inc.
 :)

module namespace guestbook = "http://www.28msec.com/templates/guestbook/guestbook";

import module namespace http = "http://www.28msec.com/modules/http";

import module namespace xqddf = "http://www.zorba-xquery.com/modules/xqddf";

declare collection guestbook:entries as node()*;
declare variable $guestbook:entries as xs:QName := xs:QName("guestbook:entries");

declare %an:sequential function guestbook:add()
{
  http:set-header("Cache-Control", "no-cache");
  xqddf:insert-nodes(
      $guestbook:entries,
      <entry author="{http:get-parameters("author")}" date="{fn:current-date()}" time="{fn:current-time()}">
      {
        http:get-parameters("text")
      }
      </entry>
  );
  exit returning guestbook:list();
};

declare %an:sequential function guestbook:list() {
  http:set-header("Cache-Control", "no-cache");
  
  let $entries := for $e in xqddf:collection($guestbook:entries)
                  order by xs:date($e/@date), xs:time($e/@time)
                  return $e
  let $num_entries := fn:count($entries)
  return 
    if($num_entries = 0)
    then    
      <div class="entry"><b>No entries, yet.</b></div>
    else
      for $entry at $pos in $entries[position() gt $num_entries - 5]
      let $numbering := if ($num_entries lt 5) then $pos else $num_entries - ( 5 - $pos) 
      return <div class="entry">
                 <div class="header"><b>{string($entry/@author)}</b></div>
                 <div class="content">{$entry/text()}</div>
                 <div class="datetime">{string($entry/@datetime)}</div>
               </div>;
};