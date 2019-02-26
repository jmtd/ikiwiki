#!/usr/bin/perl
# -*- cperl-indent-level: 8; -*-
use warnings;
use strict;
use File::Temp qw{tempdir};
use utf8;

BEGIN {
	unless (eval { require Locale::Po4a::Chooser }) {
		eval q{
			use Test::More skip_all => "Locale::Po4a::Chooser::new is not available"
		}
	}
	unless (eval { require Locale::Po4a::Po }) {
		eval q{
			use Test::More skip_all => "Locale::Po4a::Po::new is not available"
		}
	}
}

use Test::More;

BEGIN { use_ok("IkiWiki"); }

my $msgprefix;

my $dir = tempdir("ikiwiki-test-po.XXXXXXXXXX",
		  DIR => File::Spec->tmpdir,
		  CLEANUP => 1);

### Init
%config=IkiWiki::defaultconfig();
$config{srcdir} = "$dir/src";
$config{destdir} = "$dir/dst";
$config{destdir} = "$dir/dst";
$config{underlaydirbase} = "/dev/null";
$config{underlaydir} = "/dev/null";
$config{url} = "http://example.com";
$config{cgiurl} = "http://example.com/ikiwiki.cgi";
$config{discussion} = 0;
$config{po_master_language} = { code => 'en',
				name => 'English'
			      };
$config{po_slave_languages} = {
			       es => 'Castellano',
			       fr => "Français"
			      };
$config{po_translatable_pages}='index or test1 or test2 or translatable or debian*';
$config{po_link_to}='negotiated';
IkiWiki::loadplugins();
ok(IkiWiki::loadplugin('meta'), "meta plugin loaded");
ok(IkiWiki::loadplugin('po'), "po plugin loaded");
IkiWiki::checkconfig();

### seed %pagesources and %pagecase
$pagesources{'index'}='index.mdwn';
$pagesources{'index.fr'}='index.fr.po';
$pagesources{'index.es'}='index.es.po';
$pagesources{'test1'}='test1.mdwn';
$pagesources{'test1.es'}='test1.es.po';
$pagesources{'test1.fr'}='test1.fr.po';
$pagesources{'test2'}='test2.mdwn';
$pagesources{'test2.es'}='test2.es.po';
$pagesources{'test2.fr'}='test2.fr.po';
$pagesources{'test3'}='test3.mdwn';
$pagesources{'test3.es'}='test3.es.mdwn';
$pagesources{'translatable'}='translatable.mdwn';
$pagesources{'translatable.fr'}='translatable.fr.po';
$pagesources{'translatable.es'}='translatable.es.po';
$pagesources{'nontranslatable'}='nontranslatable.mdwn';
$pagesources{'debian911356'}='debian911356.mdwn';
$pagesources{'debian911356ish'}='debian911356ish.mdwn';
$pagesources{'debian911356.fr'}='debian911356.fr.po';
$pagesources{'debian911356ish.fr'}='debian911356ish.fr.po';
$pagesources{'debian911356-inlined'}='debian911356-inlined.mdwn';
$pagesources{'debian911356-inlined.fr'}='debian911356-inlined.fr.po';
$pagesources{'templates/feedlink.tmpl'}='templates/feedlink.tmpl';
$pagesources{'templates/inlinepage.tmpl'}='templates/inlinepage.tmpl';
my $now=time;
foreach my $page (keys %pagesources) {
	$IkiWiki::pagecase{lc $page}=$page;
	$IkiWiki::pagectime{$page}=$now;
	$IkiWiki::pagemtime{$page}=$now;
}

### populate srcdir
writefile('index.mdwn', $config{srcdir},
          "[[!meta title=\"index title\"]]\n[[translatable]] [[nontranslatable]]");
writefile('test1.mdwn', $config{srcdir},
          "[[!meta title=\"test1 title\"]]\ntest1 content");
