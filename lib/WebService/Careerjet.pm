package WebService::Careerjet;

use warnings;
use strict;

use URI::Escape ;
use LWP::UserAgent ;
use HTTP::Request ;
use Carp ;
use JSON;

=head1 NAME

WebService::Careerjet - Remote access to careerjet job database

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

This module allows you to remotely perform searches in Careerjet job database.

Example code:

    use WebService::Careerjet;

    # Build the interface
   
    my $careerjet = WebService::Careerjet->new('http://api.careerjet.co.uk');
    # To get jobs from USA site, use http://api.careerjet.com 
    # To get jobs from France site, use http://api.optioncarriere.com
    
    # Call API functions ( see functions for details )  
    my $result = $careerjet->search( {
                                      'keyword' => 'perl developer',
                                      'location' => 'london'
                                     } ) ;

    if ( $result->{'type'} eq 'JOBS' ){
        print "Got ".$result->{'hits'}." jobs: \n";
        print " On ".$result->{'pages'}." pages \n" ;
        my $jobs = $result->{'jobs'} ;
        foreach my $j ( @$jobs ){
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

Returns a new instance of this api client.
    
Usage:
    
    my $careerjet = WebService::Careerjet->new() ;
    # Default: uses the UK site
    # Or
    my $careerjet = WebService::Careerjet->new('http://api.careerjet.com');
    # To use the USA site job offers

You can use this api for any Careerjet WebSite.
For instance if you want to use offers from http://www.optioncarriere.com/ ,
use http://api.optioncarriere.com .

=cut

sub new{
    my ($class, $base) = @_ ;
    $base ||= 'http://api.careerjet.co.uk' ;
    
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

Performs a search in the Careerjet job database.
The search options are given as a reference on a hash.

See Options for all details about available options

Example:
    
    my $result = $api->search( { 'keywords' => 'perl developer' ,
                                 'location' => 'london' ,
                            });

    # The result is a job list if the location is not ambiguous
    if ( $result->{'type'} eq 'JOBS' ){
        print "Got ".$result->{'hits'}." jobs: \n";
        print " On ".$result->{'pages'}." pages\n";
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

    # In case the location is ambiguous, result contains
    # a list of suggested location
    if ( $result->{'type'} eq 'LOCATIONS' ){
        print "Suggested locations:\n" ;
        my $locations = $result->{'locations'} ;
        foreach my $l ( @$locations ){
            print "$l\n" ;
        }
    }


Options:

   All options have default values and are not mandatory
   
       keywords     : Keywords to search in job offers. Example: 'java manager'
                      Default : none (All offers in the api country)
   
       location     : Location to search job offers in. Examples: 'London' , 'Yorkshire' ..
                      Default: none ( All offers in the api country)
   
       sort         : Type of sort. Can be:
                       'relevance' (default) - most relevant first 
                       'date'                - freshest offer first 
                       'salary'              - biggest salary first
   
       offset       : Offset of first offer returned in entire result space
                      should be >= 1 and <= Number of hits
                      Default : 1 
   
       pagesize     : Number of offers returned in one call
                      Default : 20

       page         : Number of the asked page. 
                      should be >=1
                      The max number of pages is given by $result->{'pages'}
                      If this value is set, the eventually given offset is overrided
   
       contracttype : Character code for contract type
                       'p'    - permanent job
                       'c'    - contract
                       't'    - temporary
                       'i'    - training
                       'v'    - voluntary
                      Default: none (all contract types)
       
       contractperiod : Character code for contract work period:
                         'f'     - Full time
                         'p'     - Part time
                        Default: none (all work period)


=cut

sub search{
    my ($self, $args) = @_ ;
    my $ret = $self->_call('search' , $args ) ;
    
    if ( $ret->{'type'} eq 'ERROR' ){
        confess "CAREERJET ERROR: ".$ret->{'error'} ;
    }
    return $ret ;
}


=head1 AUTHOR

Jerome Eteve, C<< <api at careerjet.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-webservice-careerjet at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Careerjet>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Careerjet

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Careerjet>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Careerjet>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Careerjet>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Careerjet>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Careerjet Ltd. , all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of WebService::Careerjet
