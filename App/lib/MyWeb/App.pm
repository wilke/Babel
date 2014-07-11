package MyWeb::App;
use Dancer ':syntax';


#use Data::Dumper ;
use LWP::UserAgent;
use HTTP::Request::Common;
use Data::Dumper;
use JSON;

#CONFIG
our $VERSION = '0.1';
my $prefix   = "/data" ;
my $base_url = "http://0.0.0.0:3000";
my $cdmi_url = "https://www.kbase.us/services/cdmi_api";
my $default_limit = 100 ;


# Global variables
my $ua = LWP::UserAgent->new;
$ua->agent("MyClientAW/0.1 ");

my $json = new JSON;

my $list_block = {
	'next' => '',
	'previous' => '',
	'data' => [] ,
	'total_count' => '',
	'order' => '' ,
	'url' => '',
	'limit' => '' ,
	'offset' => ''
} ;		



# Define routes/resources

get '/' => sub {
    template 'index';
};

get "/metagenome" => sub {
	
	my $url = "http://kbase.us/services/communities/1/metagenome" ;
	
	my $options = params ;
	
	if (keys %$options) {
		my $opt = join "&" , (map { $_ . "=" . $options->{$_} } keys %$options) ;
		$url .= "?$opt" ;
		#return to_dumper $options ;
	}
	
	my $response = $ua->get($url) ;
	
	headers 'Content-Type' => 'application/json' ;
	return $response->content ;
};

