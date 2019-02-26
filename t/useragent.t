#!/usr/bin/perl
use warnings;
use strict;
use Test::More;

my $have_paranoid_agent;
BEGIN {
	plan(skip_all => 'LWP not available')
		unless eval q{
			use LWP qw(); 1;
		};
	use_ok("IkiWiki");
	$have_paranoid_agent = eval q{
		use LWPx::ParanoidAgent qw(); 1;
	};
}

eval { useragent(future_feature => 1); };
ok($@, 'future features should cause useragent to fail');

diag "==== No proxy ====";
delete $ENV{http_proxy};
delete $ENV{https_proxy};
delete $ENV{no_proxy};
delete $ENV{HTTPS_PROXY};
delete $ENV{NO_PROXY};

diag "---- Unspecified URL ----";
my $ua = useragent(for_url => undef);
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef, 'No http proxy');
is($ua->proxy('https'), undef, 'No https proxy');

diag "---- Specified URL ----";
$ua = useragent(for_url => 'http://example.com');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef, 'No http proxy');
is($ua->proxy('https'), undef, 'No https proxy');

diag "==== Proxy for everything ====";
$ENV{http_proxy} = 'http://proxy:8080';
$ENV{https_proxy} = 'http://sproxy:8080';
delete $ENV{no_proxy};
delete $ENV{HTTPS_PROXY};
delete $ENV{NO_PROXY};

diag "---- Unspecified URL ----";
$ua = useragent(for_url => undef);
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), 'http://proxy:8080', 'should use proxy');
is($ua->proxy('https'), 'http://sproxy:8080', 'should use CONNECT proxy');
$ua = useragent(for_url => 'http://example.com');
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http)]);
is($ua->proxy('http'), 'http://proxy:8080', 'should use proxy');
# We don't care what $ua->proxy('https') is, because it won't be used
$ua = useragent(for_url => 'https://example.com');
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(https)]);
# We don't care what $ua->proxy('http') is, because it won't be used
is($ua->proxy('https'), 'http://sproxy:8080', 'should use CONNECT proxy');

diag "==== Selective proxy ====";
$ENV{http_proxy} = 'http://proxy:8080';
$ENV{https_proxy} = 'http://sproxy:8080';
$ENV{no_proxy} = '*.example.net,example.com,.example.org';
delete $ENV{HTTPS_PROXY};
delete $ENV{NO_PROXY};

diag "---- Unspecified URL ----";
$ua = useragent(for_url => undef);
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), 'http://proxy:8080', 'should use proxy');
is($ua->proxy('https'), 'http://sproxy:8080', 'should use CONNECT proxy');

diag "---- Exact match for no_proxy ----";
$ua = useragent(for_url => 'http://example.com');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- Subdomain of exact domain in no_proxy ----";
$ua = useragent(for_url => 'http://sub.example.com');
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http)]);
is($ua->proxy('http'), 'http://proxy:8080', 'should use proxy');

diag "---- example.net matches *.example.net ----";
$ua = useragent(for_url => 'https://example.net');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- sub.example.net matches *.example.net ----";
$ua = useragent(for_url => 'https://sub.example.net');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- badexample.net does not match *.example.net ----";
$ua = useragent(for_url => 'https://badexample.net');
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(https)]);
is($ua->proxy('https'), 'http://sproxy:8080', 'should use proxy');

diag "---- example.org matches .example.org ----";
$ua = useragent(for_url => 'https://example.org');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- sub.example.org matches .example.org ----";
$ua = useragent(for_url => 'https://sub.example.org');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- badexample.org does not match .example.org ----";
$ua = useragent(for_url => 'https://badexample.org');
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(https)]);
is($ua->proxy('https'), 'http://sproxy:8080', 'should use proxy');

diag "==== Selective proxy (alternate variables) ====";
$ENV{http_proxy} = 'http://proxy:8080';
delete $ENV{https_proxy};
$ENV{HTTPS_PROXY} = 'http://sproxy:8080';
delete $ENV{no_proxy};
$ENV{NO_PROXY} = '*.example.net,example.com,.example.org';

