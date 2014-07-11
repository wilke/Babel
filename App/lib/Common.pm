package Common ;

use strict;
use warnings;

use LWP::UserAgent;
use JSON;
use Data::Dumper;

# Global variables
my $ua = LWP::UserAgent->new;
$ua->agent("MyClientAW/0.1 ");



sub new {
	my ($Class , @options) = @_ ;
	my $obj = {
		id 		=> '' ,
		name 	=> '' ,
		uri  	=> '' ,
		limit 	=> 100,
		offset 	=> 0 ,
	};
	
	return bless $obj ;
}

sub data_sources {
	my ($self) = @_ ;
	
	# Read from config later
	unless($self->{data_sources}){ 
		$self->{data_sources} =  { 
			CDMI => 'https://www.kbase.us/services/cdmi_api' ,
			Shock => '',
			WorkSpaces => ''
		};
	}
	
	return $self->{data_sources} ;
}


sub user_agent {
	my ($self) = @_ ;
	unless ($self->{ua} ) {
		my $ua = LWP::UserAgent->new;
		$ua->agent("MyClientAW/0.1 ");
		$self->{ua} = $ua ;
	}
	return $self->{ua} ;
}

sub json {
	my ($self) = @_ ;
	
	unless($self->{json}){ $self->{json} = new JSON }
	
	return $self->{json} ;
}

sub get_from_cdmi {
	
}

sub query_cdmi {
  my ($self, $params, $entity, $name, $verbose) = @_;

  my $data = { 'params' => $params,
	       'method' => "CDMI_EntityAPI.".$entity."_".$name,
	       'version' => "1.1" };


  my $response = $self->user_agent->post($self->data_sources->{'CDMI'}, Content => $self->json->encode($data))->content;

  print STDERR Dumper $response	;	
  eval {
    $response = $self->json->decode($response);
  };
  if ($@) {
    print STDERR "Error:\t" . $response."\n";
  }
  if ($verbose) {
    print STDERR Dumper($response)."\n";
  }
  $response = $response->{result};

  return $response;
}

=head1 get_list( [PARAMETER] , ENTITY , NAME)
 
=over 8

=item [PARAMETER] is a list of strings

	Values for PARAMETER are fields defined for an entity or relation 
	defined in the CDMI model (kbase.us)

=item ENTITY is a string

	The value for ENTITY is 'all_entities'

=item NAME is a string 

	The value for NAME is any entity defined in the CDMI model (kbase.us)


=cut

sub get_list{
	my ($self, $params , $entity, $name, $verbose) = @_;
	
	my $response = $self->query_cdmi( [$self->offset , $self->limit , $params] , $entity, $name, $verbose) ;
	my $list     = $self->response2list;
	
	# set to new offset
	if( scalar @$response ){
		$self->offset($self->offset + $self->limit );
	}	
	
	return $list
};

sub get_object{
	my ($self, $params , $entity, $name, $verbose) = @_;
	my $response = $self->query_cdmi( $params , $entity, $name, $verbose) ;
	
	my $return = {};
	foreach my $struct ( @$response ) {
		foreach my $id (keys %$struct) {
			my $obj = $struct->{$id} ;
			$obj->{id} = $id ,
			$obj->{url} = $self->base_url . "/sequence/$id" if ($self->base_url);
			$return = $obj ;
		}
	}
	
	return $return ;
};
	

sub listStructure {
    my $list_structure = {
    	'next' => '',
		'previous' => '',
		'data' => [] ,
		'total_count' => '',
		'order' => '' ,
		'url' => '',
		'limit' => '100' ,
		'offset' => '0'
    } ;	
	
	return $list_structure
}

sub response2list{
	my ($self, $list,$resource, $options) = @_ ;	
	# walk through smart return structure	
	my $return = $self->listStructure ;
	

	
	foreach my $struct ( @$list ) {
		foreach my $id (keys %$struct) {
			my $obj = $struct->{$id} ;
			$obj->{id} = $id ,
			$obj->{url} = $self->base_url . "/$resource/$id" if ($self->base_url and $resource);
			push @{$return->{data}} , $obj ;
		}
	}
	
	
		if ($self->base_url and $resource) {
			
			if( scalar @$list ){
				$return->{limit}  = $self->limit  ;
				$return->{offset} = $self->offset ;
		
				my $noffset = $self->offset + $self->limit ;
				my %noptions = %$options ;
				$noptions{next} = $noffset ;
		
				my $opt = join "&" , (map { $_ . "=" . $noptions{$_} } keys %noptions) ;
				$return->{next}   = $self->base_url . "/$resource?$opt" ;
		
		
				my $poffset = $self->offset - $self->limit ;
				if ($poffset ge 0 ) { 
					my %poptions = %$options ;
					$poptions{prev} = $poffset;
			
					my $opt = join "&" , (map { $_ . "=" . $poptions{$_} } keys %poptions) ;
					$return->{prev}   = $self->base_url . "/$resource?$opt" ;
				}
				else{
					$return->{prev} = '' ;
				}
			}	
		}
	
	return $return
}

sub base_url {
	my ($self , $url) = @_ ;
	$self->{base_url} = $url if ($url) ;
	return $self->{base_url} || undef
}

sub limit { 
	my ($self , $var) = @_ ; 
	$self->{limit} = $var if ($var) ; 
	return $self->{limit};
};

sub offset {
	my ($self , $var) = @_ ; 
	$self->{offset} = $var if ($var) ; 
	return $self->{offset};
};
	

sub next{
	my ($self , $url) = @_ ;
	$self->{next} = $url if ($url) ;
	return $self->{next};
}

sub prev{
	my ($self , $url) = @_ ;
	$self->{prev} = $url if ($url) ;
	return $self->{prev};
}

1;