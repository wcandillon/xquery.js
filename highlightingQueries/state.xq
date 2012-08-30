db:insert-nodes($a:accounts, <account username="{$username}"
                                      password="{hash:sha1($password)}"
                                      email="{$email}" />);
