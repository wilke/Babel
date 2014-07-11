#!/kb/runtime/bin/perl

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
umask 000;

# parameters
my $awe_job_url = "";
my $task_status;
my $conf = "awe.ini";
my $help = 0;
my $options = GetOptions ("awe_job_url=s" => \$awe_job_url,
                          "task_status" => \$task_status,
                          "conf=s"    => \$conf,
                          "help"  => \$help
			 );

if($help) {
    print_usage();
    exit 0;
}

if($awe_job_url eq "") {
    print STDERR "\nERROR, missing the required field 'awe_job_url'.\n";
    print_usage();
    exit 1;
}

my $cfg = new Config::Simple($conf);

my $user;
if(exists $ENV{"KB_AUTH_USER_ID"}) {
    $user = $ENV{"KB_AUTH_USER_ID"};
} elsif(defined $cfg->param('user') && defined $cfg->param('password')) {
    $user = $cfg->param('user');
    my $encoded = encode_base64($user.':'.$cfg->param('password'));
    my $ua = LWP::UserAgent->new();
    my $get = $ua->get("http://dev.metagenomics.anl.gov/api.cgi?auth=kbgo4711$encoded");
    unless($get->is_success) {
        print STDERR "ERROR, could not authenticate user, exiting.\n\n";
        exit 1;
    }
    my $json = new JSON();
    my $res = $json->decode( $get->content );
    unless(exists $res->{token}) {
        print STDERR "ERROR, could not authenticate user, exiting.\n\n";
        exit 1;
    }
} else {
    print STDERR "ERROR, user not authenticated, exiting.\n\n";
    exit 1;
}

my $ua = LWP::UserAgent->new();
my $get = $ua->get($awe_job_url);

unless ($get->is_success) {
    print STDERR "Could not retrieve AWE job via url: $awe_job_url";
    exit 1;
}

my $json = new JSON();
my $res = $json->decode( $get->content );
my $job_state = "";

if(exists $res->{data}->{state}) {
    $job_state = $res->{data}->{state};
}

if($job_state eq "") {
    print STDERR "Job status could not be retrieved for AWE job url = $awe_job_url\n";
} else {
    print "\nJob status retrieved for AWE job url = $awe_job_url\n";
    print "Job status is: $job_state\n\n";
    if($task_status && exists $res->{data}->{tasks}) {
        foreach my $task (@{$res->{data}->{tasks}}) {
            if(exists $task->{cmd}->{description} && exists $task->{state}) {
                my $desc = $task->{cmd}->{description};
                my $state = $task->{state};
                print "Status of task '$desc': $state\n";
            }
        }
        print "\n";
    }
}

sub print_usage {

  my $helptext = qq~
NAME
    mg-check-annotation-status -- Script for checking status of metagenome in AWE

VERSION
    1

SYNOPSIS
    mg-check-annotation-status --awe_job_url <url> [ --task_status --conf <filename> --help ]

DESCRIPTION
    Script for checking status of metagenome in AWE

  Parameters
    awe_job_url - url for AWE job
    conf - configuration file (default='awe.ini')
    help - display this message

  Options
    task_status - boolean to include status of individual tasks, default is false

  Output
    JSON object that represents the status information.

EXAMPLES
    -

SEE ALSO
    -

AUTHORS
    Jared Bischof, Travis Harrison, Folker Meyer, Tobias Paczian, Andreas Wilke

~;
  print $helptext;
}