writefile('test2.mdwn', $config{srcdir}, 'test2 content');
writefile('test3.mdwn', $config{srcdir}, 'test3 content');
writefile('translatable.mdwn', $config{srcdir}, '[[nontranslatable]]');
writefile('nontranslatable.mdwn', $config{srcdir}, '[[/]] [[translatable]]');
writefile('debian911356.mdwn', $config{srcdir}, <<EOF);
Before first inline

[[!inline pages="debian911356-inlined" raw="yes"]]

Between inlines

[[!inline pages="debian911356-inlined" raw="yes"]]

After inlines
EOF
writefile('debian911356-inlined.mdwn', $config{srcdir}, <<EOF);
English content
EOF
writefile('debian911356.fr.po', $config{srcdir}, <<EOF);
msgid "" msgstr ""
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"

msgid "Before first inline"
msgstr "Avant la première inline"

msgid "[[!inline pages=\\"debian911356-inlined\\" raw=\\"yes\\"]]\\n"
msgstr "[[!inline pages=\\"debian911356-inlined.fr\\" raw=\\"yes\\"]]\\n"

msgid "Between inlines"
msgstr "Entre les inlines"

msgid "After inlines"
msgstr "Après les inlines"
EOF
writefile('debian911356-inlined.fr.po', $config{srcdir}, <<EOF);
msgid "English content"
msgstr "Contenu français"
EOF
writefile('debian911356ish.mdwn', $config{srcdir}, <<EOF);
Before first inline

[[!inline pages="debian911356-inlined"]]

Between inlines

[[!inline pages="debian911356-inlined"]]

After inlines
EOF
writefile('debian911356ish.fr.po', $config{srcdir}, <<EOF);
msgid "" msgstr ""
"MIME-Version: 1.0\\n"
"Content-Type: text/plain; charset=UTF-8\\n"
"Content-Transfer-Encoding: 8bit\\n"

msgid "Before first inline"
msgstr "Avant la première inline"

msgid "[[!inline pages=\\"debian911356-inlined\\"]]\\n"
msgstr "[[!inline pages=\\"debian911356-inlined.fr\\"]]\\n"

msgid "Between inlines"
msgstr "Entre les inlines"

msgid "After inlines"
msgstr "Après les inlines"
EOF
# We don't actually care what the feed links look like, so skip them
writefile('templates/feedlink.tmpl', $config{srcdir}, <<EOF);
<!--feedlinks-->
EOF
# Make inlines' appearance predictable so we can screen-scrape them
writefile('templates/inlinepage.tmpl', $config{srcdir}, <<EOF);
<div class="inlinecontent">
<h6><TMPL_VAR TITLE></h6>
<TMPL_VAR CONTENT>
</div><!--inlinecontent-->
EOF

### istranslatable/istranslation
# we run these tests twice because memoization attempts made them
# succeed once every two tries...
foreach (1, 2) {
ok(IkiWiki::Plugin::po::istranslatable('index'), "index is translatable");
ok(IkiWiki::Plugin::po::istranslatable('/index'), "/index is translatable");
ok(! IkiWiki::Plugin::po::istranslatable('index.fr'), "index.fr is not translatable");
ok(! IkiWiki::Plugin::po::istranslatable('index.es'), "index.es is not translatable");
ok(! IkiWiki::Plugin::po::istranslatable('/index.fr'), "/index.fr is not translatable");
ok(! IkiWiki::Plugin::po::istranslation('index'), "index is not a translation");
ok(IkiWiki::Plugin::po::istranslation('index.fr'), "index.fr is a translation");
ok(IkiWiki::Plugin::po::istranslation('index.es'), "index.es is a translation");
ok(IkiWiki::Plugin::po::istranslation('/index.fr'), "/index.fr is a translation");
ok(IkiWiki::Plugin::po::istranslatable('test1'), "test1 is translatable");
ok(IkiWiki::Plugin::po::istranslation('test1.es'), "test1.es is a translation");
ok(IkiWiki::Plugin::po::istranslation('test1.fr'), "test1.fr is a translation");
ok(IkiWiki::Plugin::po::istranslatable('test2'), "test2 is translatable");
ok(! IkiWiki::Plugin::po::istranslation('test2'), "test2 is not a translation");
ok(! IkiWiki::Plugin::po::istranslatable('test3'), "test3 is not translatable");
ok(! IkiWiki::Plugin::po::istranslation('test3'), "test3 is not a translation");
}