# Genome data
get "/genome" => sub {

	my  $definition = { "requests" => [ 
									{ 
										"parameters" => { "body" => { }, "path"=> { }, "params" => { } }, 
										"request"=> "$base_url/genome", 
										"name"=> "info/documentation",
										"type"=> "synchronous", 
										"method"=> "GET/ANY", 
										"attributes"=> "self", 
										"description"=> "Returns description of parameters and attributes." 
									}, 
									{
										"request"=> "$base_url/genome", 
										"example"=> [ "$base_url/genome?limit=20&order=name", "retrieve the first 20 metagenomes ordered by name" ], 
										"name"=> "query",
										"description"=> "Returns a list of genomes.", 
										"parameters"=> { 
											"body"=> { }, 
											"path"=> { }, 
											"params"=> { 
												"verbosity"=> [ "cv", [ 
													[ "minimal", "returns only minimal information" ], 
													[ "metadata", "returns minimal with metadata" ], 
													[ "stats", "returns minimal with statistics" ], 
													[ "full", "returns all metadata and statistics" ] ] ], 
												"function"=> [ "string", "search parameter: query string for function" ], 
												"status"=> [ "cv", [ 
													[ "both", "returns all data (public and private) user has access to view" ], 
													[ "public", "returns all public data" ], 
													[ "private", "returns private data user has access to view" ] ] ], 
												"match"=> [ "cv", [ 
													[ "all", "return metagenomes that match all search parameters" ], 
													[ "any", "return metagenomes that match any search parameters" ] ] ], 
												"direction"=> [ "cv", [ 
													[ "asc", "sort by ascending order" ], 
													[ "desc", "sort by descending order" ] ] ], 
												"order"=> [ "string", "metagenome object field to sort by (default is id)" ], 
												"metadata"=> [ "string", "search parameter: query string for any metadata field" ], 
												"limit"=> [ "integer", "maximum number of items requested" ],
												"md5"=> [ "string", "search parameter: md5 checksum of feature sequence" ], 
												"organism"=> [ "string", "search parameter: query string for organism" ],
												"offset"=> [ "integer", "zero based index of the first data object to be returned" ] }
											 }, 
										"method" => "GET", 
										"type" => "synchronous", 
										"attributes" => { 
											"next"=> [ "uri", "link to the previous set or null if this is the first set" ], 
											"prev"=> [ "uri", "link to the next set or null if this is the last set" ], 
											"version"=> [ "integer", "version of the object" ], 
											"data"=> [ "list", [ 
												"object", [ 
												{ 
													"ID"=> [ "string","Genome ID" ], 
													"name"=> [ "string" , "Genome name" ], 
													"status"=> [ "cv", [ 
														[ "public", "genome is public" ], 
														[ "private", "genome is private" ] ] ], 
													"size"=> [ "int", "Number of base pairs" ],
													"features"=> [ "list", [ "string" , "list of feature IDs" ] ],
													"url"=> [ "uri", "resource location of this object instance" ],
													"seq_method"=> [ "string", "sequencing method" ], 
													"created" => [ "date", "time the metagenome was first created" ] 
												}, 
												"gemome object" ] ] ], 
											"total_count"=> [ "integer", "total number of available data items" ], 
											"order"=> [ "string", "name of the attribute the returned data is ordered by" ], 
											"url"=> [ "uri", "resource location of this object instance" ], 
											"limit"=> [ "integer", "maximum number of data items returned, default is 10" ], 
											"offset"=> [ "integer", "zero based index of the first returned data item" ] 
										} 
									}
								] 
	};


    my $list_block = {
    	'next' => '',
		'previous' => '',
		'data' => [] ,
		'total_count' => '',
		'order' => '' ,
		'url' => '',
		'limit' => '' ,
		'offset' => ''
    } ;				
				
	my $genome = {
		"id" => '' , 
		"pegs" => '' , 
		"rnas" => '' , 
		"scientific-name" => '', 
		"complete" => '', 
		"prokaryotic" => '', 
		"dna-size" , "contigs" ,
		"domain" => '', 
		"genetic-code" => '', 
		"phenotype" => '', 
		"md5" => '', 
		"source-id" => ''
	};


	my $options = params ;
	
	if (keys %$options) {
		
		my $offset = $options->{offset} || "0" ;
		my $limit  = $options->{limit}  || $default_limit ;
		
		my $return = $list_block ;
		
		my $list = query([ $offset , $limit , [ 
			"id" , "pegs" , "rnas" , "scientific-name" , "complete" , "prokaryotic" , "dna-size" , "contigs" ,
			"domain" , "genetic-code" , "phenotype" , "md5" , "source-id"] ], "all_entities", "Genome");
		
		
			
		if( scalar @$list ){
			$return->{limit}  = $limit ;
			$return->{offset} = $offset;
			
			my $noffset = $offset + $limit ;
			my %noptions = %$options ;
			$noptions{next} = $noffset ;
			
			my $opt = join "&" , (map { $_ . "=" . $noptions{$_} } keys %noptions) ;
			$return->{next}   = $base_url . "/genome?$opt" ;
			
			
			my $poffset = $offset - $limit ;
			if ($poffset ge 0 ) { 
				my %poptions = %$options ;
				$poptions{prev} = $poffset;
				
				my $opt = join "&" , (map { $_ . "=" . $poptions{$_} } keys %poptions) ;
				$return->{prev}   = $base_url . "/genome?$opt" ;
			}
			else{
				$return->{prev} = '' ;
			}
		}	
			
		# walk through smart return structure	
		foreach my $struct ( @$list ) {
			foreach my $id (keys %$struct) {
				my $obj = $struct->{$id} ;
				$obj->{id} = $id ,
				$obj->{url} = $base_url . "/genome/$id" ;
				push @{$return->{data}} , $obj ;
			}
		}
		
		# id	string	Unique identifier for this Genome.
# 		pegs	int	Number of protein encoding genes for this genome.
# 		rnas	int	Number of RNA features found for this organism.
# 		scientific-name	string	Full genus/species/strain name of the genome sequence.
# 		complete	boolean	TRUE if the genome sequence is complete, else FALSE
# 		prokaryotic	boolean	TRUE if this is a prokaryotic genome sequence, else FALSE
# 		dna-size	counter	Number of base pairs in the genome sequence.
# 		contigs	int	Number of contigs for this genome sequence.
# 		domain	string	Domain for this organism (Archaea, Bacteria, Eukaryota, Virus, Plasmid, or Environmental Sample).
# 		genetic-code	int	Genetic code number used for protein translation on most of this genome sequence's contigs.
# 		gc-content	float	Percent GC content present in the genome sequence's DNA.
# 		phenotype	string	zero or more strings describing phenotypic information about this genome sequence
# 		md5	string	MD5 identifier describing the genome's DNA sequence
# 		source-id	string	identifier assigned to this genome by the original source
		
		headers 'Content-Type' => 'application/json' ;
		return to_json $return ;

	}
	
	headers 'Content-Type' => 'application/json' ;
	return to_json $definition ;
};

