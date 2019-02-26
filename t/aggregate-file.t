#!/usr/bin/perl
use utf8;
use warnings;
use strict;

use Encode;
use Test::More;

BEGIN {
	plan(skip_all => "CGI not available")
		unless eval q{
			use CGI qw();
			1;
		};

	plan(skip_all => "IPC::Run not available")
		unless eval q{
			use IPC::Run qw(run);
			1;
		};

	use_ok('IkiWiki');
	use_ok('YAML::XS');
}

# We check for English error messages
$ENV{LC_ALL} = 'C';

use Cwd qw(getcwd);
use Errno qw(ENOENT);

my $installed = $ENV{INSTALLED_TESTS};

my @command;
if ($installed) {
	@command = qw(ikiwiki --plugin inline);
}
else {
	ok(! system("make -s ikiwiki.out"));
	@command = ("perl", "-I".getcwd."/blib/lib", './ikiwiki.out',
		'--underlaydir='.getcwd.'/underlays/basewiki',
		'--set', 'underlaydirbase='.getcwd.'/underlays',
		'--templatedir='.getcwd.'/templates');
}

sub write_old_file {
	my $name = shift;
	my $dir = shift;
	my $content = shift;
	writefile($name, $dir, $content);
	ok(utime(333333333, 333333333, "$dir/$name"));
}

sub write_setup_file {
	my %params = @_;
	my %setup = (
		wikiname => 'this is the name of my wiki',
		srcdir => getcwd.'/t/tmp/in',
		destdir => getcwd.'/t/tmp/out',
		url => 'http://example.com',
		cgiurl => 'http://example.com/cgi-bin/ikiwiki.cgi',
		cgi_wrapper => getcwd.'/t/tmp/ikiwiki.cgi',
		cgi_wrappermode => '0751',
		add_plugins => [qw(aggregate)],
		disable_plugins => [qw(emailauth openid passwordauth)],
		aggregate_webtrigger => 1,
	);
	if ($params{without_paranoia}) {
		$setup{libdirs} = [getcwd.'/t/noparanoia'];
	}
	unless ($installed) {
		$setup{ENV} = { 'PERL5LIB' => getcwd.'/blib/lib' };
	}
	writefile("test.setup", "t/tmp",
		"# IkiWiki::Setup::Yaml - YAML formatted setup file\n" .
		Dump(\%setup));
}

sub thoroughly_rebuild {
	ok(unlink("t/tmp/ikiwiki.cgi") || $!{ENOENT});
	ok(! system(@command, qw(--setup t/tmp/test.setup --rebuild --wrappers)));
}

sub run_cgi {
	my (%args) = @_;
	my ($in, $out);
	my $method = $args{method} || 'GET';
	my $environ = $args{environ} || {};
	my $params = $args{params} || { do => 'prefs' };

	my %defaults = (
		SCRIPT_NAME	=> '/cgi-bin/ikiwiki.cgi',
		HTTP_HOST	=> 'example.com',
	);

	my $cgi = CGI->new($args{params});
	my $query_string = $cgi->query_string();
	diag $query_string;

	if ($method eq 'POST') {
		$defaults{REQUEST_METHOD} = 'POST';
		$in = $query_string;
		$defaults{CONTENT_LENGTH} = length $in;
	} else {
		$defaults{REQUEST_METHOD} = 'GET';
		$defaults{QUERY_STRING} = $query_string;
	}

	my %envvars = (
		%defaults,
		%$environ,
	);
	run(["./t/tmp/ikiwiki.cgi"], \$in, \$out, init => sub {
		map {
			$ENV{$_} = $envvars{$_}
		} keys(%envvars);
	});

	return decode_utf8($out);
}

sub test {
	my $content;

	ok(! system(qw(rm -rf t/tmp)));
	ok(! system(qw(mkdir t/tmp)));

	write_old_file('aggregator.mdwn', 't/tmp/in',
		'[[!aggregate name="ssrf" url="file://'.getcwd.'/t/secret.rss"]]'
		.'[[!inline pages="internal(aggregator/*)"]]');

	write_setup_file();
	thoroughly_rebuild();

	$content = run_cgi(
		method => 'GET',
		params => {
			do => 'aggregate_webtrigger',
		},
	);
	unlike($content, qr{creating new page});
	unlike($content, qr{Secrets});
	ok(! -e 't/tmp/in/.ikiwiki/transient/aggregator/ssrf');
	ok(! -e 't/tmp/in/.ikiwiki/transient/aggregator/ssrf/Secrets_go_here._aggregated');

	thoroughly_rebuild();
	$content = readfile('t/tmp/out/aggregator/index.html');
	unlike($content, qr{Secrets});

	diag('Trying test again with LWPx::ParanoidAgent disabled');

	write_setup_file(without_paranoia => 1);
	thoroughly_rebuild();

	$content = run_cgi(
		method => 'GET',
		params => {
			do => 'aggregate_webtrigger',
		},
	);
	unlike($content, qr{creating new page});
	unlike($content, qr{Secrets});
	ok(! -e 't/tmp/in/.ikiwiki/transient/aggregator/ssrf');
	ok(! -e 't/tmp/in/.ikiwiki/transient/aggregator/ssrf/Secrets_go_here._aggregated');

	thoroughly_rebuild();
	$content = readfile('t/tmp/out/aggregator/index.html');
	unlike($content, qr{Secrets});
}

test();

done_testing();
