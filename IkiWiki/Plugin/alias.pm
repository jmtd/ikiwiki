package IkiWiki::Plugin::alias;
# Copyright © 2011 Jon Dowland <jmtd@debian.org>
# Licensed under the GNU GPL, version 2, or any later version published by the
# Free Software Foundation

use warnings;
use strict;
use IkiWiki '3.00';
use File::Basename;

sub import {
  hook(type => "getsetup", id=> "alias", call => \&getsetup);
  hook(type => "checkconfig", id=> "alias", call => \&checkconfig);
}

sub getsetup () {
    return
        plugin => {
            description => "define aliases to PageSpecs to ease re-use",
            safe => 0,
            rebuild => 1,
            section => "link",
        },
        pagespec_aliases => {
            type => "string",
            example => { images => "*.png or *.jpg or *.gif" },
            description => "a list of alias: PageSpec mappings",
        },
}

# ensure user-defined PageSpec aliases are composed of word-characters only
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
            error(gettext("Only word-characters are permitted in PageSpec aliases"))
                unless safe_key($key);
            my $value = ${$config{pagespec_aliases}}{$key};
            my $subname = "IkiWiki::PageSpec::match_$key";

            error(gettext("PageSpec already defined for alias ")."'$key'")
                if ref *$subname{CODE};

            my $entered;
            *{ $subname } = sub {
              my $path = shift;
              error(gettext("PageSpec alias defined recursively: ")."'$key'") if $entered;
              $entered = 1;
              my $result = IkiWiki::pagespec_match($path, $value);
              $entered = 0;
              return $result;
            }
        }
    }
}

1;
