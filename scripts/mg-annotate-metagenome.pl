#!/kb/runtime/bin/perl

use strict;
use warnings;
no warnings('once');

use Config::Simple;
use JSON;
use File::Slurp;
use Getopt::Long;
use LWP::UserAgent;
use MIME::Base64;
use Data::Dumper;
use Pod::Usage;
use String::Random qw(random_regex random_string);

umask 000;

my $CONFIG = '/kb/deployment/deployment.cfg';
my $OAUTH_URL = 'https://nexus.api.globusonline.org/goauth/token?grant_type=client_credentials';
my $WORKFLOW_URL = 'https://raw.github.com/MG-RAST/pipeline/master/conf/mgrast-prod.awe.template';

=head1 NAME

mg-annotate-metagenome -- submit a metagenome to be annotated by the microbial communities pipeline

=head1 VERSION

1

=head1 SYNOPSIS

mg-annotate-metagenome [-h] [-b bowtie] [-d dereplicate] [-m metadata_file_id] [-p KB_password] [-u KB_user] -f sequence_file_id -n metagenome_name

=head1 DESCRIPTION

Submit a metagenome to be annotated by the microbial communities pipeline.  If you are working in IRIS and are authenticated, you do not need to enter your KB_user and KB_password.

NOTE: Currently all submissions are created as public workflows with publically viewable data objects.  We're currently working to provide an authenticated workflow for the submission of private datasets and to provide a way for annotations to be loaded into MG-RAST.

Parameters:

=over 8

=item -f B<sequence_file_id>

sequence/read file ID in datastore

=item -n B<metagenome_name>

metagenome/file name for sequence file in datastore, must match any metagenome name in metadata file

=back

Options:

=over 8

=item -h

display this help message

=item -b B<bowtie>

switch to declare whether bowtie should be run to screen for human sequences (1 or 0, default 1)

=item -d B<dereplicate>

switch to declare whether dereplication should be run (1 or 0, default 1)

=item -m B<metadata_file_id>

metadata file ID in datastore

=item -p B<KB_password>

KBase password to authenticate against the API, requires a username to be set as well

=item -u B<KB_user>

KBase username to authenticate against the API, requires a password to be set as well

=back

Output:

KBase ID for your metagenome annotation.

=head1 EXAMPLES

-

=head1 SEE ALSO

-

=head1 AUTHORS

Jared Bischof, Travis Harrison, Folker Meyer, Tobias Paczian, Andreas Wilke

=cut

# vars hash is used to store anything that will be used to fill in workflow template.
# NOTE: some of the variables in the vars hash are superfluous and not used to fill
#       in the template.

my %vars = ();

# variables in config file (defaults are hard-coded here)
$vars{aweurl} = "http://localhost:7080";
$vars{shockurl} = "http://localhost:7078";
$vars{mem_host} = "10.0.4.96:11211";

# hard-coded variables
$vars{aa_pid} = 90;
$vars{ach_annotation_ver} = 1;
$vars{clientgroups} = "awe-mgr";
$vars{fgs_type} = "454";
$vars{filter_options} = "filter_options='filter_ambig:max_ambig=5:filter_ln'";
$vars{md5rna_clust} = "md5nr.clust";
$vars{prefix_length} = 50;
$vars{project} = "mgrast-pipeline";
$vars{rna_pid} = 97;
$vars{screen_indexes}='h_sapiens_asm';
$vars{totalwork} = 16;

# command line parameters
$vars{shocknode} = "";
$vars{jobname} = "";

# command line options
$vars{bowtie} = 1;
$vars{dereplicate} = 1;
$vars{metadata_file_id} = "";
my $password = "";
$vars{user} = "";
my $help = 0;
my $options = GetOptions ("f=s"  => \$vars{shocknode},
                          "n=s"  => \$vars{jobname},
			  "b=s"  => \$vars{bowtie},
			  "d=s"  => \$vars{dereplicate},
			  "m=s"  => \$vars{metadata_file_id},
			  "p=s"  => \$password,
			  "u=s"  => \$vars{user},
                          "help" => \$help
			 );

# creating aliases for these variables because their names in this script are different than their names
#  in the MG-RAST default AWE workflow template.
$vars{metagenome_name} = $vars{jobname};
$vars{sequence_file_id} = $vars{shocknode};

if ($help) {
    pod2usage( { -message => "\nDOCUMENTATION:\n",
                 -exitval => 0,
                 -output  => \*STDOUT,
                 -verbose => 2,
                 -noperldoc => 1,
               } );
}

# error-handling inputs...
my %missing;
foreach my $i ('metagenome_name', 'sequence_file_id') {
    if($vars{$i} eq "") {
        $missing{$i} = 1;
    }
}