### pofiles

my @pofiles = IkiWiki::Plugin::po::pofiles(srcfile("index.mdwn"));
ok( @pofiles, "pofiles is defined");
ok( @pofiles == 2, "pofiles has correct size");
is_deeply(\@pofiles, ["$config{srcdir}/index.es.po", "$config{srcdir}/index.fr.po"], "pofiles content is correct");

### links
require IkiWiki::Render;

sub refresh_n_scan(@) {
	my @masterfiles_rel=@_;
	foreach my $masterfile_rel (@masterfiles_rel) {
		my $masterfile=srcfile($masterfile_rel);
		IkiWiki::scan($masterfile_rel);
		next unless IkiWiki::Plugin::po::istranslatable(pagename($masterfile_rel));
		my @pofiles=IkiWiki::Plugin::po::pofiles($masterfile);
		IkiWiki::Plugin::po::refreshpot($masterfile);
		IkiWiki::Plugin::po::refreshpofiles($masterfile, @pofiles);
		map IkiWiki::scan(IkiWiki::abs2rel($_, $config{srcdir})), @pofiles;
	}
}

$config{po_link_to}='negotiated';
$msgprefix="links (po_link_to=negotiated)";
refresh_n_scan('index.mdwn', 'translatable.mdwn', 'nontranslatable.mdwn');
is_deeply(\@{$links{'index'}}, ['translatable', 'nontranslatable'], "$msgprefix index");
is_deeply(\@{$links{'index.es'}}, ['translatable.es', 'nontranslatable'], "$msgprefix index.es");
is_deeply(\@{$links{'index.fr'}}, ['translatable.fr', 'nontranslatable'], "$msgprefix index.fr");
is_deeply(\@{$links{'translatable'}}, ['nontranslatable'], "$msgprefix translatable");
is_deeply(\@{$links{'translatable.es'}}, ['nontranslatable'], "$msgprefix translatable.es");
is_deeply(\@{$links{'translatable.fr'}}, ['nontranslatable'], "$msgprefix translatable.fr");
is_deeply([sort @{$links{'nontranslatable'}}], [sort('/', 'translatable', 'translatable.fr', 'translatable.es')], "$msgprefix nontranslatable");

$config{po_link_to}='current';
$msgprefix="links (po_link_to=current)";
refresh_n_scan('index.mdwn', 'translatable.mdwn', 'nontranslatable.mdwn');
is_deeply(\@{$links{'index'}}, ['translatable', 'nontranslatable'], "$msgprefix index");
is_deeply(\@{$links{'index.es'}}, [ (map bestlink('index.es', $_), ('translatable.es', 'nontranslatable'))], "$msgprefix index.es");
is_deeply(\@{$links{'index.fr'}}, [ (map bestlink('index.fr', $_), ('translatable.fr', 'nontranslatable'))], "$msgprefix index.fr");
is_deeply(\@{$links{'translatable'}}, [bestlink('translatable', 'nontranslatable')], "$msgprefix translatable");
is_deeply(\@{$links{'translatable.es'}}, ['nontranslatable'], "$msgprefix translatable.es");
is_deeply(\@{$links{'translatable.fr'}}, ['nontranslatable'], "$msgprefix translatable.fr");
is_deeply([sort @{$links{'nontranslatable'}}], [sort('/', 'translatable', 'translatable.fr', 'translatable.es')], "$msgprefix nontranslatable");

