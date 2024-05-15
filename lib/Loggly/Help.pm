package Loggly::Help;
use strict;
use warnings;
use Moose;
use feature qw/say signatures/;
use Data::Dumper;
our $VERSION = "0.01";

has 'config' => ( is => 'rw', isa => 'Loggly::Config', default => sub { Loggly::Config->instance; } );

sub print($self) {
  my $defaults  = $self->config->defaults;
  my $logtype   = $self->config->logtype;
  my $logconfig = $self->config->logconfig;

  #  my $params   =;

  say "Loggly Version: " . $Loggly::VERSION;

  say "Usage: $0 [" . ( $logtype ? $logtype : '<LOGTYPE>' ) . "] [options]";

  if ( !$logtype ) {
    say "\nAvailable Log Types:";
    for my $key ( sort( keys( %{ $self->config->cfg->{logconfig} } ) ) ) {
      say "  $key\t\t" . ( $self->config->cfg->{logconfig}->{$key}->{description} // '' );
    }
  }

  if ($logconfig) {

    say "\n$logtype Options:";
    for my $key ( sort( keys( %{ $logconfig->{params} } ) ) ) {
      next if $key eq 'description';
      my $short   = ( $logconfig->{params}->{$key}->{short} ? "-" . $logconfig->{params}->{$key}->{short} . ", " : '' );
      my $desc    = $logconfig->{params}->{$key}->{description};
      my $type    = $logconfig->{params}->{$key}->{type} // '';
      my $default = ( $type =~ /i|s/ ) ? " STR" : '';
      say "  $short--$key" . $default . "\t\t$desc";
    }
  }

  say "\nGlobal Options:";
  for my $key ( sort( keys( %{$defaults} ) ) ) {
    my $short   = ( $defaults->{$key}->{short} ? "-" . $defaults->{$key}->{short} . ", " : '' );
    my $desc    = $defaults->{$key}->{description};
    my $type    = $defaults->{$key}->{type} // '';
    my $default = ( $type =~ /i|s/ ) ? " " . $defaults->{$key}->{default} : '';
    say "  $short--$key" . $default . "\t\t$desc";
  }

}

1;
