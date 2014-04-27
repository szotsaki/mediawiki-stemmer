#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Carp;
use DBI;
use English qw( -no_match_vars );
use HTML::Parser;
use LWP::Simple;
use Readonly;
use String::ShellQuote;
use Text::SimpleTable::AutoWidth;

binmode STDOUT, ':encoding(UTF-8)';

Readonly::Scalar my $MAX_WORDS => 3;

# Startup check
if ($#ARGV != 1) {
  die "Usage: $PROGRAM_NAME <Wikipedia page name> <isStemmingRequired>\n";
}

my $page_name = shift;
my $stemming_required = shift;

# GET Wikipedia page
my $web_page  = get("https://en.wikipedia.org/wiki/${page_name}?action=render")
  or croak 'Unable to get page: maybe this one has not been created yet?';

# Remove unnecessary HTML elements
my $parser = HTML::Parser->new(
  api_version => 3,
  text_h      => [ \my @parsed_page, 'text' ]
);
$parser->ignore_elements(qw(script style table div h1 h2 h3 h4 h5 h6 ul ol a));
$parser->parse($web_page) || die "Can't parse output\n";
$parser->eof();

my $parsed_page = join q{}, map { $_->[0] } @parsed_page;
$parsed_page =~
  s/\R{2,}(?:\h*\R)/\n/gsmx;    # \h: horizonatal whitespace; \R: ANYCRLF
$parsed_page =~ s/(^\n)|(\n+$)//gsmx;    # Multiple newlines
$parsed_page =~ s/ [.,()\/;] //gsmx;     # Lonely characters
$parsed_page =~ s/&amp;/&/gsmx;          # &amp; -> &
$parsed_page =~ s/[ ]{2}/ /gsmx;         # Double spaces
$parsed_page =~ s/\[\d+\]//gsmx;         # References, like [43]

# Read stop words
open my $stopw_file, '<', 'stop-words.txt' or croak $ERRNO;
my @stop_words_array = <$stopw_file>;
my %stop_words;
for (@stop_words_array) { chomp; $stop_words{$_} = 0 }
close $stopw_file or croak $ERRNO;

# Read up the SQLite database and set cache size to 520 MB
my $dbh = DBI->connect( 'dbi:SQLite:wiki-pages.db', q{}, q{} );
$dbh->do('PRAGMA cache_size = -520000');
my $select = $dbh->prepare('SELECT Title FROM Titles WHERE Title = ?');

# Iterating through the text
my %matched_words_cache;
my %matched_words;
for ( my $readahead = $MAX_WORDS ; $readahead > 0 ; $readahead-- ) {
  my @tokenized_page = split q{ }, $parsed_page;

  # Iterating through the tokenized page
  for ( my $word = 0 ; $word < @tokenized_page - $readahead ; $word++ ) {
    my $expression;
    my $expression_;
    for ( 0 .. $readahead - 1 ) {
      $expression  .= "$tokenized_page[$word + $_] ";
      $expression_ .= "$tokenized_page[$word + $_]_";
    }
    $expression_ = lc $expression_;
    chop $expression;
    chop $expression_;

    if ( ( $readahead != 1 || ! exists $stop_words{$expression} )
      && !exists $matched_words_cache{$expression} )
    {
      # See if there is any match without altering the current expression
      $select->execute($expression_);
      my $row = $select->fetch;
      if ($row) { # If there is an instant match
        $matched_words{$expression}       = $expression;
        $matched_words_cache{$expression} = $expression;
      } else { # If there isn't an instant match and we need stemming
        next if ! $stemming_required;

        # Get the last word and stem it
        my @splitexpression = split q{ }, $expression;
        my $stemmedword = pop @splitexpression;
        my $argument = shell_quote_best_effort $stemmedword;
        print "Stemming: $stemmedword... ";
        $stemmedword = `echo $argument | hunspell -d en_US -s`;
        chomp $stemmedword;
        chomp $stemmedword;
        $stemmedword = (split q{ }, $stemmedword)[-1];
        print "$stemmedword\n";
        push @splitexpression, $stemmedword;
        my $stemmedexpression = join q{ }, @splitexpression;
        my $stemmedexpression_ = join q{_}, @splitexpression;

        # Re-run the query
        $select->execute($stemmedexpression_);
        $row = $select->fetch;
        if ($row) {
          $matched_words{$expression}       = $stemmedexpression;
          $matched_words_cache{$expression} = $stemmedexpression;
        }
      }
    }
  }

  # Removing found elements from tokenized page
  foreach my $key ( keys %matched_words_cache ) {
    $parsed_page =~ s/$key//gsmx;
  }
  %matched_words_cache = ();
}

# Compare the results with the original ones
my %matched_wikipedia_link;
sub a_tag_handler {
  my $attr = shift;
  if (exists $attr->{title}) {
    $matched_wikipedia_link{$attr->{title}} = 0;
  }

  return;
}

my $parser_a = HTML::Parser->new(api_version => 3,
                 start_h => [\&a_tag_handler, 'attr']
             );
$parser_a->ignore_elements(qw(script style table div h1 h2 h3 h4 h5 h6 ul ol));
$parser_a->report_tags(qw(a));
$parser_a->parse($web_page) || die "Can't parse output\n";
$parser->eof();

# Print out the comparison table
my $table = Text::SimpleTable::AutoWidth->new(captions => ['Stemmer\'s new links', 'Wikipedia existing links']);

my @sorted_matched_words = sort values %matched_words;
my @sorted_wiki_words = sort keys %matched_wikipedia_link;
my $max_length = ($#sorted_matched_words, $#sorted_wiki_words)[$#sorted_matched_words < $#sorted_wiki_words];

for (0..$max_length) {
  my $stemmer_link = $sorted_matched_words[$_] || q{};
  my $wiki_link = $sorted_wiki_words[$_] || q{};
  $table->row($stemmer_link, $wiki_link);
}

print $table->draw();