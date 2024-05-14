requires 'perl', '5.008001';
requires 'App::cpanminus';
#requires 'https://github.com/localh0rst/OpenSearch-Perl.git';
# There sure is a better way to do this...

on 'test' => sub {
    requires 'Test::More', '0.98';
    `cpanm https://github.com/localh0rst/OpenSearch-Perl.git`;
};

on 'build' => sub {
    requires 'Test::More', '0.98';
    `cpanm https://github.com/localh0rst/OpenSearch-Perl.git`;
};

on 'build' => sub {
    requires 'Test::More', '0.98';
    `cpanm https://github.com/localh0rst/OpenSearch-Perl.git`;
};
