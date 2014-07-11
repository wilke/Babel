#!/kb/runtime/bin/perl
use strict vars;
use warnings;
use Test::More;


# local config

use lib "/Users/Andi/Development/kbase/communities_api/client" ;
use lib "/Users/Andi/Development/kbase/kb_seed/lib/" ;
#use lib "../client/";

use Test::More ; #tests => 378;

use CommunitiesAPIClient;
use Data::Dumper;



=pod

=head1 Testing Plan

=head2 Testing always object/instance retrieval 

=over

=item Create new object

=back

=cut




my @tests = ();
my $testCount = 0;
my $maxTestNum = 4;  # increment this each time you add a new test sub.
my $HOST='http://kbase.us/services/communities/';

# keep adding tests to this list
unless (@ARGV) {
       for (my $i=1; $i <= $maxTestNum; $i++) {
               push @tests, $i;
       }
}

else {
       # need better funtionality here
       @tests = @ARGV;
}

# do anything here that is a pre-requisiste
my ($client) = setup();




foreach my $num (@tests) {
       my $test = "test" . $num;
       &$test($client);
       $testCount++;
}

done_testing($testCount);
teardown();

# write your tests as subroutnes, add the sub name to @tests


#
#  Test - Are the methods valid?
#

sub test1 {
  my ($object) = @_;
    can_ok($object, qw[get_abundanceprofile_instance get_library_query get_library_instance get_metagenome_query get_metagenome_instance get_project_query  get_project_instance get_sample_query get_sample_instance get_sequences_md5 get_sequences_annotation ]);
    
}


# Test - Abundance Profile
sub test2 {
  my ($object) = @_;


  my $test_name = "get_abundanceprofile_instance";
  note("TEST $test_name");
  my %attributes = (
		    'generated_by'=>'S',
		    'matrix_type'=>'S',
		    'date'=>'S',
		    'data'=>'L',
		    'rows'=>'L',
		    'matrix_element_type'=>'S',
		    'format_url'=>'S',
		    'format'=>'S',
		    'columns'=>'L',
		    'id'=>'S',
		    'type'=>'S',
		    'shape'=>'L'
		   );
  my %test_value;
  my $return = undef ;
  
  eval { $return = $object->get_abundanceprofile_instance() };
  like($@, qr/Invalid argument count/, "$test_name Call with no parameters failed properly");

  undef $return;
  



  # test parameters 
  my @verbosity          = ( 'minimal' , 'verbose' , 'full' );
  my @sources_features   = ( 'M5RNA' , 'RDP' , 'Greengenes' , 'LSU' , 'SSU' , 'M5NR' , 'SwissProt' , 'GenBank' , 'IMG' , 
			     'KEGG' , 'SEED' , 'TrEMBL' , 'RefSeq' , 'PATRIC' , 'eggNOG' ) ;
  my @sources_functions  = ( 'NOG' , 'COG' , 'KO' , 'GO' , 'Subsystems' ) ;
  my @types      = ( 'feature' , 'organism' , 'function' ) ;

  foreach my $verbose (@verbosity){

    # Test organism and feature
    foreach my $source (@sources_features){   
      foreach my $type ('feature' , 'organism') {

	my $return = undef;
	my $test_value = { 'id'        => 'mgm4440026.3' ,
			   'type'      => $type ,
			   'source'    => $source ,
			   'verbosity' => $verbose
			 };

	# skip test for M5* and features
	next if ($source =~/M5/ and $type eq "feature");

	eval { $return = $object->get_abundanceprofile_instance($test_value)  };
	is($@, '', "$test_name Call with valid parameter works: " . (join "\t" , $verbose , $source , $type) );
	if ($@){
	  print STDERR "Test for get_abundance_profile_instance failed:\n";
	  print STDERR $@ , "\n";
	  print STDERR "Test values: \n" . Dumper $test_value ;

	  print STDERR "Skipping next tests!\n\n";
	  next;
	}
	is (ref($return), 'HASH', "$test_name was the return an HASH?") if ($return); 
	&test_result($return,\%attributes,$test_value) if ($return);
      }
    }
    
    # Test ontology/function
    foreach my $source (@sources_functions){
      foreach my $type ('function') {
	
	my $return = undef;
	my $test_value = { 'id'        => 'mgm4440026.3' ,
			   'type'      => $type ,
			   'source'    => $source ,
			   'verbosity' => $verbose
			 };

	eval { $return = $object->get_abundanceprofile_instance($test_value)  };
	is($@, '', "$test_name Call with valid parameter works: " . (join "\t" , $verbose , $source , $type) );
	if ($@){
	  print STDERR "Test for get_abundance_profile_instance failed:\n";
	  print STDERR $@ , "\n";
	  print STDERR "Test values: \n" . Dumper $test_value ;

	  print STDERR "Skipping next tests!\n\n";
	  next;
	}
	is (ref($return), 'HASH', "$test_name was the return an HASH?") if ($return); 
	&test_result($return,\%attributes,$test_value) if ($return);
      }
    }
  }

}