get "/genome/" => sub { &genome } ;

get '/genome/:id' => sub {

    my $options = params;

    my $id = $options->{id};
    delete $options->{id};

    my $list = query(
        [
			[$id],
			[
                "id",        "pegs",
                "rnas",      "scientific-name",
                "complete",  "prokaryotic",
                "dna-size",  "contigs",
                "domain",    "genetic-code",
                "phenotype", "md5",
                "source-id"
			]
        ],
        "get_entity",
        "Genome"
    );


	my $return = {};
	foreach my $struct ( @$list ) {
		foreach my $id (keys %$struct) {
			my $obj = $struct->{$id} ;
			$obj->{id}  = { id => $id ,
							ref => $base_url . "/genome/$id" 
						};
			$obj->{features} = { pegs => $struct->{$id}->{pegs} ,
								rnas =>	$struct->{$id}->{rnas} ,	
								ref => { id => "$id/feature" ,
										url => $base_url . "/genome/$id/feature" ,
									}
								};			
			$obj->{url} = $base_url . "/sequence/$id" ;
			$return = $obj ;
		}
	}


    headers 'Content-Type' => 'application/json';
    return to_json $return ;
};


get "/sequence" => sub {
 
	 my $offset = 0 ;
	 my $limit  = 100 ;
 
     my $options = params;

     my $id = $options->{id};
     delete $options->{id};



	my $list = query([ $offset , $limit , [
                 							"id",        
                 						   	"sequence",  
 				 						  ], 
				], "all_entities", "ProteinSequence");



	my %return = %$list_block ;
 	foreach my $struct ( @$list ) {
 		foreach my $id (keys %$struct) {
 			my $obj = $struct->{$id} ;
 			$obj->{id} = $id ,
 			$obj->{url} = $base_url . "/sequence/$id" ;
 			# $return = $obj ;
			push @{ $return{data} } , $obj ;
 		}
 	}


     headers 'Content-Type' => 'application/json';
     return to_json \%return ;	
	
 };


get "/relationship/:id" => sub {
	
     my $options = params;
     my $id = $options->{id};

 	# my $list = query([ $id , [
 #              							"from_link",
 #              						   	"to_link",
 # 			 						  ],
 # 									  ], "get_relationship", "IsOwnedBy");

 	my $list = query([ [$id] , [ "id" , "pegs" , "source-id" ], ["from-link" , "to-link"], ["id" , "function" , "feature-type" , "source-id" , "alias"] ], "get_relationship", "IsOwnerOf");

 	#print STDERR Dumper $list ;

 	my %return = %$list_block ;
 	foreach my $res ( @$list ) {
	
		# create list of feature IDs for protein sequence query
		# want to make call once with all IDs instead of a single call per ID
		my $ids = [] ;
		map { push @$ids , $_->[2]->{id} } @$res ;
	
	 	my $seq_list = query([ $ids , [ "id" , "feature-type"], ["from-link" , "to-link"], ["id" , "sequence"] ], 
		"get_relationship", "Produces");
		
		my $feature2seq = {};	
		foreach my $res ( @$seq_list ) {
 			foreach my $triple (@$res) {
				print STDERR Dumper $triple ;
				# feature ID
				my $fid = $triple->[0]->{id} ;
				
				$feature2seq->{ $fid } = { "feature-type" => [] ,
				 							"md5" => $triple->[2]->{"id"} ,
											"sequence" => $triple->[2]->{"sequence"},
													 } ;
				push @{ $feature2seq->{ $fid }->{"feature-type"} } ,  $triple->[0]->{"feature-type"} ;
				 									 
			}
		}
		
	
		# build return structure
 		foreach my $triple (@$res) {
			
 				
			
 			my $obj = $triple->[2] ;
 			$obj->{genome} = { id => $id  ,
 							   url => $base_url . "/genome/" . $triple->[0]->{id} ,
 							};	
			$obj->{seq} = $feature2seq->{$id} ;				
 			$obj->{url} = $base_url . "/relationship/$id" ;
 			# $return = $obj ;
 			push @{ $return{data} } , $obj ;
 		}
 	}

	


  headers 'Content-Type' => 'application/json';
  return to_json \%return ;	

 };