if(keys %missing > 0) {
    print STDERR "\nERROR, the following parameters are missing from your command:\n";
    foreach my $i (keys %missing) {
        print STDERR "  $i\n";
    }
    print "\nFor more detailed documentation run '$0 -h'\n\n";
    exit 1;
}

my $cfg = new Config::Simple($CONFIG);
my $p_cfg = $cfg->param(-block=>'communities_pipeline');
foreach my $i ('aweurl',
               'shockurl',
               'mem_host') {
    if(defined $p_cfg->{$i}) {
        $vars{$i} = $p_cfg->{$i};
    } else {
        $missing{$i} = 1;
    }
}

if(keys %missing > 0) {
    print STDERR "\nERROR, the following parameters are missing from your config file ($CONFIG):\n";
    foreach my $i (keys %missing) {
        print STDERR "  $i\n";
    }
    print "\nFor more detailed documentation run '$0 -h'\n\n";
    exit 1;
}

my $token = "";
if(exists $ENV{"KB_AUTH_TOKEN"}) {
    $token = $ENV{"KB_AUTH_TOKEN"};
} elsif($vars{user} ne "" && $password ne "") {
    my $encoded = encode_base64($vars{user}.':'.$password);
    my $json = new JSON();
    my $pre = `curl -s -H "Authorization: Basic $encoded" -X POST "https://nexus.api.globusonline.org/goauth/token?grant_type=client_credentials"`;
    eval {
        my $res = $json->decode($pre);
        unless(exists $res->{access_token}) {
            print STDERR "ERROR, could not authenticate user, exiting.\n\n";
            exit 1;
        }
        $token = $res->{access_token};
    };
    if ($@) {
        print STDERR "could not reach auth server: $@\n";
        exit 1;
    }
} else {
    print STDERR "ERROR, user not authenticated, exiting.\n\n";
    exit 1;
}

###############################################################################
#
# Done handling inputs, now to check the Shock nodes for valid data and
#  validate the inputs.
#
###############################################################################

my $md_filename = "";
# Checking if files are in Shock and have a non-zero size.
print "\nINFO, validating file in Shock nodes.\n";
foreach my $var_name ('metadata_file_id', 'sequence_file_id') {
    if($var_name eq 'sequence_file_id' || ($var_name eq 'metadata_file_id' && $vars{metadata_file_id} ne "")) {
        my $snode_url = "http://".$vars{shockurl}.'/node/'.$vars{$var_name};
        my $ua = LWP::UserAgent->new();
        my $get = $ua->get($snode_url);
        unless ($get->is_success) {
            print STDERR "ERROR, could not retrieve Shock node for '$var_name' via url: $snode_url\n";
            exit 1;
        }

        my $json = new JSON();
        my $res = $json->decode( $get->content );
        my $size = $res->{data}->{file}->{size};
        if($size =~ /^\d+$/ && $size > 0) {
            print "INFO, Shock node for '$var_name' has a size of $size bytes.\n";
        } else {
            print STDERR "ERROR, Shock node for '$var_name' does not exist or is 0 bytes in size.\n";
            exit 1;
        }

        if($var_name eq 'metadata_file_id') {
            $md_filename = $res->{data}->{file}->{name};
        } elsif($var_name eq 'sequence_file_id') {
            $vars{inputfile} = $res->{data}->{file}->{name};
        }
    }
}

# Downloading metadata file to validate it if file metadata was submitted.
if($vars{metadata_file_id} ne "") {
    print "INFO, downloading metadata file for validation.\n";
    my $ua = LWP::UserAgent->new();
    my $get = $ua->get("http://".$vars{shockurl}.'/node/'.$vars{'metadata_file_id'}."?download", ":content_file" => $md_filename);

    print "INFO, validating metdata file.\n";
    my $post = $ua->post("http://dev.metagenomics.anl.gov/api.cgi/metadata/validate",
                         Content_Type => 'form-data',
                         Content      => [ upload => [$md_filename] ]
                        );

    my $json = new JSON();
    my $res = $json->decode( $post->content );
    if($res->{is_valid} == 0) {
        print STDERR "ERROR, your metadata file did not validate.\n";
        print STDERR $res->{message}."\n";
        print STDERR "Exiting without job submission.\n\n";
        exit 1;
    } else {
        print "INFO, metadata validated.\n";
    }

    print "INFO, checking if metagenome_name exists in metadata file as file_name or metagenome_name.\n";
    my $job_found = 0;
    foreach my $sample (@{$res->{metadata}->{samples}}) {
        foreach my $library (@{$sample->{libraries}}) {
            if((exists $library->{data}->{metagenome_name}->{value} && $vars{metagenome_name} eq $library->{data}->{metagenome_name}->{value}) ||
               (exists $library->{data}->{file_name}->{value} && $vars{inputfile} eq $library->{data}->{file_name}->{value})) {
               $job_found = 1;
            }
        }
    }

    if($job_found == 0) {
        print STDERR "ERROR, metagenome_name '".$vars{metagenome_name}."' not found in any 'metagenome_name' field in metadata.\n";
        print STDERR "       and input file name '".$vars{inputfile}."' not found in any 'file_name' field in metadata.\n";
        print STDERR "Exiting without job submission.\n\n";
        exit 1;
    } else {
        print "INFO, job found in metadata.\n";
    }
}

