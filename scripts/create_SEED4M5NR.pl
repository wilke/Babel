
#Script for checking status of metagenome in AWE
#Command name: check_metagenome.pl
#Parameters:
#     -awe_job_url=<url for AWE job, required>
#     -task_status <option variable to include status of individual tasks>
#     -conf=<configuration file (default='awe.ini')>

use strict;
use warnings;
no warnings('once');

use JSON;
use Config::Simple;
use Getopt::Long;
use LWP::UserAgent;
use MIME::Base64;
use Data::Dumper;
umask 000;

# parameters
my $cdmi_url    = "https://www.kbase.us/services/cdmi_api";
my $api_url     = "http://0.0.0.0:3000";
my $conf        = "Babel.ini";
my $client_name = "Babel CLient 0.1";
my $help        = 0;
my $limit       = 100;
my $verbose     = 0 ;
my $dir         = ".";

my $options = GetOptions(
    "api"     => \$api_url,
    "conf=s"  => \$conf,
    "help"    => \$help,
    "verbose" => \$verbose,
    "dir=s"   => \$dir ,
);

if ($help) {
    print_usage();
    exit 0;
}

my $json = new JSON();
my $cfg  = {};
$cfg = new Config::Simple($conf) if ( -f $conf );
my $url = $api_url || $cfg->param('api_url');

my $ua = LWP::UserAgent->new($client_name);


# open output files
if (-d $dir){
	open(ID2SEQ , ">$dir/id2func2org2seq") or die "Can't open $dir/id2func2org2seq for writing!\n";
	open(SS 	, ">$dir/subsystem2role") or die "Can't open $dir/subsystem2role for writing!\n";
	open(SS2SEQ , ">$dir/subsystem2role2seq") or die "Can't open $dir/subsystem2role2seq for writing!\n";
}
else{
	print STDERR "No such file or directory $dir\n";
	exit ;
}

# get genomes and sequences

# url for genome list
my $genome_list_url = "$url/genome?limit=$limit";

while ($genome_list_url) {

    my $get = $ua->get($genome_list_url);

    # check response status
    unless ( $get->is_success ) {
        print STDERR join "\t" , "ERROR:" , $get->code , $get->status_line ;
        exit 1;
    }

    my $res = $json->decode( $get->content );

    $genome_list_url = $res->{next};
	
    foreach my $genome ( @{ $res->{data} } ) {

        # url for all genome features
        my $genome_feature_url = $genome->{url} . "/feature";

        while ($genome_feature_url) {

	    print STDERR "URL:\t$genome_feature_url\n";
            my $get = $ua->get($genome_feature_url);

            # check response status
            unless ( $get->is_success ) {
                print STDERR "ERROR\n";
                exit 1;
            }

            my $res = $json->decode( $get->content );
            $genome_feature_url = $res->{next};


			print STDERR "Features: " . scalar @{ $res->{data}) , "\n";


            foreach my $feature ( @{ $res->{data} } ) {
				
				if ( $feature->{feature_type} eq "CDS" ){
					print join( "\t", $feature->{id},  ($feature->{function} || $feature->{role} || '') , 
														$genome->{scientific_name} , $feature->{sequence}->{sequence} ) , "\n"
					                  if ( $verbose );
				
					print ID2SEQ join( "\t", $feature->{id},  ($feature->{function} || $feature->{role} || '') , $genome->{scientific_name} , $feature->{sequence}->{sequence} ), "\n"
					  
									  
				}

			
            }
        }
    }
}

sub print_usage { }

