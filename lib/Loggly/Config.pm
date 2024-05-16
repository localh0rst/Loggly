package Loggly::Config;
use strict;
use warnings;
use OpenSearch;
use Moose;
use MooseX::Singleton;
use feature      qw/signatures/;
use YAML::XS     qw/LoadFile/;
use Getopt::Long qw/GetOptionsFromArray/;
use Loggly::Help;
use Module::Runtime qw/use_module/;

#use Mojo::EventEmitter;
use Data::Dumper;
our $VERSION = "0.01";

has '_cfg_file' => ( is => 'rw', isa => 'Str', default => $ENV{HOME} . "/.logglyrc" );
has '_args'     => ( is => 'rw', isa => 'ArrayRef' );
has 'cfg'       => ( is => 'rw', isa => 'HashRef' );

has 'logtype'   => ( is => 'rw' );
has 'logconfig' => ( is => 'rw' );
has 'opts'      => ( is => 'rw', isa => 'HashRef', default => sub { {} } );
has 'defaults'  => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

has 'follow'        => ( is => 'rw', isa => 'Bool', default => 0 );
has 'sink'          => ( is => 'rw', isa => 'Str' );
has 'source_config' => ( is => 'rw' );
has 'source'        => ( is => 'rw' );

has 'poll_interval' => ( is => 'rw', isa => 'Int' );

# TODO: Check required fields
# TODO: Allow comma separated values for fields. i.e. --code 200,400,500
# TODO: Allow multiple values for the same field. i.e. --code 200 --code 400
# TODO: Put every field that is requested with --<name> into @{$fields} in the config?
# TODO: Add a --debug option that will print out the query that is being sent to the source
sub BUILD {
  my $self = shift;

  # Create the config file if it doesn't exist
  my $file = $self->_cfg_file;
  unless ( -e $file ) {
    say STDERR "Creating new config in: " . $file;
    open( my $fh, '>', $file ) or die("Can't open file: $file for writing ($!).\n");
    print $fh <DATA>;
    close $fh;
  }

  $self->cfg( LoadFile($file) );
  $self->logconfig( $self->cfg->{logconfig}->{ $self->_args->[0] } ) if $self->_args->[0];
  $self->logtype( shift( @{ $self->_args } ) )                       if $self->logconfig;
  $self->defaults( $self->cfg->{defaults} );

  # Parse the command line options
  Getopt::Long::Configure("pass_through");
  GetOptionsFromArray(
    $self->_args,
    $self->opts,

    $self->logconfig
    ? (
      map {
            $_
          . ( $self->logconfig->{params}->{$_}->{short} ? '|' . $self->logconfig->{params}->{$_}->{short} : '' )
          . (
          $self->logconfig->{params}->{$_}->{type} =~ /i|s/
          ? "=" . $self->logconfig->{params}->{$_}->{type}
          : ""
          )
        }
        keys( %{ $self->logconfig->{params} } )
      )
    : (),

    (
      map {
            $_
          . ( $self->cfg->{defaults}->{$_}->{short} ? '|' . $self->cfg->{defaults}->{$_}->{short} : '' )
          . (
          $self->cfg->{defaults}->{$_}->{type} =~ /i|s/
          ? "=" . $self->cfg->{defaults}->{$_}->{type}
          : ""
          )
        }
        keys( %{ $self->cfg->{defaults} } )
    )
  );

  if ( !$self->logtype || !$self->logconfig || $self->opts->{help} ) {
    Loggly::Help->new->print;
    print Dumper "EXITING";
    exit 0;
  }

  # If we reached this, we have all required options
  $self->source_config( $self->cfg->{sources}->{ $self->cfg->{logconfig}->{ $self->logtype }->{source} } );
  if ( !$self->source_config ) {
    say STDERR "No source configuration found for: " . $self->logtype;
    exit 1;
  }

  $self->follow( $self->opts->{follow} // $self->logconfig->{follow} // $self->defaults->{follow}->{default} );

  $self->source( $self->source_config->{type} );

  if ( $self->opts->{sink} ) {
    $self->sink( $self->opts->{sink} );
  } elsif ( $self->opts->{json} ) {
    $self->sink( ucfirst('json') );
  } elsif ( $self->opts->{table} ) {
    $self->sink( ucfirst('table') );
  } else {
    $self->sink( $self->defaults->{sink}->{default} );
  }

  $self->poll_interval( $self->opts->{poll} // $self->logconfig->{poll} // $self->defaults->{poll}->{default} );

}

1;

__DATA__
---
sources:
  my-cluster-1:
    type: OpenSearch
    hosts: [my-cluster-1:9200, my-cluster-2:9200]
    user: admin
    pass: admin
    secure: 1
    allow_insecure: 1
defaults:
  # Defaults can be overridden by either the logconfig sections or the cli_options
  # Returning all fields only makes sense in the case of JSON output. 
  # Precedence: cli_options > logconfig > defaults
  sink:
    default: Print
    type: s
    description: Output sink. Default is Loggly::Sink::Print. Specifying --sink will overwrite --json and --table
  cs:
    default: false
    type: b
    description: Case insensitive search. Default is true.
  table: 
    default: false
    type: b
    description: Output in table format. Default is false. Usees Loggly::Sink::Table
  size:
    default: 1000
    type: i
    description: Number of results to return per query. Default is 1000. If limit is smaller, this will be overridden.
  limit:
    default: 0
    type: i
    description: Limit the number of results to return. Default is 0 aka unlimited.
  time:
    default: 1d
    type: s
    description: Time range. Default is 1d. Results in now-1d.
  poll:
    default: 1000
    type: i
    description: Poll interval in milliseconds. Default is 1000 (1s). This only applies to the --follow option after there have been no new results.
  json:
    default: false
    type: b
    description: Output in JSON format. Default is false. Uses Loggly::Sink::Json
  follow:
    short: f
    default: false
    type: b
    description: Follow (aka tail -f) the logs. Default is false.
  help:
    default: false
    type: b
    description: Print this help message. 

logconfig:
  dns_int:
    description: DNS Internal logs
    source: my-cluster-1
    # If you want to override the defaults, you can do so here. you only need to specify the fields you want to override.
    # i.e. json: true
    index: dns-internal-logs
    # Fields to return in the results. Default is all fields.
    fields:
      - event.original
      - query_class
      - query_type
    field_print: event.original
    # Make sure not to overwrite any default cli options (size, limit, time, etc.)
    params:
      ns:
        short: n
        type: s
        description: Nameserver IP address to filter on.
        field_name: nameserver_ip
        query_type: ip
        required: false
      srcip:
        short: s
        type: s
        description: Nameserver IP address to filter on.
        field_name: nameserver_ip
        query_type: ip
        required: false
      query:
        short: q
        type: s
        description: DNS query name
        field_name: q.keyword
        query_type: wildcard
        case_sensitive: true
        required: false
      class:
        short: c
        type: s
        description: DNS query class
        field_name: query_class.keyword
        query_type: term
        case_sensitive: false
        required: false
      type:
        short: t
        type: s
        description: DNS query type
        field_name: query_type.keyword
        query_type: term
        case_sensitive: false
        required: false


        
        
      
    

