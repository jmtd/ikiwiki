#!/usr/bin/perl

package IkiWiki;

use warnings;
use strict;
use Test::More tests => 17;
use Encode;

BEGIN { use_ok("IkiWiki"); }
BEGIN { use_ok("IkiWiki::Render"); }
BEGIN { use_ok("IkiWiki::Plugin::admonition"); }
BEGIN { use_ok("IkiWiki::Plugin::mdwn"); }
BEGIN { use_ok("IkiWiki::Plugin::format"); }

# Initialize plugins, cargo-culted from htmlize.t
%config=defaultconfig();
$config{srcdir}=$config{destdir}="/dev/null";
ok(loadplugins(), 'load plugins');
ok(checkconfig(), 'check config');

# base set of pages, more or less inspired by map.t
%IkiWiki::pagesources = ('inliner.mdwn' => "inliner.html", 'inlinee.mdwn' => "inlinee.html");

# simplest possible processing pipeline
sub render_quick {
    my $content = shift;
    $content = preprocess('inliner.mdwn', 'inlinee.mdwn', $content);
    $content = htmlize('inliner.mdwn', 'inlinee.mdwn', 'mdwn', $content);
    return $content;
}

# check all known admonition types
foreach my $type (qw/tip note important caution warning/) {
    like(render_quick("[[!$type foo]]"), qr!<div class="$type">foo</div>\s+!, $type);
}
my $rendered = '<div class="tip">foo <em>bar</em> baz</div>\s*';
my $not_rendered = '<div class="tip">foo \*bar\* baz</div>\s*';
like(render_quick('[[!tip "foo *bar* baz"]]'), qr/$rendered/, 'directive renders');
like(render_quick('<div class="tip">foo *bar* baz</div>'), qr!$not_rendered!, 'no rendering because mdwn dislike blocks');
like(render_quick('&nbsp;<div class="tip">foo *bar* baz</div>'), qr!&nbsp;$rendered!, 'nsbp makes blocks rendered');
like(render_quick('<span/><div class="tip">foo *bar* baz</div>'), qr!<span />$rendered!, 'span makes blocks rendered');
like(render_quick('<span/><div class="tip">[[!format mdwn "foo *bar* baz"]]</div>'), qr!<span />$rendered!, '[[!format]] rendered inside div');
