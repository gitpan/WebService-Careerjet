use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'WebService::Careerjet',
    AUTHOR              => 'Jerome Eteve <api@careerjet.com>',
    VERSION_FROM        => 'lib/WebService/Careerjet.pm',
    ABSTRACT_FROM       => 'lib/WebService/Careerjet.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/jobsearch' ] ,
    PREREQ_PM => {
        'Test::More' => 0,
        'URI::Escape' => 3.28,
        'LWP::UserAgent' => 2.033,
        'HTTP::Request'  => 1.40,
        'Carp'           => 1.03,
        'JSON'           => 1.05,
        'Getopt::Std'    => 1.05,
        'Text::Wrap'     => 2001.09292
        
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'WebService-Careerjet-*' },
);
