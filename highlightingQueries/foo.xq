module namespace s = "http://www.28msec.com/cloud9/lib/socket";

import module namespace date = "http://www.zorba-xquery.com/modules/datetime";
import module namespace random = "http://www.zorba-xquery.com/modules/random";
import module namespace base64 = "http://www.zorba-xquery.com/modules/converters/base64";
import module namespace json = "http://www.zorba-xquery.com/modules/converters/json";

import module namespace req = "http://www.28msec.com/modules/http/request";
import module namespace res = "http://www.28msec.com/modules/http/response";
import module namespace sleep = "http://www.28msec.com/modules/sleep";
import module namespace store = "http://www.28msec.com/modules/store";

declare namespace j = "http://john.snelson.org.uk/parsing-json-into-xquery";

declare %private collection s:clients as element(client);
declare %private variable $s:clients as xs:QName := xs:QName('s:clients');

declare %private %an:automatic %an:value-equality index s:client
on nodes db:collection(xs:QName('s:clients'))
by xs:string(@id) as xs:string;  
declare %private variable $s:client as xs:QName := xs:QName('s:client');

declare %private collection s:messages as element(message);
declare %private variable $s:messages as xs:QName := xs:QName('s:messages');

declare %private %an:automatic %an:value-equality index s:message
on nodes db:collection(xs:QName('s:messages'))
by xs:string(@session-id) as xs:string;
declare %private variable $s:message as xs:QName := xs:QName('s:message');

declare variable $s:disconnect     := 0;
declare variable $s:connect        := 1;
declare variable $s:heartbeat      := 2;
declare variable $s:msg            := 3;
declare variable $s:json           := 4;
declare variable $s:event          := 5;
declare variable $s:acknowledgment := 6;
declare variable $s:error          := 7;
declare variable $s:noop           := 8;

declare variable $s:heartbeat-timeout  as xs:integer := 20;
declare variable $s:connection-timeout as xs:integer := 20;

declare %private variable $s:listeners as item()* := ();

declare %private variable $s:handshake               as xs:QName := xs:QName('s:handshake');
declare %private variable $s:transport-not-supported as xs:QName := xs:QName('s:transport-not-supported');

declare %private variable $s:supported-transports as xs:string+ := "xhr-polling";

declare %private variable $s:transport   as xs:string? := ();
declare %private variable $s:session-id  as xs:string? := ();

declare function s:id() as xs:string? { $s:session-id };

declare %an:sequential function s:on($event-name as xs:string, $handler as function(*))
as empty-sequence()
{
  $s:listeners :=  ($s:listeners, $event-name, $handler);
};

declare %an:sequential function s:handler($event-name as xs:string)
as function(*)
{
  for $handler at $i in $s:listeners
  let $handler-event-name := if($handler instance of xs:string) then $handler else ()
  where $handler-event-name = $event-name
  return $s:listeners[$i + 1]
};

declare function s:clients()
as element(client)*
{
  db:collection($s:clients)
};

declare function s:get()
as element(client)?
{
  idx:probe-index-point-value($s:client, $s:session-id)
};

declare %an:sequential function s:listen()
as xs:string
{
  try {
    {
      s:handshake();
      for $message in s:messages()
      let $type := number($message/@type)
      return
        switch ($type)
          case $s:disconnect
          return s:disconnect();
        
          case $s:msg
          return
            for $handler in s:handler("message")
            return $handler($message/text());
            
          case $s:json
          return
            for $handler in s:handler("message")
            return $handler($message/text());
          
          case $s:event
          return
            let $event-name := json:parse($message/text())/j:pair[@name="name"]/text()
            for $handler in s:handler($event-name)
            return $handler($message/text());
            
        default return ();
        
      if(req:method-get()) then { 
        
        s:heartbeat();
        
        variable $messages := s:close();
        variable $timeout  := 0;
        
        if(true()) then
          (: We have a padding of 3/4 the connection timeout :)
          while(empty($messages) and $timeout lt ($s:connection-timeout * 3 div 4)) {
            sleep:millis(50);
            $messages := s:close();
            $timeout := $timeout + 0.05;
          }
        else();
        
        if(empty($messages)) then
          "8::"
        else
          $messages
          
      } else {
        "1"
      }
    }
  } catch s:handshake {
    {
      $err:description
    }
  }
};

declare %an:sequential function s:connect()
as empty-sequence()
{
  $s:session-id := random:uuid();
  variable $client := idx:probe-index-point-value($s:client, $s:session-id);
  if(empty($client)) then 
    db:insert-nodes($s:clients, <client id="{$s:session-id}" last-seen="{date:current-dateTime()}" />);
  else
    error();
  s:send-impl("1::");
  for $handler in s:handler("connect")
  return $handler($s:session-id);
};

