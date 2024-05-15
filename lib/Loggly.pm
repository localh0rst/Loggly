package Loggly;
use 5.008001;
use strict;
use warnings;
use OpenSearch;
use Moose;
use Loggly::Config;
use feature qw/say signatures/;
use Mojo::IOLoop;
use Data::Dumper;
use Scalar::Util    qw(weaken);
use Module::Runtime qw(use_module);

our $VERSION = "0.01";

has 'loop' => ( is => 'rw', isa => 'Mojo::IOLoop', lazy => 1, default => sub { Mojo::IOLoop->singleton } );
has 'args' => ( is => 'rw', isa => 'ArrayRef', required => 1 );
has 'config' => (
  is      => 'rw',
  isa     => 'Loggly::Config',
  lazy    => 1,
  default => sub { Loggly::Config->initialize( _args => shift->args ) }
);

has 'source' => ( is => 'rw' );
has 'sink'   => ( is => 'rw' );

sub BUILD( $self, $args ) {

  $self->source( use_module( "Loggly::Source::" . $self->config->source )->new );
  $self->sink( use_module( "Loggly::Sink::" . $self->config->sink )->new );

  if ( !$self->sink->can('output') ) {
    die "Sink does not implement 'output' method";
  }

  if ( !( $self->source->can('poll') || $self->source->can('stream') ) ) {
    die "Source does not implement 'poll' or 'stream' method";
  }

  weaken $self;
  $self->source->on(
    'messages' => sub {
      my ( $loop, $messages ) = @_;

      $self->sink->output($messages);

      if ( !$messages || scalar @$messages == 0 ) {
        $self->stop if ( !$self->config->follow );

        # If there are no messages, slow down a little
        $self->loop->timer( $self->config->poll_interval / 1000 => sub { $self->source->poll; } );
      } else {
        if ( $self->source->can('poll') ) {
          $self->loop->next_tick( sub { $self->source->poll; } );
        }

      }

    }
  );

  $self->source->on(
    'error' => sub {
      my ( $loop, $message ) = @_;
      die($message);
    }
  );

  $self->source->on(
    'end' => sub {
      my ( $loop, $message ) = @_;
      $self->stop;
    }

  );

  if ( $self->source->can('stream') ) {
    $self->source->stream;
  } else {
    $self->loop->next_tick( sub { $self->source->poll; } );
  }
}

sub stop( $self, $error = undef ) {
  $self->loop->stop;
  if ($error) {
    say STDERR $error;
    exit(1);
  }
}

sub run($self) {
  $self->loop->start unless $self->loop->is_running;
}

1;
__END__

=encoding utf-8

=head1 NAME

Loggly - CLI app for interacting with OpenSearch.

=head1 SYNOPSIS

    use Loggly;

=head1 DESCRIPTION

Loggly is ...

=head1 LICENSE

Copyright (C) localh0rst.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

localh0rst E<lt>git@fail.ninjaE<gt>

=cut

