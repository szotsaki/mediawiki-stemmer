#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use utf8;
use HTML::Parser;
use LWP::Simple;

binmode STDOUT, ':encoding(UTF-8)';

my $page_name = 'Linux';
my $web_page = get("https://en.wikipedia.org/wiki/${page_name}?action=render")
  or croak 'Unable to get page';

my $parser = HTML::Parser->new(
	api_version => 3,
	text_h => [ \my @parsed_page, 'text' ]
);
$parser->ignore_elements(qw(script style table div h1 h2 h3 h4 h5 h6 a ul ol));
$parser->parse($web_page) || die "Can't parse output\n";
$parser->eof();

my $parsed_page = join q{}, map {$_->[0]} @parsed_page;
$parsed_page =~ s/\R{2,}(?:\h*\R)/\n/gsmx;
$parsed_page =~ s/(^\n)|(\n+$)//gsmx;
print $parsed_page;

1;