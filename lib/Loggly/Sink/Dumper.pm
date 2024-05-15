package Loggly::Sink::Dumper;
use strict;
use warnings;
use Moose;
use feature qw/say signatures/;
use Data::Dumper;

has 'config' => ( is => 'ro', isa => 'Loggly::Config', default => sub { Loggly::Config->instance() } );

sub BUILD( $self, $args ) {

}

sub output( $self, $messages ) {
  print Dumper $messages if ( scalar( @{$messages} ) );
}

1;
