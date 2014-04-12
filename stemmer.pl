#!/usr/bin/perl

use strict;
use warnings;

use Carp;
use utf8;
use HTML::Parser;
use LWP::Simple;
use DBI;
use DBD::SQLite;
use Readonly;
use English qw( -no_match_vars );

binmode STDOUT, ':encoding(UTF-8)';

Readonly::Scalar my $MAX_WORDS => 3;

# GET Wikipedia page
my $page_name = 'Linux';
my $web_page  = get("https://en.wikipedia.org/wiki/${page_name}?action=render")
  or croak 'Unable to get page';

# Remove unnecessary HTML elements
my $parser = HTML::Parser->new(
  api_version => 3,
  text_h      => [ \my @parsed_page, 'text' ]
);
$parser->ignore_elements(qw(script style table div h1 h2 h3 h4 h5 h6 a ul ol));
$parser->parse($web_page) || die "Can't parse output\n";
$parser->eof();

my $parsed_page = join q{}, map { $_->[0] } @parsed_page;
$parsed_page =~
  s/\R{2,}(?:\h*\R)/\n/gsmx;    # \h: horizonatal whitespace; \R: ANYCRLF
$parsed_page =~ s/(^\n)|(\n+$)//gsmx;
$parsed_page =~ s/ [.,()\/] //gsmx;
$parsed_page =~ s/&amp;/&/gsmx;
$parsed_page =~ s/[ ]{2}/ /gsmx;
my @tokenized_page = split q{ }, $parsed_page;

#print $parsed_page;

# Read stop words
open my $stopw_file, '<', 'stop-words.txt' or croak $ERRNO;
my @stop_words_array = <$stopw_file>;
my %stop_words;
for (@stop_words_array) { chomp; $stop_words{$_}++ }
close $stopw_file or croak $ERRNO;

# Read up the SQLite database and set cache size to 470 MB
my $dbh = DBI->connect( 'dbi:SQLite:wiki-pages.db', q{}, q{} );
$dbh->do('PRAGMA cache_size = -470000');
my $select = $dbh->prepare('SELECT Title FROM Titles WHERE Title = ?');

# Iterating through the text
for ( my $readahead = $MAX_WORDS ; $readahead > 0 ; $readahead-- ) {
  for ( my $word = 0 ; $word < @tokenized_page - $readahead ; $word++ ) {
    my $expression;
    for ( 0 .. $readahead - 1 ) {
      $expression .= "$tokenized_page[$word + $_] ";
    }
    $expression = lc $expression;
    chop $expression;

    if ( $readahead != 1 || !exists $stop_words{$expression} ) {
      $select->execute($expression);
      my $row = $select->fetch;
    }
  }
}