declare %private %an:sequential function s:close()
as xs:string?
{
  store:flush();
  variable $client := idx:probe-index-point-value($s:client, $s:session-id);
  variable $messages := (
    for $message in idx:probe-index-point-value($s:message, $s:session-id)
    let $datetime := xs:dateTime($message/@datetime)
    order by $datetime ascending
    return $message);
  db:delete-nodes($messages);
  if(count($messages) = 1) then {
    $messages/text()
  } else if(empty($messages)) then {
    ()
  } else {
    string-join(
      for $message in $messages
      return
        "&#65533;" || string-length($message/text()) || "&#65533;" || $message/text()
      , "")
   }
};

declare %private %an:sequential function s:disconnect()
{
  db:delete-nodes(idx:probe-index-point-value($s:client, $s:session-id));
  for $handler in s:handler("disconnect")
  return $handler($s:session-id);
};

declare %private %an:sequential function s:heartbeat()
{
  for $disconnected in db:collection($s:clients)[(date:current-dateTime() - xs:dateTime(@last-seen)) gt xs:dayTimeDuration("PT" || $s:heartbeat-timeout || "S")]
  return {
    variable $id := string($disconnected/@id);
    db:delete-nodes($disconnected);
    for $handler in s:handler("disconnect")
    return $handler($id);
  }
  variable $client := idx:probe-index-point-value($s:client, $s:session-id);
  if(empty($client)) then {
     for $handler in s:handler("disconnect")
     return $handler($s:session-id); 
  } else {
    replace value of node $client/@last-seen with date:current-dateTime();
  }
};

declare %an:sequential function s:broadcast($event-name as xs:string, $data as xs:string)
{
  s:emit($event-name, $data, true())
};

declare %an:sequential function s:emit($event-name as xs:string, $data as xs:string)
{
  s:emit($event-name, $data, false())
};

declare %an:sequential function s:emit($event-name as xs:string, $data as xs:string, $broadcast as xs:boolean)
{
  s:send-impl("5:::" || '{"name":' || ' "' || $event-name || '", "args": [' || $data || "]}", $broadcast)
};

declare %an:sequential function s:send-impl($message as xs:string)
as empty-sequence()
{
  s:send-impl($message, false())
};

declare %private %an:sequential function s:send-impl($message as xs:string, $broadcast as xs:boolean)
as empty-sequence()
{
  for $session-id in (if($broadcast) then db:collection($s:clients)/@id/string(.) else $s:session-id)
  return
    db:insert-nodes($s:messages, 
                    <message datetime="{date:current-dateTime()}"
                             session-id="{$session-id}">{$message}</message>);
};

declare %private %an:sequential function s:handshake()
{ 
  res:set-content-type("text/plain");
  variable $segments := tokenize(req:path(), "/")[. != ""];
  $s:transport := $segments[3 + 1];
  $s:session-id := $segments[4 + 1];
  if($s:transport != $s:supported-transports) then
    error($res:service-unavailable);
  else
    ();
  (: If the transport is empty, it's an handshake :)
  if(empty($s:transport)) then {
    s:connect();
    error($s:handshake, $s:session-id || ":" || $s:heartbeat-timeout || ":" || $s:connection-timeout || ":" || string-join($s:supported-transports, ","));
  } else{}
};

declare %private function s:messages()
as element(message)*
{
  let $payload := if(req:method-get()) then () else req:text-content()
  return
    if(empty($payload)) then
      ()
    else if(not(starts-with($payload, "&#65533;"))) then
      s:parse-message($payload)
    else
      let $tokens := tokenize($payload, "&#65533;(\d)+&#65533;")[. != ""]
      for $token in $tokens
      return s:parse-message($token)
};

declare %private function s:parse-message($payload as xs:string)
as element(message)
{
  let $segments := tokenize($payload, ":")
  let $type := number($segments[1])
  let $id := $segments[2]
  let $endpoint := $segments[3]
  let $data := string-join(subsequence($segments, 4), ":")
  return
    <message id="{$id}" endpoint="{$endpoint}" type="{$type}">
    {
      $data
    }
    </message>
};

declare %private function s:serialize-message($message as element(message))
as xs:string
{
  let $type := string($message/@type)
  let $id   := string($message/@id)
  let $endpoint := string($message/@endpoint)
  let $data := $message/text()
  return
    $type || ":" || $id || ":" || $endpoint || ":" || $data
};

declare function s:foo()
{
<script type="text/javascript"><![CDATA[
$(function(){
    
});        
    //]]></script>
};
