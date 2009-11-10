#!/usr/bin/perl
# Ikiwiki tag2 plugin.
package IkiWiki::Plugin::tag2;

use warnings;
use strict;
use IkiWiki 3.00;

my %tags;

sub import {
	hook(type => "getopt", id => "tag2", call => \&getopt);
	hook(type => "getsetup", id => "tag2", call => \&getsetup);
	hook(type => "preprocess", id => "tag2", call => \&preprocess_tag2, scan => 1);
	hook(type => "preprocess", id => "tag2link", call => \&preprocess_tag2link, scan => 1);
	hook(type => "pagetemplate", id => "tag2", call => \&pagetemplate);
}

sub getopt () {
	eval q{use Getopt::Long};
	error($@) if $@;
	Getopt::Long::Configure('pass_through');
	GetOptions("tag2base=s" => \$config{tag2base});
}

sub getsetup () {
	return
		plugin => {
			safe => 1,
			rebuild => undef,
		},
		tag2base => {
			type => "string",
			example => "tag2",
			description => "parent page tags are located under",
			safe => 1,
			rebuild => 1,
		},
}

sub tag2page ($) {
	my $tag2=shift;
			
	if ($tag2 !~ m{^\.?/} &&
	    defined $config{tag2base}) {
		$tag2="/".$config{tag2base}."/".$tag2;
		$tag2=~y#/#/#s; # squash dups
	}

	return $tag2;
}

sub tag2link ($$$;@) {
	my $page=shift;
	my $destpage=shift;
	my $tag2=shift;
	my %opts=@_;

	return htmllink($page, $destpage, tag2page($tag2), %opts);
}

sub preprocess_tag2 (@) {
	if (! @_) {
		return "";
	}
	my %params=@_;
	my $page = $params{page};
	delete $params{page};
	delete $params{destpage};
	delete $params{preview};

	foreach my $tag2 (keys %params) {
		$tag2=linkpage($tag2);
		$tags{$page}{$tag2}=1;
		# hidden WikiLink
		add_link($page, tag2page($tag2));
	}
		
	return "";
}

sub preprocess_tag2link (@) {
	if (! @_) {
		return "";
	}
	my %params=@_;
	return join(" ", map {
		if (/(.*)\|(.*)/) {
			my $tag2=linkpage($2);
			$tags{$params{page}}{$tag2}=1;
			add_link($params{page}, tag2page($tag2));
			return tag2link($params{page}, $params{destpage}, $tag2,
				linktext => pagetitle($1));
		}
		else {
			my $tag2=linkpage($_);
			$tags{$params{page}}{$tag2}=1;
			add_link($params{page}, tag2page($tag2));
			return tag2link($params{page}, $params{destpage}, $tag2);
		}
	}
	grep {
		$_ ne 'page' && $_ ne 'destpage' && $_ ne 'preview'
	} keys %params);
}

sub pagetemplate (@) {
	my %params=@_;
	my $page=$params{page};
	my $destpage=$params{destpage};
	my $template=$params{template};

	$template->param(tags => [
		map { 
			link => tag2link($page, $destpage, $_, rel => "tag2")
		}, sort keys %{$tags{$page}}
	]) if exists $tags{$page} && %{$tags{$page}} && $template->query(name => "tags");

	if ($template->query(name => "categories")) {
		# It's an rss/atom template. Add any categories.
		if (exists $tags{$page} && %{$tags{$page}}) {
			$template->param(categories => [map { category => $_ },
				sort keys %{$tags{$page}}]);
		}
	}
}

package IkiWiki::PageSpec;

sub match_tagged2 ($$;@) {
	my $page = shift;
	my $glob = shift;
	return match_link($page, IkiWiki::Plugin::tag2::tag2page($glob));
}

1