###############################################################################
#
#  Now, download the workflow, get a KBase ID, fill-in the workflow,
#    and submit the workflow to AWE.
#
###############################################################################

# Download the workflow
my $ua = LWP::UserAgent->new();
my $tmp_filename = "/tmp/mg_annotate_metagenome.".random_regex('\w\w\w\w\w\w\w\w\w\w').".tmp";
my $get = $ua->get($WORKFLOW_URL);
if ($get->is_success) {
    open TMP, ">$tmp_filename" || die "Cannot open tmp file: $tmp_filename\n";
    print TMP $get->content;
    close TMP;
} else {
    print STDERR "ERROR, could not retrieve workflow template.\n";
    exit 1;
}

# Allocate a KBase ID for this metagenome
$ua = LWP::UserAgent->new();
my $form = '{ "method": "IDServerAPI.allocate_id_range",
              "version": "1.1",
              "params": ["kb|mg",1] }';
my $post = $ua->post("http://www.kbase.us/services/idserver", Content => $form);
my $json = new JSON();
my $res = $json->decode( $post->content );
if(exists $res->{error} || !exists $res->{result}->[0]) {
    print STDERR "ERROR, could not retrieve KBase metagenome ID, exiting.\n";
    exit 1;
}
$vars{xref} = "kb|mg.".$res->{result}->[0];

print "INFO, configuring AWE pipeline with the specified parameters.\n";
# Replace # vars in template
my $text = read_file($tmp_filename);
foreach my $key (keys %vars) {
    $text =~ s/#$key/$vars{$key}/g;
}
system("rm -f $tmp_filename");

# Create an output file with unused filename
my $workflow_outfile = "submitted_workflow";
my $workflow_errfile = "submitted_workflow";
my $i=1;
for($i=1; $i<=100; ++$i) {
    unless(-e $workflow_outfile.".$i.out" || -e $workflow_errfile.".$i.err") {
        last;
    }
}
$workflow_outfile .= ".$i.out";
$workflow_errfile .= ".$i.err";

if(-e $workflow_outfile || -e $workflow_errfile) {
    print STDERR "ERROR, one of the output files could not be created.  Attempting to write to files: '$workflow_outfile' and possibly '$workflow_errfile' if there is an error in submission, but one of these files already exists.\n";
    print STDERR "Exiting without job submission.\n\n";
    exit 1;
}

print "INFO, writing file with configured workflow to: $workflow_outfile\n";
open OUT, ">$workflow_outfile" || die "Cannot open file $workflow_outfile for writing.\n";
print OUT $text;
close OUT;

print "INFO, submitting pipeline ($workflow_outfile) to AWE.\n";
$ua = LWP::UserAgent->new();
$post = $ua->post("http://".$vars{aweurl}."/job",
                  Content_Type => 'form-data',
                  Content      => [ upload => [$workflow_outfile] ]
                 );

$res = $json->decode( $post->content );
my $state = $res->{data}->{state};

if($state ne "submitted") {
    open OUT, ">$workflow_errfile" || die "Could not open $workflow_errfile for writing.";
    print OUT Dumper($res);
    close OUT; 

    print STDERR "ERROR, AWE job submission was not successful, please see '$workflow_errfile' for more info.\n\n";
    exit 1;
}

my $awe_id = $res->{data}->{id};
my $job_id = $res->{data}->{jid};
print "INFO, AWE submission successful!\n";
print "INFO, AWE id = $awe_id\n";
print "INFO, job id = $job_id\n";
my $full_awe_url = "http://".$vars{aweurl}."/job/$awe_id";
print "INFO, AWE url = $full_awe_url\n";

$ua = LWP::UserAgent->new();
my $kbase_mg_id = $vars{xref};
$kbase_mg_id =~ s/^.*\.(\d+)$/$1/;
$form = '{ "method": "IDServerAPI.register_allocated_ids",
           "version": "1.1",
           "params": ["kb|mg","AWE",{"'.$full_awe_url.'":'.$kbase_mg_id.'}] }';
$post = $ua->post("http://www.kbase.us/services/idserver", Content => $form);
$res = $json->decode( $post->content );
if(exists $res->{error}) {
    print STDERR "ERROR, could not register AWE URL with KBase metagenome ID, but job was submitted to AWE.\n";
    exit 1;
}

print "Your KBase metagenome ID is: $vars{xref}\n";
print "Done.\n\n";
