package WebService::Careerjet;

use warnings;
use strict;

use URI::Escape ;
use LWP::UserAgent ;
use HTTP::Request ;
use Carp ;
use JSON;

=head1 NAME

WebService::Careerjet - Perl interface to Careerjet's public search API

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

This module provides a Perl interface to the public search API of Careerjet,
a vertical search engine for job offers that covers over 20 countries.
(http://www.careerjet.co.uk/?worldwide)

Example code:

    use WebService::Careerjet;

    # Create Perl interface to API
    my $careerjet = WebService::Careerjet->new('en_GB');

    # Perform a search
    my $result = $careerjet->search( {
                                      'keyword' => 'perl developer',
                                      'location' => 'london'
                                     } ) ;

    # Go through results
    if ( $result->{'type'} eq 'JOBS' ){
        print "Found ".$result->{'hits'}." jobs\n";
        my $jobs = $result->{'jobs'} ;

        foreach my $j(@$jobs){
          print "URL         :".$j->{'url'}."\n" ;
          print "TITLE       :".$j->{'title'}."\n" ;
          print "COMPANY     :".$j->{'company'}."\n" ;
          print "SALARY      :".$j->{'salary'}."\n" ;
          print "DATE        :".$j->{'date'}."\n";
          print "DESCRIPTION :".$j->{'description'}."\n" ;
          print "SITE        :".$j->{'site'}."\n" ;
          print "\n";
        }
    }

=head1 FUNCTIONS

=head2 new

Creates a Webservice::Careerjet search object for a given UNIX locale.
Each locale corresponds to an existing Careerjet site and determines
in which language job-related information is returned as well
as which default location filter is used. For example if your users
are primarily dutch-speaking Belgians use "nl_BE".
    
Usage:
    my $careerjet = WebService::Careerjet->new($locale);

Available locales:

    LOCALE     LANGUAGE         DEFAULT LOCATION     CAREERJET SITE
    cz_CZ      Czech Republic   Czech                http://www.careerjet.cz
    de_AT      German           Austria              http://www.careerjet.at
    de_CH      German           Switzerland          http://www.careerjet.ch
    de_DE      German           Germany              http://www.careerjet.de
    en_AU      English          Australia            http://www.careerjet.com.au
    en_CN      English          China                http://www.careerjet.cn
    en_CN      English          Hong Kong            http://www.careerjet.hk
    en_IE      English          Ireland              http://www.careerjet.ie
    en_IN      English          India                http://www.careerjet.co.in
    en_NZ      English          New Zealand          http://www.careerjet.co.nz
    en_PH      English          Philippines          http://www.careerjet.ph
    en_SG      English          Singapore            http://www.careerjet.sg
    en_GB      English          United Kingdom       http://www.careerjet.co.uk
    en_US      English          United States        http://www.careerjet.com
    en_ZA      English          South Africa         http://www.careerjet.co.za
    en_TW      English          Taiwan               http://www.careerjet.com.tw
    es_ES      Spanish          Spain                http://www.opcionempleo.com
    es_ES      Spanish          Mexico               http://www.opcionempleo.com.mx
    fr_BE      French           Belgium              http://www.optioncarriere.be
    fr_CH      French           Switzerland          http://www.optioncarriere.ch
    fr_FR      French           France               http://www.optioncarriere.com
    fr_LU      French           Luxembourg           http://www.optioncarriere.lu
    fr_MA      French           Marocco              http://www.optioncarriere.ma
    it_IT      Italian          Italy                http://www.careerjet.it
    nl_BE      Dutch            Belgium              http://www.careerjet.be
    nl_NL      Dutch            Netherlands          http://www.careerjet.nl
    pl_PL      Polish           Poland               http://www.careerjet.pl
    pt_PT      Portuguese       Portugal             http://www.careerjet.pt
    pt_BR      Portuguese       Brazil               http://www.careerjet.com.br
    sv_SE      Swedish          Sweden               http://www.careerjet.se
    sk_SK      Slovak           Slovakia             http://www.careerjet.sk

=cut
   
my %h_locale2base = ( 
    cz_CZ  => "http://www.careerjet.cz",
    de_AT  => "http://www.careerjet.at",
    de_CH  => "http://www.careerjet.ch",
    de_DE  => "http://www.careerjet.de",
    en_AU  => "http://www.careerjet.com.au",
    en_CN  => "http://www.careerjet.cn",
    en_CN  => "http://www.careerjet.hk",
    en_IE  => "http://www.careerjet.ie",
    en_IN  => "http://www.careerjet.co.in",
    en_NZ  => "http://www.careerjet.co.nz",
    en_PH  => "http://www.careerjet.ph",
    en_SG  => "http://www.careerjet.sg",
    en_GB  => "http://www.careerjet.co.uk",
    en_UK  => "http://www.careerjet.co.uk",
    en_US  => "http://www.careerjet.com",
    en_ZA  => "http://www.careerjet.co.za",
    en_TW  => "http://www.careerjet.com.tw",
    es_ES  => "http://www.opcionempleo.com",
    es_ES  => "http://www.opcionempleo.com.mx",
    fr_BE  => "http://www.optioncarriere.be",
    fr_CH  => "http://www.optioncarriere.ch",
    fr_FR  => "http://www.optioncarriere.com",
    fr_LU  => "http://www.optioncarriere.lu",
    fr_MA  => "http://www.optioncarriere.ma",
    it_IT  => "http://www.careerjet.it",
    nl_BE  => "http://www.careerjet.be",
    nl_NL  => "http://www.careerjet.nl",
    pl_PL  => "http://www.careerjet.pl",
    pt_PT  => "http://www.careerjet.pt",
    pt_BR  => "http://www.careerjet.com.br",
    sv_SE  => "http://www.careerjet.se",
    sk_SK  => "http://www.careerjet.sk",
);


sub new{
    my ($class, $locale) = @_ ;
    $locale ||= 'en_GB';

    my $base = $h_locale2base{$locale} || $h_locale2base{en_GB};

    my $ua = LWP::UserAgent->new() ;
    $ua->agent($class.'/'.$VERSION);
    
    my $self = {
        'base' => $base,
        'agent' => $ua
    };
    
    return bless $self , $class ;
}


sub _call{
    my ($self, $function, $args) = @_ ;
    
    my $url = $self->{'base'}.'/devel/'.$function.'.api?' ;
    foreach my $k ( keys %$args ){
        $url .= $k.'='.URI::Escape::uri_escape_utf8($args->{$k}).'&';
        
    }
    
    my $req = HTTP::Request->new( 'GET' => $url ) ;
    
    my $ret = undef ;
    
    my $res = $self->{'agent'}->request($req) ;
    if ( $res->is_success() ){
        my $content = $res->content() ;
        my $json = new JSON ;
        $ret = $json->jsonToObj($content) ;
    }
    else{
        $ret->{'type'} = 'ERROR' ;
        $ret->{'error'} = $res->status_line() ;
    }
    
    unless( defined $ret ){
        $ret = {'type' => 'ERROR',
                'error' => 'Json parsing error' };
    }
    
    return $ret ;
    
}

=head2 search

Performs a search using Careerjet's public search API.
Search parameters are passed on as a reference to a hash.
All options are outlined below.

Example:
    
    my $result = $api->search( { 'keywords' => 'perl developer' ,
                                 'location' => 'london' ,
                            });

    # The result is a job list if the location is not ambiguous
    if ( $result->{'type'} eq 'JOBS' ){
        print "Found ".$result->{'hits'}." jobs\n";
        print "Total number of result pages: ".$result->{'pages'}."\n";
        my $jobs = $result->{'jobs'} ;
        foreach my $j ( @$jobs ){
            print "URL         :".$j->{'url'}."\n" ;
            print "TITLE       :".$j->{'title'}."\n" ;
            print "COMPANY     :".$j->{'company'}."\n" ;
            print "SALARY      :".$j->{'salary'}."\n" ;
            print "DATE        :".$j->{'date'}."\n";
            print "DESCRIPTION :".$j->{'description'}."\n" ;
            print "SITE        :".$j->{'site'}."\n" ;
            print "\n" ;
        }
    
    }

    # If the location is ambiguous, a list of suggest locations
    # is returned
    if ( $result->{'type'} eq 'LOCATIONS' ){
        print "Suggested locations:\n" ;
        my $locations = $result->{'locations'} ;
        foreach my $l ( @$locations ){
            print "$l\n" ;
        }
    }


Options:

   All options have default values and are not mandatory
   
       keywords     :   Keywords to match either title, content or company name of job offerings
                        Examples: 'perl developper', 'ibm', 'software architect'
                        Default : none
   
       location     :   Loction of requested job postings.
                        Examples: 'London' , 'Yorkshire', 'France' 
                        Default: country specified by country code
   
       sort         :   Type of sort. This can be:
                         'relevance'  - sorted by decreasing relevancy (default)
                         'date'       - sorted by decreasing date
                         'salary'     - sorted by decreasing salary
   
       start_num    :   Position of returned job postings within the entire result space.
                        This should be a least 1 but not more than the total number of job offers.
                        Default : 1
   
       pagesize     :   Number of returned results
                        Default : 20

       page         :   Page number of returned job postings within the entire result space.
                        This can be used instead of start_num. The minimum page number is 1.
                        The maximum number of pages is given by $result->{'pages'}
                        If this value is set, it overrides start_num.
   
       contracttype :   Selected contract type. The following codes can be used: 
                         'p'    - permanent
                         'c'    - contract
                         't'    - temporary
                         'i'    - training
                         'v'    - voluntary
                        Default: none (all contract types)
       
       contractperiod : Selected contract period. The following codes can be used: 
                         'f'     - full time
                         'p'     - part time
                        Default: none (all contract periods)


=cut

sub search{
    my ($self, $args) = @_ ;
    my $ret = $self->_call('search' , $args ) ;
    
    if ( $ret->{'type'} eq 'ERROR' ){
        confess "CAREERJET ERROR: ".$ret->{'error'} ;
    }
    return $ret ;
}

=head1 AUTHORS

Jerome Eteve, Thomas Busch

=head1 FEEDBACK

Any feedback is welcome. Please send your suggestions to <api at careerjet.com>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Careerjet Ltd. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER
SOFTWARE), EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGES.

=cut

1; # End of WebService::Careerjet
