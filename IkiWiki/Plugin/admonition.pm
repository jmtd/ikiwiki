#!/usr/bin/perl
# Copyright 2016 Antoine Beaupré
# Released under GPL version 2

package IkiWiki::Plugin::admonition;
use utf8;
use strict;
use warnings;
use IkiWiki 3.0;

sub import {
	hook(type => "getsetup", id => "admonition", call => \&getsetup);
	# ikiwiki doesn't pass the id, so make multiple subs
	foreach my $directive (qw(warning caution important note tip)) {
		hook (type => "preprocess", id => $directive, call => sub { preprocess(@_, id => $directive)})
	}
}

sub preprocess {
	my %params = @_;
	my $text = shift;
	my $format = pagetype($pagesources{$params{page}});
        if (!$format) {
            print STDERR "undetermined format for page $params{page}, defaulting to mdwn\n";
            $format = 'mdwn';
        }
	$text = IkiWiki::preprocess($params{page}, $params{destpage}, $text);
	$text = IkiWiki::htmlize($params{page}, $params{destpage}, $format, $text);
	# we use 'id' here instead of class because that's the hook
	# keyword above, but it's really a class we're setting, so that we
	# can reuse it multiple times.
	return "<div class=\"". $params{'id'} . "\">$text</div>";
}

sub getsetup () {
	return
		plugin => {
			safe => 1,
			rebuild => undef,
			section => "core",
		},
}
1;
