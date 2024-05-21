package Loggly::Source::OpenSearch;
use strict;
use warnings;
use Moose;
use OpenSearch;
use feature qw/say signatures/;
use Data::Dumper;
use MooseX::NonMoose;
extends 'Mojo::EventEmitter';

has 'config'       => ( is => 'ro', isa => 'Loggly::Config', default => sub { Loggly::Config->instance() } );
has 'opensearch'   => ( is => 'rw', isa => 'OpenSearch' );
has 'search'       => ( is => 'rw', isa => 'OpenSearch::Search' );
has 'search_after' => ( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

sub BUILD( $self, $args ) {
  $self->opensearch( OpenSearch->new( $self->config->source_config ) );

  my $time = $self->config->opts->{time} // $self->config->logconfig->{time}
    // $self->config->defaults->{time}->{default};
  my $cp   = $self->config->logconfig->{params};
  my $cs   = $self->config->opts->{cs}   // $self->config->logconfig->{cs} // $self->config->defaults->{cs}->{default};
  my $size = $self->config->opts->{size} // $self->config->logconfig->{size}
    // $self->config->defaults->{size}->{default};
  my $fields = $self->config->logconfig->{fields} // undef;
  my $index  = $self->config->logconfig->{index};

  # Build the Query Filter
  my $query_filter = {

    bool => {
      must => [ { range => { '@timestamp' => { gte => 'now-' . ( $time ? $time : '1h' ) } } }, ],
    }

  };

  foreach my $key ( keys %{$cp} ) {

    #my $my ( $r, $t ) = split( ';', $cfg->val( $logtype . '-params', $key ) );
    #
    my $r = $cp->{$key}->{field_name};
    my $t = $cp->{$key}->{query_type};
    next unless $self->config->opts->{$key};

    my $query_type = {};
    if ( $t eq 'match' ) {
      $query_type = { match => { $r => { query => $self->config->opts->{$key}, operator => 'and' } } };
    } elsif ( $t eq 'term' ) {

      $query_type = {
        term => {
          $r => { value => $self->config->opts->{$key}, case_insensitive => ( $cs ? 'false' : 'true' ) }
        }
      };

    } elsif ( $t eq 'regexp' ) {

      $query_type = { regexp => { $r => $self->config->opts->{$key} } };

    } elsif ( $t eq 'ip' ) {
      $query_type = {
        term => {
          $r => $self->config->opts->{$key}
        }
      };
    } elsif ( $t eq 'wildcard' ) {
      $query_type = {
        wildcard => {
          $r => { value => $self->config->opts->{$key}, case_insensitive => ( $cs ? 'false' : 'true' ) }
        }
      };

    } else {
      die("Unknown type $t");

    }

    push( @{ $query_filter->{bool}->{must} }, $query_type );
  }

  my $search = $self->opensearch->search->search;
  $search->query($query_filter)->size($size)
    ->sort( [ { '@timestamp' => { order => 'asc' } }, { '_id' => { order => 'asc' } } ] );
  $search->_source( OpenSearch::Filter::Source->new->includes( @{$fields} ) ) if $fields;
  $search->index($index)                                                      if $index;

  $self->search($search);
}

sub poll($self) {

  if ( $self->search_after->[0] ) {
    $self->search->search_after( $self->search_after );
  }

  $self->search->execute_p->then( sub($res) {
    my $last = $res->{hits}->{hits}->[-1];
    $self->search_after( $last->{sort} ) if ($last);
    $self->emit( 'messages', [ map { $_->{_source} } @{ $res->{hits}->{hits} } ] );
  } )->catch( sub($err) {
    $self->emit( 'error', $err );
  } );

}

1;