### targetpage
$config{usedirs}=0;
$msgprefix="targetpage (usedirs=0)";
is(targetpage('test1', 'html'), 'test1.en.html', "$msgprefix test1");
is(targetpage('test1.fr', 'html'), 'test1.fr.html', "$msgprefix test1.fr");
$config{usedirs}=1;
$msgprefix="targetpage (usedirs=1)";
is(targetpage('index', 'html'), 'index.en.html', "$msgprefix index");
is(targetpage('index.fr', 'html'), 'index.fr.html', "$msgprefix index.fr");
is(targetpage('test1', 'html'), 'test1/index.en.html', "$msgprefix test1");
is(targetpage('test1.fr', 'html'), 'test1/index.fr.html', "$msgprefix test1.fr");
is(targetpage('test3', 'html'), 'test3/index.html', "$msgprefix test3 (non-translatable page)");
is(targetpage('test3.es', 'html'), 'test3.es/index.html', "$msgprefix test3.es (non-translatable page)");

### urlto -> index
$config{po_link_to}='current';
$msgprefix="urlto (po_link_to=current)";
is(urlto('', 'index'), './index.en.html', "$msgprefix index -> ''");
is(urlto('', 'nontranslatable'), '../index.en.html', "$msgprefix nontranslatable -> ''");
is(urlto('', 'translatable.fr'), '../index.fr.html', "$msgprefix translatable.fr -> ''");
# when asking for a semi-absolute or absolute URL, we can't know what the
# current language is, so for translatable pages we use the master language
is(urlto('nontranslatable'), '/nontranslatable/', "$msgprefix 1-arg -> nontranslatable");
is(urlto('translatable'), '/translatable/index.en.html', "$msgprefix 1-arg -> translatable");
is(urlto('nontranslatable', undef, 1), 'http://example.com/nontranslatable/', "$msgprefix 1-arg -> nontranslatable");
is(urlto('index', undef, 1), 'http://example.com/index.en.html', "$msgprefix 1-arg -> index");
is(urlto('', undef, 1), 'http://example.com/index.en.html', "$msgprefix 1-arg -> ''");
# FIXME: should these three produce the negotiatable URL instead of the master
# language?
is(urlto(''), '/index.en.html', "$msgprefix 1-arg -> ''");
is(urlto('index'), '/index.en.html', "$msgprefix 1-arg -> index");
is(urlto('translatable', undef, 1), 'http://example.com/translatable/index.en.html', "$msgprefix 1-arg -> translatable");

$config{po_link_to}='negotiated';
$msgprefix="urlto (po_link_to=negotiated)";
is(urlto('', 'index'), './', "$msgprefix index -> ''");
is(urlto('', 'nontranslatable'), '../', "$msgprefix nontranslatable -> ''");
is(urlto('', 'translatable.fr'), '../', "$msgprefix translatable.fr -> ''");
is(urlto('nontranslatable'), '/nontranslatable/', "$msgprefix 1-arg -> nontranslatable");
is(urlto('translatable'), '/translatable/', "$msgprefix 1-arg -> translatable");
is(urlto(''), '/', "$msgprefix 1-arg -> ''");
is(urlto('index'), '/', "$msgprefix 1-arg -> index");
is(urlto('nontranslatable', undef, 1), 'http://example.com/nontranslatable/', "$msgprefix 1-arg -> nontranslatable");
is(urlto('translatable', undef, 1), 'http://example.com/translatable/', "$msgprefix 1-arg -> translatable");
is(urlto('index', undef, 1), 'http://example.com/', "$msgprefix 1-arg -> index");
is(urlto('', undef, 1), 'http://example.com/', "$msgprefix 1-arg -> ''");

### bestlink
$config{po_link_to}='current';
$msgprefix="bestlink (po_link_to=current)";
is(bestlink('test1.fr', 'test2'), 'test2.fr', "$msgprefix test1.fr -> test2");
is(bestlink('test1.fr', 'test2.es'), 'test2.es', "$msgprefix test1.fr -> test2.es");
$config{po_link_to}='negotiated';
$msgprefix="bestlink (po_link_to=negotiated)";
is(bestlink('test1.fr', 'test2'), 'test2.fr', "$msgprefix test1.fr -> test2");
is(bestlink('test1.fr', 'test2.es'), 'test2.es', "$msgprefix test1.fr -> test2.es");