# Test Project
sub test3 {
  my ($object) = @_ ;
  
  my $test_name = "get_library_query";
  note("TEST $test_name");
  my %attributes = (
		    'version'=>'S',
		    'project'=>'S',
		    'name'=>'S',
		    'sequencesets'=>'L',
		    'metagenome'=>'S',
		    'created'=>'S',
		    'url'=>'S',
		    'id'=>'S',
		    'sample'=>'S',
		    'metadata'=>'M'
		   );
  my $return     = undef;

  # Test parameters
  my $good_params = {
		     "verbosity"=> [
				    "minimal",
				   ],
		     "order    "=> [
				    "id",
				    "name",
				   ],
		     "limit"    => [ 1 , 50 , 100 ] ,
		     "offset"   => [ 0 , 1 , 50 ] ,
		    };
  
  my $bad_params = {
		    "verbosity"=> [
				   "verbose",
				   "full",
				  ],
		    "order"=> [
			       "created",
			       "url",
			       "metagenome",
			      ],
		    "limit"=> [ -50 ] ,
		    "offset"=> [ 0 , -10 ] ,
		   };
  
  
  eval { $return = $object->get_library_query()  };
  like($@, qr/Invalid argument count/, "$test_name Call with no parameters failed properly");
  
  # Test should work
  foreach my $verbose ( @{$good_params->{verbosity} }) {
    foreach my $order ( @{$good_params->{order} }) {
      foreach my $limit ( @{$good_params->{limit} }) {
	foreach my $offset ( @{$good_params->{offset} }) {
	  
	  my$return = undef;
	  my $test_value = { "verbosity" => $verbose ,
			     "limit"     => $limit ,
			     "offset"    => $offset ,
			     "order"     => $order ,
			   };
	  eval { $return = $object->get_library_query($test_value)  };
	  is($@, '', "$test_name Call with valid parameters (verbosity=$verbose , limit=$limit , offset=$offset , order=$order) works ");
	  is (ref($return), 'HASH', "$test_name was the return a HASH?") if ($return); 
	  &test_result($return,\%attributes,$test_value)  if ($return);
	}
      }
    }
  }
       
  # Test should fail
  foreach my $verbose ( @{$bad_params->{verbosity} }) {
    foreach my $order ( @{$bad_params->{order} }) {
      foreach my $limit ( @{$bad_params->{limit} }) {
	foreach my $offset ( @{$bad_params->{offset} }) {
	  
	  my $return = undef;
	  my $test_value = { "verbosity" => $verbose ,
			     "limit"     => $limit ,
			     "offset"    => $offset ,
			     "order"     => $order ,
			   };
	  
	  eval { $return = $object->get_library_query($test_value)  };
	  is($@, '', "$test_name Call with invalid parameter (verbosity=$verbose , limit=$limit , offset=$offset , order=$order) works ");
	  if ($@) {
	    diag ( "Test failed:\n " . $@ ) ;
	    diag ( Dumper $return ) ;
	    next ;
	    
	  }
	  is (ref($return), 'HASH', "$test_name was the return a HASH?") if ($return);
	  ok($return->{ERROR} , "$test_name returned error message");
	  ok( !@{$return->{data}} , "$test_name no instances returned for invalid parameters?") if ($return); 
	  if ( @{$return->{data}} ){
	    print STDERR  Dumper $return ;
	    exit;
	    
	  }
	  &test_result($return,\%attributes,$test_value)  if (@{$return->{data}});
	}
      }
    }
  }
}


