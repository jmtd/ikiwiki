package IkiWiki::Plugin::permalink;

use warnings;
use strict;
use IkiWiki '3.00';

sub import {
  hook(type => "pagetemplate", id=> "permalink", call => \&pagetemplate);
}

sub pagetemplate () {
    my %params=@_;
    $params{template}->param(permalink => urlto($params{page},"",1));
}

1;