### beautify_urlpath
$config{po_link_to}='default';
$msgprefix="beautify_urlpath (po_link_to=default)";
is(IkiWiki::beautify_urlpath('test1/index.en.html'), './test1/index.en.html', "$msgprefix test1/index.en.html");
is(IkiWiki::beautify_urlpath('test1/index.fr.html'), './test1/index.fr.html', "$msgprefix test1/index.fr.html");
$config{po_link_to}='negotiated';
$msgprefix="beautify_urlpath (po_link_to=negotiated)";
is(IkiWiki::beautify_urlpath('test1/index.html'), './test1/', "$msgprefix test1/index.html");
is(IkiWiki::beautify_urlpath('test1/index.en.html'), './test1/', "$msgprefix test1/index.en.html");
is(IkiWiki::beautify_urlpath('test1/index.fr.html'), './test1/', "$msgprefix test1/index.fr.html");
$config{po_link_to}='current';
$msgprefix="beautify_urlpath (po_link_to=current)";
is(IkiWiki::beautify_urlpath('test1/index.en.html'), './test1/index.en.html', "$msgprefix test1/index.en.html");
is(IkiWiki::beautify_urlpath('test1/index.fr.html'), './test1/index.fr.html', "$msgprefix test1/index.fr.html");

### re-scan
refresh_n_scan('index.mdwn');
is($pagestate{'index'}{meta}{title}, 'index title');
is($pagestate{'index.es'}{meta}{title}, 'index title');
is($pagestate{'index.fr'}{meta}{title}, 'index title');
refresh_n_scan('test1.mdwn');
is($pagestate{'test1'}{meta}{title}, 'test1 title');
is($pagestate{'test1.es'}{meta}{title}, 'test1 title');
is($pagestate{'test1.fr'}{meta}{title}, 'test1 title');

### istranslatedto
ok(IkiWiki::Plugin::po::istranslatedto('index', 'es'));
ok(IkiWiki::Plugin::po::istranslatedto('index', 'fr'));
ok(! IkiWiki::Plugin::po::istranslatedto('index', 'cz'));
ok(IkiWiki::Plugin::po::istranslatedto('test1', 'es'));
ok(IkiWiki::Plugin::po::istranslatedto('test1', 'fr'));
ok(! IkiWiki::Plugin::po::istranslatedto('test1', 'cz'));
ok(! IkiWiki::Plugin::po::istranslatedto('nontranslatable', 'es'));
ok(! IkiWiki::Plugin::po::istranslatedto('nontranslatable', 'cz'));
ok(! IkiWiki::Plugin::po::istranslatedto('test1.es', 'fr'));
ok(! IkiWiki::Plugin::po::istranslatedto('test1.fr', 'es'));

### islanguagecode
ok(IkiWiki::Plugin::po::islanguagecode('en'));
ok(IkiWiki::Plugin::po::islanguagecode('es'));
ok(IkiWiki::Plugin::po::islanguagecode('arn'));
ok(! IkiWiki::Plugin::po::islanguagecode('es_'));
ok(! IkiWiki::Plugin::po::islanguagecode('_en'));

# Actually render translated pages
use IkiWiki::Render;

my %output;
foreach my $page (sort keys %pagesources) {
	my $source = "$config{srcdir}/$pagesources{$page}";
	if (-e $source) {
		IkiWiki::scan($pagesources{$page});
	}
}

# This is the most complicated case, so use this while we test rendering
$config{po_link_to}='current';