diag "---- Unspecified URL ----";
$ua = useragent(for_url => undef);
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), 'http://proxy:8080', 'should use proxy');
is($ua->proxy('https'), 'http://sproxy:8080', 'should use CONNECT proxy');

diag "---- Exact match for no_proxy ----";
$ua = useragent(for_url => 'http://example.com');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- Subdomain of exact domain in no_proxy ----";
$ua = useragent(for_url => 'http://sub.example.com');
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http)]);
is($ua->proxy('http'), 'http://proxy:8080', 'should use proxy');

diag "---- example.net matches *.example.net ----";
$ua = useragent(for_url => 'https://example.net');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- sub.example.net matches *.example.net ----";
$ua = useragent(for_url => 'https://sub.example.net');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- badexample.net does not match *.example.net ----";
$ua = useragent(for_url => 'https://badexample.net');
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(https)]);
is($ua->proxy('https'), 'http://sproxy:8080', 'should use proxy');

diag "---- example.org matches .example.org ----";
$ua = useragent(for_url => 'https://example.org');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- sub.example.org matches .example.org ----";
$ua = useragent(for_url => 'https://sub.example.org');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- badexample.org does not match .example.org ----";
$ua = useragent(for_url => 'https://badexample.org');
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(https)]);
is($ua->proxy('https'), 'http://sproxy:8080', 'should use proxy');

diag "==== Selective proxy (many variables) ====";
$ENV{http_proxy} = 'http://proxy:8080';
$ENV{https_proxy} = 'http://sproxy:8080';
# This one should be ignored in favour of https_proxy
$ENV{HTTPS_PROXY} = 'http://not.preferred.proxy:3128';
# These two should be merged
$ENV{no_proxy} = '*.example.net,example.com';
$ENV{NO_PROXY} = '.example.org';

diag "---- Unspecified URL ----";
$ua = useragent(for_url => undef);
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), 'http://proxy:8080', 'should use proxy');
is($ua->proxy('https'), 'http://sproxy:8080', 'should use CONNECT proxy');

diag "---- Exact match for no_proxy ----";
$ua = useragent(for_url => 'http://example.com');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- Subdomain of exact domain in no_proxy ----";
$ua = useragent(for_url => 'http://sub.example.com');
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http)]);
is($ua->proxy('http'), 'http://proxy:8080', 'should use proxy');

diag "---- example.net matches *.example.net ----";
$ua = useragent(for_url => 'https://example.net');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- sub.example.net matches *.example.net ----";
$ua = useragent(for_url => 'https://sub.example.net');
SKIP: {
	skip 'paranoid agent not available', 1 unless $have_paranoid_agent;
	ok($ua->isa('LWPx::ParanoidAgent'), 'uses ParanoidAgent if possible');
}
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), undef);
is($ua->proxy('https'), undef);

diag "---- badexample.net does not match *.example.net ----";
$ua = useragent(for_url => 'https://badexample.net');
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(https)]);
is($ua->proxy('https'), 'http://sproxy:8080', 'should use proxy');

diag "==== One but not the other ====\n";
$ENV{http_proxy} = 'http://proxy:8080';
delete $ENV{https_proxy};
delete $ENV{HTTPS_PROXY};
delete $ENV{no_proxy};
delete $ENV{NO_PROXY};
$ua = useragent(for_url => undef);
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), 'http://proxy:8080', 'should use proxy');
is($ua->proxy('https'), 'http://proxy:8080', 'should use proxy');

delete $ENV{http_proxy};
$ENV{https_proxy} = 'http://sproxy:8080';
delete $ENV{HTTPS_PROXY};
delete $ENV{no_proxy};
delete $ENV{NO_PROXY};
$ua = useragent(for_url => undef);
ok(! $ua->isa('LWPx::ParanoidAgent'), 'should use proxy instead of ParanoidAgent');
is_deeply([sort @{$ua->protocols_allowed}], [sort qw(http https)]);
is($ua->proxy('http'), 'http://sproxy:8080', 'should use proxy');
is($ua->proxy('https'), 'http://sproxy:8080', 'should use proxy');

done_testing;
