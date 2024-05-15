package Loggly::Sink::Json;
use strict;
use warnings;
use Moose;
use feature                    qw/say signatures/;
use Data::Format::Pretty::JSON qw/format_pretty/;

has 'config' => ( is => 'ro', isa => 'Loggly::Config', default => sub { Loggly::Config->instance() } );

sub BUILD( $self, $args ) {

}

sub output( $self, $messages ) {

  foreach my $message ( @{$messages} ) {
    say STDOUT format_pretty($message);
  }

}

1;