foreach my $page (sort keys %pagesources) {
	my $source = "$config{srcdir}/$pagesources{$page}";
	if (-e $source && defined IkiWiki::pagetype($pagesources{$page})) {
		IkiWiki::scan($pagesources{$page});
		my $content = readfile($source);
		#print STDERR "-------------------------------------\n";
		#print STDERR "SOURCE: $page: $content\n";
		$content = IkiWiki::filter($page, $page, $content);
		#print STDERR "FILTERED: $page: $content\n";
		$content = IkiWiki::preprocess($page, $page, $content);
		#print STDERR "PREPROCESSED: $page: $content\n";
		$content = IkiWiki::linkify($page, $page, $content);
		#print STDERR "LINKIFIED: $page: $content\n";
		$content = IkiWiki::htmlize($page, $page, IkiWiki::pagetype($pagesources{$page}), $content);
		#print STDERR "HTMLIZED: $page: $content\n";
		IkiWiki::run_hooks(format => sub {
			$content=shift->(
				page => $page,
				content => $content,
			);
		});
		#print STDERR "FORMATTED: $page: $content\n";
		$output{$page} = $content;
	}
}

like($output{index}, qr{
	<p>
	<a\s+href="\./translatable/index\.en\.html">
	translatable
	</a>\s*
	<a\s+href="\./nontranslatable/">
	nontranslatable
	</a>
	</p>
}sx);

like($output{'index.es'}, qr{
	<p>
	<a\s+href="\./translatable/index\.es\.html">
	translatable
	</a>\s*
	<a\s+href="\./nontranslatable/">
	nontranslatable
	</a>
	</p>
}sx);

like($output{'index.fr'}, qr{
	<p>
	<a\s+href="\./translatable/index\.fr\.html">
	translatable
	</a>\s*
	<a\s+href="\./nontranslatable/">
	nontranslatable
	</a>
	</p>
}sx);

like($output{'translatable'}, qr{
	<a\s+href="\.\./nontranslatable/">
	nontranslatable
	</a>
}sx);

TODO: {
local $TODO = 'was [[/]] meant to be a link to the index?';
unlike($output{'nontranslatable'}, qr{
	class=.createlink.
}sx);
};
like($output{'nontranslatable'}, qr{
	<a\s+href="\.\./translatable/index\.en\.html">
	translatable
	</a>
}sx);

like($output{debian911356}, qr{
	<p>Before\sfirst\sinline</p>
	\s*
	<p>English\scontent</p>
	\s*
	<p>Between\sinlines</p>
	\s*
	<p>English\scontent</p>
	\s*
	<p>After\sinlines</p>
}sx);

like($output{'debian911356.fr'}, qr{
	<p>Avant\sla\spremière\sinline</p>
	\s*
	<p>Contenu\sfrançais</p>
	\s*
	<p>Entre\sles\sinlines</p>
	\s*
	<p>Contenu\sfrançais</p>
	\s*
	<p>Après\sles\sinlines</p>
}sx);

# Variation of Debian #911356 without using raw inlines.
like($output{debian911356ish}, qr{
	<p>Before\sfirst\sinline</p>
	\s*
	<!--feedlinks-->
	\s*
	<div\sclass="inlinecontent">
	\s*
	<h6>debian911356-inlined</h6>
	\s*
	<p>English\scontent</p>
	\s*
	</div><!--inlinecontent-->
	\s*
	<p>Between\sinlines</p>
	\s*
	<!--feedlinks-->
	\s*
	<div\sclass="inlinecontent">
	\s*
	<h6>debian911356-inlined</h6>
	\s*
	<p>English\scontent</p>
	\s*
	</div><!--inlinecontent-->
	\s*
	<p>After\sinlines</p>
}sx);

like($output{'debian911356ish.fr'}, qr{
	<p>Avant\sla\spremière\sinline</p>
	\s*
	<!--feedlinks-->
	\s*
	<div\sclass="inlinecontent">
	\s*
	<h6>debian911356-inlined\.fr</h6>
	\s*
	<p>Contenu\sfrançais</p>
	\s*
	</div><!--inlinecontent-->
	\s*
	<p>Entre\sles\sinlines</p>
	\s*
	<!--feedlinks-->
	\s*
	<div\sclass="inlinecontent">
	\s*
	<h6>debian911356-inlined\.fr</h6>
	\s*
	<p>Contenu\sfrançais</p>
	\s*
	</div><!--inlinecontent-->
	\s*
	<p>Après\sles\sinlines</p>
}sx);

done_testing;
