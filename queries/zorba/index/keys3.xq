import module namespace ddl = "http://www.zorba-xquery.com/modules/store/static/collections/ddl";
import module namespace dml = "http://www.zorba-xquery.com/modules/store/static/collections/dml";
import module namespace index_ddl = "http://www.zorba-xquery.com/modules/store/static/indexes/ddl";
import module namespace index_dml = "http://www.zorba-xquery.com/modules/store/static/indexes/dml";

import module namespace keys-lib = "http://www.example.com/" at "keys_mod.xqlib";

ddl:create(xs:QName("keys-lib:foo"));
index_ddl:create(xs:QName("keys-lib:FooIdx3"));

for $i in 1 to 10
return
  dml:insert-nodes(xs:QName("keys-lib:foo"),
    if ($i mod 5 eq 0) then <foo id="{$i}" name="me"/> else <foo id="{$i}"/>
  );

let $keys := index_dml:keys(xs:QName("keys-lib:FooIdx3"))
return
  <keys>{
    $keys
  }</keys>