# Features for a genome
get "/genome/:id/feature/:fid" => sub {
 	my $id  = params->{id};
	my $fid = params->{fid};	
 	return forward "/genome/$id/feature" , { "fid" => $fid } ;
};
    
get "/genome/:id/feature/" => sub {
	my $id = params->{id};	
	forward "/genome/$id/feature";
};

get "/genome/:id/feature" => sub {
	
    my $options = params;
    my $id = $options->{id};

	my ($fid) = $options->{fid} || undef;

	# my $list = query([ $id , [
#              							"from_link",
#              						   	"to_link",
# 			 						  ],
# 									  ], "get_relationship", "IsOwnedBy");


	# TODO
	if ($fid) {
	
		# get single feature
	
	}
	else{
		# get all features
	}


	# Needs to be structed
	# Get all features for genome
	my $list = query([ [$id] , [ "id" , "pegs" , "source-id" ], ["from-link" , "to-link"], ["id" , "function" , "feature-type" , "source-id" , "alias"] ], "get_relationship", "IsOwnerOf");

	#print STDERR Dumper $list ;

	my %return = %$list_block ;
	foreach my $res ( @$list ) {
	
	
	
		# create list of feature IDs for protein sequence query
		# want to make call once with all IDs instead of a single call per ID
		my $ids = [] ;
		map { push @$ids , $_->[2]->{id} } @$res ;
	
		# get  sequences
	 	my $seq_list = query([ $ids , [ "id" , "feature-type"], ["from-link" , "to-link"], ["id" , "sequence"] ], 
		"get_relationship", "Produces");
		
		my $feature2seq = {};	
		foreach my $res ( @$seq_list ) {
 			foreach my $triple (@$res) {
				# print STDERR Dumper $triple ;
		
				# feature ID
				my $fid = $triple->[0]->{id} ;
				
				
				$feature2seq->{ $fid } = { "feature-type" => [] ,
				 							"md5" => $triple->[2]->{"id"} ,
											"sequence" => $triple->[2]->{"sequence"},
													 } ;
				push @{ $feature2seq->{ $fid }->{"feature-type"} } ,  $triple->[0]->{"feature_type"} ;
				 									 
			}
		}
	
	
		# get roles
		my $roles = {} ;
	 	my $role_list = query([ $ids , [ "id" ], ["from-link" , "to-link"], ["id" , "hypothetical"] ], 
		"get_relationship", "HasFunctional");
		
		my $feature2role = {};	
		foreach my $res ( @$role_list ) {
 			foreach my $triple (@$res) {
				#print STDERR Dumper $triple ;
				# feature ID
				my $fid = $triple->[0]->{id} ;
				push @{ $feature2role->{ $fid } } , $triple->[2] ;
				$roles->{ $triple->[2]->{id} }++ ;
			}
		}
		
		# END #
		
		
		# get Subsystems
		
	 	# my $ss_list = query([ [ keys %$roles ] , [ "id" ], ["from-link" , "to-link"], ["id" , "version" , "curator" , "notes" , "description"
	# 	, "usable" , "private" , "cluster-based" , "functional-coupling" , "experimental"] ],
	# 	"get_relationship", "IsIncludedIn");
		
	 	my $ss_list = query([ [ keys %$roles ] , [ "id" ], ["from-link" , "to-link"], ["id" ,"version"] ], 
		"get_relationship", "IsIncludedIn");
		
		# id	string	Unique identifier for this Subsystem.
	# 	version	int	version number for the subsystem. This value is incremented each time the subsystem is backed up.
	# 	curator	string	name of the person currently in charge of the subsystem
	# 	notes	text	descriptive notes about the subsystem
	# 	description	text	description of the subsystem's function in the cell
	# 	usable	boolean	TRUE if this is a usable subsystem, else FALSE. An unusable subsystem is one that is experimental or is of such low quality that it can negatively affect analysis.
	# 	private	boolean	TRUE if this is a private subsystem, else FALSE. A private subsystem has valid data, but is not considered ready for general distribution.
	# 	cluster-based	boolean	TRUE if this is a clustering-based subsystem, else FALSE. A clustering-based subsystem is one in which there is functional-coupling evidence that genes belong together, but we do not yet know what they do.
	# 	experimental	boolean	TRUE if this is an experimental subsystem, else FALSE. An experimental subsystem is designed for investigation and is not yet ready to be used in comparative analysis and annotation.
	
	print STDERR Dumper $ss_list ;
	
		my $role2subsystems = {};	
		foreach my $res ( @$ss_list ) {
 			foreach my $triple (@$res) {
				print STDERR Dumper $triple ;
				# feature ID
				my $role = $triple->[0]->{id} ;
				push @{ $role2subsystems->{ $role } } , $triple->[2] ;
			}
		}
		
		# END
	

	
	
	
		# construct return 
		foreach my $triple (@$res) {
			
			my $fid = $triple->[2]->{id} ;
			
			my $obj = $triple->[2] ;
			$obj->{genome} = { id => $id  ,
							   url => $base_url . "/genome/" . $triple->[0]->{id} ,
							};	
			$obj->{url} = $base_url . "/genome/$id/feature/$fid" ;
			$obj->{sequence} = $feature2seq->{$fid} ;
			$obj->{functional_roles} = $feature2role->{$fid} || [] ;
			
			$obj->{subsystems} = [] ;
			foreach my $role ( @{ $feature2role->{$fid} } ){
				foreach my $ss ( @{ $role2subsystems->{ $role->{id} } } ){
					push @{ $obj->{subsystems} } , $ss ;
				}
		 
			} 
			
			
			# $return = $obj ;
			push @{ $return{data} } , $obj ;
		}
	}


 headers 'Content-Type' => 'application/json';
 return to_json \%return ;	
};



