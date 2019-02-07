#!/usr/bin/perl
use warnings;
use strict;
use Test::More;

BEGIN { use_ok("IkiWiki"); }

# pagetitle(x) => XML-escaped form of page title
is(pagetitle("foo_bar"), "foo bar");
is(pagetitle("foo_bar_baz"), "foo bar baz");
is(pagetitle("foo_bar__33__baz"), "foo bar&#33;baz");
# &#1234 is U+04D2 CYRILLIC CAPITAL LETTER A WITH DIAERESIS
is(pagetitle("foo_bar__1234__baz"), "foo bar&#1234;baz", 'Unicode in BMP');
# &#8800 is U+2260 NOT EQUAL TO
is(pagetitle("foo_bar__8800__baz"), "foo bar&#8800;baz", 'Unicode in BMP');
is(pagetitle("foo_bar___33___baz"), "foo bar &#33; baz", 'Exclamation mark');
is(pagetitle("foo_bar___95___baz"), "foo bar &#95; baz", 'Underscore');
is(pagetitle("中文"), "中文", 'Chinese');
is(pagetitle("Кириллица"), "Кириллица", 'Cyrillic');
# Outside basic multilingual plane: &#128169 is U+1F4A9 PILE OF POO
is(pagetitle("foo_bar__128169__baz"), "foo bar&#128169;baz", 'Unicode outside BMP');

# pagetitle(x, false) => same
is(pagetitle("foo_bar__33__baz", 0), "foo bar&#33;baz");
is(pagetitle("foo_bar__1234__baz", undef), "foo bar&#1234;baz", 'Unicode in BMP');
is(pagetitle("foo_bar__8800__baz", undef), "foo bar&#8800;baz", 'Unicode in BMP');
is(pagetitle("foo_bar___33___baz", ""), "foo bar &#33; baz", 'Exclamation mark');
is(pagetitle("foo_bar___95___baz", 0), "foo bar &#95; baz", 'Underscore');
is(pagetitle("中文", 0), "中文", 'Chinese');
is(pagetitle("Кириллица", 0), "Кириллица", 'Cyrillic');
is(pagetitle("foo_bar__128169__baz", 0), "foo bar&#128169;baz", 'Unicode outside BMP');

# pagetitle(x, true) => unescaped form of page title
is(pagetitle("foo_bar", 1), "foo bar");
is(pagetitle("foo_bar_baz", 'unescaped'), "foo bar baz");
is(pagetitle("foo_bar__33__baz", 42), "foo bar!baz");
is(chr(1234), "\x{04D2}");
is(pagetitle("foo_bar__1234__baz", 1), "foo bar\x{04D2}baz", 'Unicode in BMP');
is(chr(8800), "\x{2260}");
is(pagetitle("foo_bar__8800__baz", 1), "foo bar\x{2260}baz", 'Unicode in BMP');
is(pagetitle("foo_bar___33___baz", 1), "foo bar ! baz");
is(pagetitle("foo_bar___95___baz", 1), "foo bar _ baz");
is(pagetitle("中文", 1), "中文", 'Chinese');
is(pagetitle("Кириллица", 1), "Кириллица", 'Cyrillic');
is(chr(128169), "\x{0001F4A9}");
is(pagetitle("foo_bar__128169__baz", 1), "foo bar\x{0001F4A9}baz", 'Unicode outside BMP');

done_testing;