sub test4 {
  my ($client) = @_ ;

  my $test_name = "get_library_instance";
  note("TEST $test_name");
  my %attributes = (
		    'version'=>'S',
		    'project'=>'S',
		    'name'=>'S',
		    'sequencesets'=>'L',
		    'metagenome'=>'S',
		    'created'=>'S',
		    'url'=>'S',
		    'id'=>'S',
		    'sample'=>'S',
		    'metadata'=>'M'
		   );
  
  my $good_params = {
		     "verbosity"=> [
				    "minimal",
				    "verbose",
				    "full",
				   ],
		    };
  
  my $bad_params = {
		    "verbosity"=> [
				   "all",
				   "done",
				  ],
		    "order"=> [
			       "created",
			       "url",
			       "metagenome",
			      ],
		   };
 
  my $return = undef ;
  eval { $return = $client->get_library_instance()  };
  like($@, qr/Invalid argument count/, "$test_name Call with no parameters failed properly");
  
  foreach my $verbose ( @{$good_params->{verbosity} }) {
    
    my $test_value = { id        => 'mgl5589' ,
		       verbosity => $verbose ,
		     };
    my $return = undef ;

    eval { $return = $client->get_library_instance($test_value)  };
    is($@, '', "$test_name Call with valid parameter works ");
    is (ref($return), 'HASH', "$test_name was the return an HASH?") if ($return); 
    &test_result($return,\%attributes,$test_value)  if ($return);
  }
      
}

























# needed to set up the tests, should be called before any tests are run
sub setup {
my $client = CommunitiesAPIClient->new($HOST); # create a new object with the URL

# Test 1 - Is there an object
ok( defined $client, "Did an object get defined for Communities" );               
#  Test 2 - Is the object in the right class?
isa_ok( $client, 'CommunitiesAPIClient', "Is it in the right class (Communities)" );  

return ($client) ;
}

# this should be called after all tests are done to clean up the filesystem, etc.
sub teardown {
}










#----------------------------------------------------------------------------
#
#  Test the returned results
#	1.	Test for an error
#	2.	Test that the returned attribute is expected
#	3.	Test that the returned attribute is the right type
#	4.	If verbosity is 'full' make sure that all of them returned
#

