requires 'perl', '5.008001';
requires 'OpenSearch', git => 'https://github.com/localh0rst/OpenSearch-Perl.git';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

