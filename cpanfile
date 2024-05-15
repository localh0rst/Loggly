requires 'perl', '5.008001';
requires 'App::cpanminus';

on 'test' => sub {
    requires 'Test::More', '0.98';
    `cpanm https://github.com/localh0rst/OpenSearch-Perl.git`;
};

Data::Dumper;
Data::Format::Pretty::JSON
Getopt::Long
IO::Async::FileStream;
IO::Async::Loop::Mojo;
Module::Runtime
Mojo::IOLoop;
Mojo::UserAgent;
Moose;
MooseX::NonMoose;
MooseX::Singleton;
OpenSearch;
Scalar::Util
YAML::XS