sub test_result
{
	my ($return,$attribute,$test) = @_;
	my $data;

	my $result = $return;
#		print Dumper($result);  

	if (ref($result) eq 'HASH' && exists ($result->{'rows'}) )
	{	#print "DEBUG: Abundanceprofile \n";
		$data->[0] = $result;
	}
	elsif (ref($result) eq 'HASH' && exists ($result->{'data'}))
	{   #print "DEBUG: Sample/Library/Metagenome/Project query \n";
		$data->[0] = $result->{data};
	}  
	elsif (ref($result) eq 'HASH')
	{   #print "DEBUG: Sample/Library/Metagenome/Project instance \n";
		$data->[0] = $result;
	} 
	elsif (ref($result) eq 'ARRAY')
	{	#print "DEBUG: Sample/Library/Metagenome/Project/Sequences_MD5 instance  \n";
#		print Dumper($result);  
		$data = $return;
		die "never should reached this point" ;
	}
	else
	{	print "DEBUG: UNKNOWN  \n";
		$data = $return;
	}

#	my $result = $return->{'result'};
#		print Dumper($data);  
#return;

#	if (ref($result) eq 'HASH' && exists ($return->{'result'}->{'rows'}) )
#	{	#print "DEBUG: Abundanceprofile \n";
#		$data->[0] = $return->{'result'};
#	}
#	elsif (ref($result) eq 'HASH')
#	{   #print "DEBUG: Sample/Library/Metagenome/Project query \n";
#		$data = $return->{'result'}->{'data'};
#	}  
#	elsif (ref($result) eq 'ARRAY')
#	{	#print "DEBUG: Sample/Library/Metagenome/Project/Sequences_MD5 instance  \n";
#		$data = $return->{'result'};
#	}
#	else
#	{	print "DEBUG: UNKNOWN  \n";
#		$data = $return;
#	}

	my %attributes = %$attribute;
	my %test_value = %$test;
	my %found_att;
	my $count = 0;

	if (ref($data) eq 'ARRAY')
	{
		foreach my $key3 (@$data)
		{
			if (ref($key3) eq 'HASH')
			{
				foreach my $key4 (keys(%$key3))
				{
					#print "\t\t\tKEY=$key4 VALUE=$key3->{$key4} \n";
					#print Dumper \%attributes ;
					ok(exists $attributes{$key4}, "Is Attribute $key4 valid?");
					if (exists $attributes{$key4} && $attributes{$key4} eq 'M'  )
					{
						is (ref($key3->{$key4}),'HASH', "Is Attribute $key4 a hash?");
					}
					elsif (exists $attributes{$key4} && $attributes{$key4} eq 'L'  )
					{
						is (ref($key3->{$key4}),'ARRAY', "Is Attribute $key4 an array?");
					}
					else
					{
						is (ref($key3->{$key4}),'', "Is Attribute $key4 a scalar?");
					}
					$found_att{$key4} = 'Y';
				}
			}
			$count++;
		}
	}

	if (exists $test_value{'verbosity'} && $test_value{'verbosity'} eq 'full')
	{
		note"Verbosity=FULL, Were all Attributes returned?";
		foreach my $key(keys(%attributes))
		{
			ok(exists $found_att{$key}, "Was attribute $key found?");
		}
	}

	return if (ref($result) eq 'ARRAY');

	is ($result->{'limit'},$test_value{"limit"}, "Is the returned limit the same as the requested limit?") if (exists $test_value{"limit"});
	is ($count, $test_value{"limit"}, "Is the returned number of records the same as the requested limit?") if (exists $test_value{"limit"});
	is ($result->{'offset'},$test_value{"offset"}, "Is the returned offset the same as the requested offset?") if (exists $test_value{"offset"});
	is ($result->{'order'},$test_value{"order"}, "Is the returned order the same as the requested order?") if (exists $test_value{"order"});

#	is ($return->{'result'}->{'limit'},$test_value{"limit"}, "Is the returned limit the same as the requested limit?") if (exists $test_value{"limit"});
#	is ($count, $test_value{"limit"}, "Is the returned number of records the same as the requested limit?") if (exists $test_value{"limit"});
#	is ($return->{'result'}->{'offset'},$test_value{"offset"}, "Is the returned offset the same as the requested offset?") if (exists $test_value{"offset"});
#	is ($return->{'result'}->{'order'},$test_value{"order"}, "Is the returned order the same as the requested order?") if (exists $test_value{"order"});


}

sub test_error
{
	my ($return,$test) = @_;
	my %test_value = %$test;

	if (exists $return->{'error'})
	{
		print "\tRETURN ERROR\n";
		foreach my $key (keys(%{$return->{'error'}->{'data'}}))
		{
			print "\t$return->{'error'}->{'data'}->{$key} \n";
		}
 		print "\tRETURN PARAMETERS: ";
		foreach my $key (keys(%test_value))
		{
			print "$key=$test_value{$key}  ";
		}
		print "\n";
		print "\tCODE=".$return->{'error'}->{'code'}."\n";
		print "\tMESSAGE=".$return->{'error'}->{'message'}."\n";
#		print Dumper($return);  
		ok( ! exists ($return->{'error'}->{'data'}),"Is the HASH free of errors");
		return;
	}
	else
	{
		ok( ! exists ($return->{'error'}->{'data'}),"Is the HASH free of errors");
	}

}