get "/subsystem/:id" => sub {
 	my $id  = params->{id};	
 	return forward "/subsystem" , { "id" => $id } ;
};

get "/subsystem" => sub {
 
 	my $options = params;
 
	 my $offset = $options->{offset} || 0 ;
	 my $limit  = $options->{limit}  || 100 ;
 
     my $options = params;

     my $id = $options->{id};
     delete $options->{id};

	 # return structure , empty has to be filled 
	 my %return ; 

	 # single subsystem definition
	 my $subsystem = {
	 	
		 id => '' ,	
		 version => '',
		 curator => '',
		 notes => '' ,
		 description => '',
		 usable	=> '',
		 private => '',
		 'cluster-based' => '',
		 experimental => '' ,
	 };

	 # retrieve single subsystem
	 if ($id){
	 	
	    
		 my $list = query([ [$id] , [ 'id','version','curator', 'notes','description','usable','private','cluster-based','experimental'] ], 
		 "get_entity", "Subsystem" );
		 

	 	foreach my $struct ( @$list ) {
	 		foreach my $id (keys %$struct) {
	 			my $obj = $struct->{$id} ;
	 			$obj->{id}  = { id => $id ,
	 							ref => $base_url . "/subsystem/$id" 
	 						};
				my ($roles , $error) = &get_role([$id] , 'subsystem') ; 			
	 			$obj->{roles} = $error || $roles ; 	
	 			
				$obj->{url} = $base_url . "/subsystem/$id" ;
	 			%return = %$obj ;
	 		}
	 	}
		
	 }
	 # retrieve all subsystems
	 else{

		 my $list = query([ $offset , $limit , [ 'id','version','curator', 'notes','description','usable','private','cluster-based','experimental'] ], 
		 "all_entities", "Subsystem" );


		 %return = %$list_block ;
 		 foreach my $struct ( @$list ) {
 			 foreach my $id (keys %$struct) {
 				 my $obj = $struct->{$id} ;
 				 $obj->{id} = $id ,
 				 $obj->{url} = $base_url . "/subsystem/$id" ;
 				 # $return = $obj ;
				 push @{ $return{data} } , $obj ;
 			 }
 		 }
	 }


     headers 'Content-Type' => 'application/json';
     return to_json \%return ;	
	
};



 sub subsystem {
	 my ($id) = @_ ;
	 
	 my $offset = 0 ;
	 my $limit = 100 ;
	 my $list = [];
	 
	 if ($id) {
	 	
	 }
	 else{
	 	
	 	my $list = query([ $offset , $limit , [ 'id','version','curator', 'notes','description','usable','private','cluster-based','experimental'] ], 
	 	"all_entities", "Subsystem" );
		
	 }
	 
	 return $list ;
 };

 sub genome {
 	return "HALLO"
 };

