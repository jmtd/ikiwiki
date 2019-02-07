#!/usr/bin/perl
use warnings;
use strict;
use Test::More;
use utf8;

BEGIN { use_ok("IkiWiki"); }

is(linkpage("foo bar"), "foo_bar");
is(linkpage("foo bar baz"), "foo_bar_baz");
is(linkpage("foo bar/baz"), "foo_bar/baz");
is(linkpage("foo bar&baz"), "foo_bar__38__baz");
is(linkpage("foo bar & baz"), "foo_bar___38___baz");
is(linkpage("foo bar_baz"), "foo_bar_baz");
is(chr(95), '_');
is(linkpage("foo bar__95__baz"), "foo_bar__95__baz", 'underscore');
is(linkpage("foo bar\xACbaz"), "foo_bar__172__baz", 'U+00AC is in Latin-1 range');
is(linkpage("foo bar\x{04D2}baz"), "foo_bar\x{04D2}baz", 'U+04D2 is alphanumeric');
is(linkpage("foo bar\x{2260}baz"), "foo_bar__8800__baz", 'U+2260 is nonalphanumeric');
is(linkpage("中文"), "中文", 'Chinese');
is(linkpage("Кириллица"), "Кириллица", 'Cyrillic');
is(linkpage("foo bar\x{0001F4A9}baz"), "foo_bar__128169__baz", 'U+1F4A9 is outside BMP');

done_testing;
