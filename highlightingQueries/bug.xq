http:send-request(<http:request method="get"
                                href="{$get-file || $filePath}"
                                override-media-type="text/plain">{$header-getfile}</http:request>)[2]