sub get_feature{
	 my ($ids , $type ) = @_ ;
	 
	 # type of $ids is one of feature , genome , subsystem , role   

	 print STDERR Dumper $ids , $type ;
	 
	 	 #
	 # id	string	Unique identifier for this Feature.
	 # feature-type	string	Code indicating the type of this feature. Among the codes currently supported are "peg" for a protein encoding gene, "bs" for a binding site, "opr" for an operon, and so forth.
	 # source-id	string	ID for this feature in its original source (core) database
	 # sequence-length	counter	Number of base pairs in this feature.
	 # function	text	Functional assignment for this feature. This will often indicate the feature's functional role or roles, and may also have comments.
	 # alias
	 
	 # template for role structure
	 my $template = {	
						'id'   				=> '' ,
						'url'  				=> '$base_url . "/role' ,
						'function' 			=> '',
						'alias'     		=> '',
						'feature_type' 		=> '' ,
						'source_id' 		=> '' ,
						'sequence_length' 	=> '' ,
						'sequence'        	=> {
							'dna' 		=> '' ,
							'protein' 	=> '',
						},
						'links' 			=> [ { rel => 'self' , href => $base_url . "/feature" } ] , 
							
					};
				
	my $error = undef ;	
	my $list = [] ; # list of roles	
	
	# type feature  -> entity Feature 
	# type organism -> relationship IsOwnerOf
	# type role     -> relationship IsFunctionalIn
	
	if ($type eq 'role'){
		# get features for role
		
		
		my $feature_list = query([ $ids , [ 'id'] , [ ] , ['id','feature-type' , 'source-id' , 'sequence-length' , 'function' , 'alias'] ], 
	 	"get_relationship", "IsFunctionalIn" );
		
		foreach my $res ( @$feature_list ) {
			
			# collect all feature IDs and retrieve sequences
			my $fids = [] ;
			map { push @$fids , $_->[2]->{id} } @$res ;
			my $id2seq = &get_sequence($fids , 'feature');
			
			# Create feature
 			foreach my $triple (@$res) {
				print STDERR Dumper $triple ;
				
				my $feature = {} ;
				%$feature = %$template ;
				
				# feature and role ID
				my $fid = $triple->[2]->{id} ;
				my $rid = $triple->[0]->{id} ;
				
				$feature->{id}  = $fid ;
				my ($oid) = $fid =~ /(kb\|g\.\d+)/ ;
				$feature->{url} = $base_url . "/genome/$oid/feature/$fid" ;
				
				$feature->{'feature_type'} 	= $triple->[2]->{'feature_type'} ;
				$feature->{'source_id'} 	= $triple->[2]->{'source_id'} ;
				$feature->{'function'}		= $triple->[2]->{'function'} ;
				$feature->{'alias'} 		= $triple->[2]->{'alias'};
				$feature->{'sequence'} 		= $id2seq->{$fid} ;
				$feature->{'sequence_length'} = $triple->[2]->{'alias'};
				
				push @$list , $feature ;
				
			}
		}
			
		
	}
	else{
		return ['not implemented'] ;
	}
	
	return $list ;
}


sub get_sequence{
	my ($ids , $type) = @_;
	my $list = [] ;
	
	# get sequences for Features
	
 	my $seq_list = query([ $ids , [ "id" , "feature-type"], ["from-link" , "to-link"], ["id" , "sequence"] ], 
	"get_relationship", "Produces");
	
	my $id2seq = {};	
	foreach my $res ( @$seq_list ) {
		foreach my $triple (@$res) {
			# print STDERR Dumper $triple ;
	
			# feature ID
			my $fid = $triple->[0]->{id} ;
			
			
			$id2seq->{ $fid } = { "feature-type" => [] ,
			 							"md5" => $triple->[2]->{"id"} ,
										"sequence" => $triple->[2]->{"sequence"},
												 } ;
			push @{ $id2seq->{ $fid }->{"feature-type"} } ,  $triple->[0]->{"feature_type"} ;
			 									 
		}
	}
	
	return $id2seq ;
}

