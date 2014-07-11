#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper ;
use Pod::Usage

use lib '/Users/Andi/Development/kbase/dev_container/modules/Babel/Dancer/MyWeb-App/lib' ;

use Common ;
use Common::Genome ;

my $common = new Common ;
my $genome = new Common::Genome ;

print Dumper $genome ;

print Dumper $genome->data_sources ;


my $offset = 0 ;
my $limit  = 10;

my $orgs = $common->query_cdmi([ $offset , $limit , [ 
			"id" , "pegs" , "rnas" , "scientific-name" , "complete" , "prokaryotic" , "dna-size" , "contigs" ,
			"domain" , "genetic-code" , "phenotype" , "md5" , "source-id"] ], "all_entities", "Genome");


print Dumper $common->response2list($orgs) ;



my $orgs = $common->get_list( [ 
			"id" , "pegs" , "rnas" , "scientific-name" , "complete" , "prokaryotic" , "dna-size" , "contigs" ,
			"domain" , "genetic-code" , "phenotype" , "md5" , "source-id"] , "all_entities", "Genome");
			
print Dumper $orgs ;			

#print Dumper $genome->query_cdmi([ $org2feature->{$org}, [ "id" ], [], [ "id", "sequence" ] ], "get_relationship", "Produces");