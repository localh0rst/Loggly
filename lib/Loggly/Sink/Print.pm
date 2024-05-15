package Loggly::Sink::Print;
use strict;
use warnings;
use Moose;
use feature qw/say signatures/;
use Data::Dumper;
use MooseX::NonMoose;
extends 'Mojo::EventEmitter';

has 'config' => ( is => 'ro', isa => 'Loggly::Config', default => sub { Loggly::Config->instance() } );

sub BUILD( $self, $args ) {

}

sub output( $self, $messages ) {

  # TODO: Color output?
  my $field          = $self->config->logconfig->{field_print} // 'event.original';
  my @splitted_field = split( /\./, $field );

  foreach my $message ( @{$messages} ) {
    if ( ref($message) eq 'HASH' ) {
      foreach my $field (@splitted_field) {
        $message = $message->{$field};
      }
    }

    # Just be sure there is no newline at the end
    chomp($message);
    say STDOUT $message;
  }

}

1;
