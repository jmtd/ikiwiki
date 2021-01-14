#!/usr/bin/perl
package IkiWiki;
use warnings;
use strict;
use Test::More tests => 11;

# We check for English error messages
$ENV{LC_ALL} = 'C';

BEGIN { use_ok("IkiWiki"); }
BEGIN { use_ok("IkiWiki::Plugin::alias"); }

$config{srcdir} = 't/pagespec_alias/src';
$config{wiki_file_chars} = "-[:alnum:]+/.:_";
$config{pagespec_aliases} = {
	"foo" => "bar",
	"baz" => "qaz",
	"alpha" => "beta()",
	"beta" => "gamma",
};

is(checkconfig(), 1, "basic config passes");

ok(  pagespec_match("bar", "foo()"), "alias match test");
ok(! pagespec_match("bar", "baz()"), "alias doesn't match test");
ok(  pagespec_match("gamma", "alpha()"), "chained aliases match");
ok(! pagespec_match("beta", "alpha()"), "pagespecs vs pagenames");

# Note: the existing aliases from prior tests are not cleared. The aliases
# in the following tests have been chosen with this in mind.

$config{pagespec_aliases} = {
	"link" => "foo",
};
# eval to test code that calls "die". We could instead use dies_ok from Test::Exception
eval { checkconfig(); };
like($@, qr/PageSpec already defined for alias 'link'/, "checkconfig catches a name already defined elsewhere");

$config{pagespec_aliases} = {
	"fnord" => "fnord()",
};
checkconfig();
eval { pagespec_match("anything", "fnord()"); };
like($@, qr/PageSpec alias defined recursively/, "recursive aliases are detected (1 level)");

$config{pagespec_aliases} = {
        "gamma" => "epsilon()",
        "epsilon" => "gamma()",
};
checkconfig();
eval { pagespec_match("anything", "gamma()"); };
like($@, qr/PageSpec alias defined recursively/, "recursive aliases are detected (2 level)");

$config{pagespec_aliases} = {
	"f☺oo" => "bar",
};
eval { checkconfig(); };
like($@, qr/Only word-characters are permitted in PageSpec aliases/, "checkconfig catches an invalid alias name");
