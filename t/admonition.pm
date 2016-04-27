#!/usr/bin/perl

package IkiWiki;

use warnings;
use strict;
use Test::More tests => 13;
use Encode;

BEGIN { use_ok("IkiWiki"); }
BEGIN { use_ok("IkiWiki::Render"); }
BEGIN { use_ok("IkiWiki::Plugin::admonition"); }
BEGIN { use_ok("IkiWiki::Plugin::mdwn"); }
BEGIN { use_ok("IkiWiki::Plugin::format"); }

# Initialize htmlscrubber plugin
%config=IkiWiki::defaultconfig();
$config{srcdir}=$config{destdir}="/dev/null";
IkiWiki::loadplugins();
IkiWiki::checkconfig();
%IkiWiki::pagesources = ('inliner.mdwn' => "inliner.html", 'inlinee.mdwn' => "inlinee.html");

sub render_quick {
    my $content = shift;
    $content = IkiWiki::preprocess('inliner.mdwn', 'inlinee.mdwn', $content);
    $content = IkiWiki::htmlize('inliner.mdwn', 'inlinee.mdwn', 'mdwn', $content);
    return $content;
}
foreach my $type (qw/tip note important caution warning/) {
    like(render_quick("[[!$type foo]]"), qr!<div class="$type">foo</div>\s+!, $type);
}
my $rendered = '<div class="tip">foo <em>bar</em> baz</div>\s*';
my $not_rendered = '<div class="tip">foo \*bar\* baz</div>\s*';
like(render_quick('[[!tip "foo *bar* baz"]]'), qr/$rendered/, 'renders');
like(render_quick('<div class="tip">foo *bar* baz</div>'), qr!$not_rendered!, 'no rendering because mdwn');
like(render_quick('&nbsp;<div class="tip">foo *bar* baz</div>'), qr!&nbsp;$rendered!, 'nbsp hack');
like(render_quick('<span/><div class="tip">foo *bar* baz</div>'), qr!<span />$rendered!, 'span hack');
like(render_quick('<span/><div class="tip">[[!format mdwn "foo *bar* baz"]]</div>'), qr!<span />$rendered!, 'format hack');
