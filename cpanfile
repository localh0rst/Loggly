requires 'perl', '5.008001';
requires 'Data::Dumper';
requires 'Data::Format::Pretty::JSON';
requires 'Getopt::Long';
requires 'IO::Async::FileStream';
requires 'IO::Async::Loop::Mojo';
requires 'Module::Runtime';
requires 'Mojo::IOLoop';
requires 'Mojo::UserAgent';
requires 'Moose';
requires 'MooseX::NonMoose';
requires 'MooseX::Singleton';
requires 'OpenSearch';
requires 'Scalar::Util';
requires 'YAML::XS';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

