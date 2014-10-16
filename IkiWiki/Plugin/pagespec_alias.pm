package IkiWiki::Plugin::pagespec_alias;
# Copyright © 2011 Jon Dowland <jmtd@debian.org>
# Licensed under the GNU GPL, version 2, or any later version published by the
# Free Software Foundation

use warnings;
use strict;
use IkiWiki '3.00';
use File::Basename;

sub import {
  hook(type => "getsetup", id=> "pagespec_alias", call => \&getsetup);
  hook(type => "checkconfig", id=> "pagespec_alias", call => \&checkconfig);
}

sub getsetup () {
    return
        plugin => {
            description => "define aliases to pagespecs to ease re-use",
            safe => 0,
            rebuild => 1,
            section => "misc",
        },
        pagespec_aliases => {
            type => "string",
            example => { image => "*.png or *.jpg or *.gif" },
            description => "a list of mappings, alias to pagespec",
            safe => 1,
            rebuild => 0,
        },
}

# ensure user-defined pagespec aliases are composed of word-characters only
sub safe_key {
  my $key = shift;
  return 1 if $key =~ /^\w+$/;
  0;
}

sub checkconfig () {
    no strict 'refs';
    no warnings 'redefine';

    if ($config{pagespec_aliases}) {
        foreach my $key (keys %{$config{pagespec_aliases}}) {
	    next unless safe_key($key);
            my $value = ${$config{pagespec_aliases}}{$key};
            my $subname = "IkiWiki::PageSpec::match_$key";
            *{ $subname } = sub {
              my $path = shift;
              shift;
              return IkiWiki::pagespec_match($path, $value, @_);
            }
        }
    }
}

1;
