package Common::Genome ;
our @ISA = 'Common' ;


# Class method

sub genomes{
	my ($class , $ids , $query) = @_ ;
	my $response = $class->query_cdmi([ $offset , $limit , [ 
			"id" , "pegs" , "rnas" , "scientific-name" , "complete" , "prokaryotic" , "dna-size" , "contigs" ,
			"domain" , "genetic-code" , "phenotype" , "md5" , "source-id"] ], "all_entities", "Genome");
			
	
	return $class->response2list($list) ;
}

sub new {
	
	my ($Class , @options) = @_ ;
	my $obj = {
		id => '' ,
		name => '' ,
	};
	
	return bless $obj ;	
}

1;