sub get_role{
	 my ($ids , $type , $subsystem) = @_ ;
	 

	 error "ERROR: not a reference $ids" unless (ref $ids) ;
	 
	 print STDERR Dumper $ids , $type ;
	 
	 # template for role structure
	 my $template = {	
		 				name => '' ,
						id   => '' ,
						url  => '$base_url . "/role' ,
						links => [ { rel => 'self' , href => $base_url . "/role" } ] , 
						features => [],	
					};
				
	my $error = undef ;	
	my $list = [] ; # list of roles		
	 
	 	 # type of ID can be either 'role' or 'subsystem'
	 unless ( $type eq 'role' or 'subsystem'){
		 print STDERR "Error: Invalid value for parameter type in function get_rols (type=".($type || 'undef').").\n";
		 return $template , $error ;
	 }
	 
	 
	 
	
		
	# if $id get role for every ID
	# else get all roles		
	
	
	if (ref $ids and @$ids){	
		debug 'Retrieving data for IDs\n'; 
		
		if ($type eq 'subsystem') {
			# retrieve roles in subsystem
			 
			debug 'Retrieving data for subsytems' ;
			
			my $role_list = query([ $ids , [ 'id'] , [
				'from-link' , 'to-link' , 'sequence' , 'abbreviation' , 'auxiliary'] , ['id','hypothetical'] ], 
		 	"get_relationship", "Includes" );
		
			debug Dumper $role_list ;
	
			foreach my $res ( @$role_list ) {
	 			foreach my $triple (@$res) {
					print STDERR Dumper $triple ;
					# role ID
					my $rid = $triple->[2]->{id} ;
					my $sid = $triple->[0]->{id} ;
					
					my $role  = {} ;
					%$role = %$template ;
					
					$role->{name} 			= $rid ;
					$role->{hypothetical}	= $triple->[2]->{hypothetical} ; 
					$role->{subsystem} 		= $sid ;
					$role->{id}				= $rid ;
					$role->{url}			= $base_url . "subsystem/$sid/role/$rid" ;
					$role->{links} 			= { 
												rel => 'self' ,
									 		   	href => $base_url . "/subsystem/$sid/role/$rid" , 
											}; 
					$role->{features}		= &get_feature( [$rid] , 'role' );
					 
					 
					push @{ $list } , $role ;
				}
			}
	
				
		}
		else{
			
			# retrieve role information for id/role name
		 	my $role_list = query([ $ids , [ 'id','hypothetical'] , [
				'from-link' , 'to-link' , 'sequence' , 'abbreviation' , 'auxiliary'] , ['id'] ], 
		 	"get_relationship", "IsIncludedIn" );
			
			foreach my $res ( @$role_list ) {
	 			foreach my $triple (@$res) {
					print STDERR Dumper $triple ;
					# role ID
					my $rid = $triple->[1]->{id} ;
					my $sid = $triple->[2]->{id} ;
					
					my $role = {};
					%$role = %$template ;
					
			
					 
											$role->{name} 			= $rid ;
											$role->{hypothetical}	= $triple->[1]->{hypothetical} ; 
											$role->{subsystem} 		= $sid ;
											$role->{id}				= $rid ;
											$role->{url}			= $base_url . "subsystem/$sid/role/$rid" ;
											$role->{links} 			= { 
																		rel => 'self' ,
															 		   	href => $base_url . "subsystem/$sid/role/$rid" , 
																	};
											$role->{features}		= &get_role( $rid , 'role' );						
					 
					push @{ $list } , $role ;
				}
			}
			
			
		}
		
		
	}
	else{
		# retrieve all roles

	 	my $list = query([ $ids , [ 'id','hypothetical'] ], 
	 	"all_entities", "Role" );
		
	}
	
	 return $list , $error ;
}

sub query {
  my ($params, $entity, $name, $verbose) = @_;

  my $data = { 'params' => $params,
	       'method' => "CDMI_EntityAPI.".$entity."_".$name,
	       'version' => "1.1" };


  print STDERR Dumper $data ;

  my $response = $ua->post($cdmi_url, Content => $json->encode($data))->content;

  print STDERR Dumper $response	;	
  eval {
    $response = $json->decode($response);
  };
  if ($@) {
    print STDERR $response."\n";
  }
  if ($verbose) {
    print STDERR Dumper($response)."\n";
  }
  $response = $response->{result};

  return $response;
}

true;
