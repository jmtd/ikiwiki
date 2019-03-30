#!/usr/bin/perl
# duckduckgo search form plugin
# Copyright © 2019 Jonathan Dowland <jon@dow.land>
# based on the google search form plugin by Peter Simons <simons@cryp.to>
# Licensed under the GNU GPL, version 2, or any later version published by the
# Free Software Foundation
package IkiWiki::Plugin::duckduckgo;

use warnings;
use strict;
use IkiWiki 3.00;
use URI;

sub import {
	hook(type => "getsetup", id => "duckduckgo", call => \&getsetup);
	hook(type => "checkconfig", id => "duckduckgo", call => \&checkconfig);
	hook(type => "pagetemplate", id => "duckduckgo", call => \&pagetemplate);
}

sub getsetup () {
	return
		plugin => {
			safe => 1,
			rebuild => 1,
			section => "web",
		},
}

sub checkconfig () {
	if (! length $config{url}) {
		error(sprintf(gettext("Must specify %s when using the %s plugin"), "url", 'duckduckgo'));
	}
	
	# This is a mass dependency, so if the search form template
	# changes, every page is rebuilt.
	add_depends("", "templates/duckduckgoform.tmpl");
}

my $form;
sub pagetemplate (@) {
	my %params=@_;
	my $page=$params{page};
	my $template=$params{template};

	# Add search box to page header.
	if ($template->query(name => "searchform")) {
		if (! defined $form) {
			my $searchform = template("duckduckgoform.tmpl", blind_cache => 1);
			$searchform->param(url => $config{url});
			$searchform->param(html5 => $config{html5});
			$form=$searchform->output;
		}

		$template->param(searchform => $form);
	}
}

1
