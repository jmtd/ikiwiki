#!/usr/bin/perl
package IkiWiki;
use warnings;
use strict;
use Test::More tests => 6;

BEGIN { use_ok("IkiWiki"); }
BEGIN { use_ok("IkiWiki::Plugin::pagespec_alias"); }

ok(! system("rm -rf t/pagespec_alias/dest"));

$config{srcdir} = 't/pagespec_alias/src';
$config{wiki_file_chars} = "-[:alnum:]+/.:_";
$config{pagespec_aliases} = {
	"foo" => "bar",
	"baz" => "qaz",
	"alpha" => "beta()",
	"beta" => "gamma",
};

is(checkconfig(), 1);

ok(  pagespec_match("bar", "foo()"), "alias match test");
ok(! pagespec_match("bar", "baz()"), "alias doesn't match test");
ok(  pagespec_match("gamma", "alpha()"), "chained aliases match");
ok(! pagespec_match("beta", "alpha()"), "pagespecs vs pagenames");
