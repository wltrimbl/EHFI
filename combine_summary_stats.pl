#!/usr/bin/env perl

use warnings;
use Getopt::Long;
use Cwd;
use Cwd 'abs_path';
use File::Basename;
use Statistics::Descriptive;



my($mode, $ouput_file, $within_pattern, $between_pattern, $within_file, $between_file, $help, $verbose, $debug);

my $current_dir = getcwd()."/";
$output_file = "Within_Between.P_VALUE_SUMMARY";
$mode = "exact";

if($debug){print STDOUT "made it here"."\n";}

# path of this script
my $DIR=dirname(abs_path($0));  # directory of the current script, used to find other scripts + datafiles


# check input args and display usage if not suitable
if ( (@ARGV > 0) && ($ARGV[0] =~ /-h/) ) { &usage(); }

unless ( @ARGV > 0 || $within_pattern || $between_pattern  ) { &usage(); }

if ( ! GetOptions (
		   "m|file_search_mode=s" => \$mode,
		   "o|output_file=s"      => \$output_file,
		   "w|within_pattern=s"   => \$within_pattern,
		   "b|between_pattern=s"  => \$between_pattern,
		   "h|help!"              => \$help, 
		   "v|verbose!"           => \$verbose,
		   "d|debug!"             => \$debug
		  )
   ) { &usage(); }

##################################################
##################################################
###################### MAIN ######################
##################################################
##################################################

if($debug){print STDOUT "mode: ".$mode."\n\n";}

if($mode eq "pattern"){
  my $within_search = $current_dir.qx(ls $within_pattern*/*SUMMARY);
  chomp $within_search;
  $within_file = $within_search;
  
  my $between_search = $current_dir.qx(ls $between_pattern*/*SUMMARY);
  chomp $between_search;
  $between_file = $between_search;
  
  #if($debug){print STDERR "within_file:"."\n"."###".$within_file."###\n";}
  #if($debug){print STDERR "between_file:"."\n"."###".$between_file."###\n";}
}else{
  $within_file = $within_pattern;
  $between_file = $between_pattern;
}


open(OUTPUT_FILE, ">", $output_file) or die "Can't open OUTPUT_FILE $output_file";
open(WITHIN_FILE, "<", $within_file) or die "Can't open WITHIN_FILE $within_file";
open(BETWEEN_FILE, "<", $between_file) or die "Can't open BETWEEN_FILE $between_file";

# Go through the Within file and pull out the within group stats
print OUTPUT_FILE "##### Within group statistics"."\n";

my @all_og_dist;
my @all_og_dist_stdev;
my @all_scaled_dist;
my @all_p;
my @all_perm;

my @within_og_dist;
my @within_og_dist_stdev;
my @within_scaled_dist;
my @within_p;
my @within_perm;

my @between_og_dist;
my @between_og_dist_stdev;
my @between_scaled_dist;
my @between_p;
my @between_perm;

while ( my $within_line = <WITHIN_FILE> )  {
  
  unless ( $within_line =~ m/^# Mean_p_value/ || $within_line =~ m/^# Stdev_p_value/ ){

    chomp $within_line;
    
    if ( $within_line =~ m/^#/ ) { 
      print OUTPUT_FILE $within_line."\n";
    }elsif ( $within_line =~ m/^->m/ ){
      print OUTPUT_FILE $within_line."\n";
      if($debug){print STDOUT "within_line: ".$within_line."\n"}
      
      my @within_array = split("\t", $within_line);
      
      push (@within_og_dist, $within_array[1]);
      push (@all_og_dist, $within_array[1]);
      
      push (@within_og_dist_stdev, $within_array[2]);
      push (@all_og_dist_stdev, $within_array[2]);
      
      push (@within_scaled_dist, $within_array[3]);
      push (@all_scaled_dist, $within_array[3]);
      
      push (@within_p, $within_array[4]);
      push (@all_p, $within_array[4]);
      
      push (@within_perm, $within_array[5]);
      push (@all_perm, $within_array[5]);
      
    }else{
    }
    
  }
  
}

my $stat_1 = Statistics::Descriptive::Full->new();
$stat_1->add_data(@within_og_dist);
my $w_avg_og_dist_avg = $stat_1->mean();#my $avg_og_dist_avg = sprintf("%.4f", $stat_1->mean());
if ($debug){ print STDOUT "avg_og_dist_avg: ".$avg_og_dist_avg."\n"; }
if ($debug){ print STDOUT "avg_og_dist_avg: ".sprintf("%.4f", $avg_og_dist_avg)."\n"; }

my $stat_2 = Statistics::Descriptive::Full->new();
$stat_2->add_data(@within_og_dist_stdev);
my $w_avg_og_dist_stdev = $stat_2->mean();

my $stat_3 = Statistics::Descriptive::Full->new();
$stat_3->add_data(@within_scaled_dist);
my $w_avg_scaled_dist = $stat_3->mean();

my $stat_4 = Statistics::Descriptive::Full->new();
$stat_4->add_data(@within_p);
my $w_avg_p = $stat_4->mean();

my $stat_5 = Statistics::Descriptive::Full->new();
$stat_5->add_data(@within_perm);
my $w_avg_num_perm = $stat_5->mean();

print OUTPUT_FILE (
		   "# Within group summary (average):"."\t".
		   sprintf("%.4f", $w_avg_og_dist_avg)."\t".
		   sprintf("%.4f", $w_avg_og_dist_stdev)."\t".
		   sprintf("%.4f", $w_avg_scaled_dist)."\t".
		   sprintf("%.4f", $w_avg_p)."\t".
		   sprintf("%.4f", $w_avg_num_perm)."\n".
		   "#################################################################################"."\n"
		  );


print OUTPUT_FILE "##### Between group summary stats"."\n";

# Go through the Between file and pull out the between group stats
while ( my $between_line = <BETWEEN_FILE> )  {

  unless ( $between_line =~ m/^# Mean_p_value/ || $between_line =~ m/^# Stdev_p_value/ ){
    
    chomp $between_line;
    
    if ( $between_line =~ m/^#/ ) { 
      print OUTPUT_FILE $between_line."\n";
      
    }elsif ( $between_line =~ m/^->>m/ ){
      print OUTPUT_FILE $between_line."\n";
      if($debug){print STDOUT "between_line: ".$between_line."\n"}
      
      my @between_array = split("\t", $between_line);
      
      push (@between_og_dist, $between_array[1]);
      push (@all_og_dist, $between_array[1]);
      
      push (@between_og_dist_stdev, $between_array[2]);
      push (@all_og_dist_stdev, $between_array[2]);
      
      push (@between_scaled_dist, $between_array[3]);
      push (@all_scaled_dist, $between_array[3]);
      
      push (@between_p, $between_array[4]);
      push (@all_p, $between_array[4]);
      
      push (@between_perm, $between_array[5]);
      push (@all_perm, $between_array[5]);
      
    }else{
    }
    
  }
  
}
  
my $stat_6 = Statistics::Descriptive::Full->new();
$stat_6->add_data(@between_og_dist);
my $b_avg_og_dist_avg = sprintf("%.4f", $stat_6->mean());

my $stat_7 = Statistics::Descriptive::Full->new();
$stat_7->add_data(@between_og_dist_stdev);
my $b_avg_og_dist_stdev = sprintf("%.4f", $stat_7->mean());

my $stat_8 = Statistics::Descriptive::Full->new();
$stat_8->add_data(@between_scaled_dist);
my $b_avg_scaled_dist = sprintf("%.4f", $stat_8->mean());

my $stat_9 = Statistics::Descriptive::Full->new();
$stat_9->add_data(@between_p);
my $b_avg_p = sprintf("%.4f", $stat_9->mean());

my $stat_10 = Statistics::Descriptive::Full->new();
$stat_10->add_data(@between_perm);
my $b_avg_num_perm = sprintf("%.4f", $stat_10->mean());

print OUTPUT_FILE (
		   "# Between group summary (average):"."\t".
		   sprintf("%.4f", $b_avg_og_dist_avg)."\t".
		   sprintf("%.4f", $b_avg_og_dist_stdev)."\t".
		   sprintf("%.4f", $b_avg_scaled_dist)."\t".
		   sprintf("%.4f", $b_avg_p)."\t".
		   sprintf("%.4f", $b_avg_num_perm)."\n".
		   "#################################################################################"."\n"
		  );

my $stat_11 = Statistics::Descriptive::Full->new();
$stat_11->add_data(@all_og_dist);
my $a_avg_og_dist_avg = sprintf("%.4f", $stat_11->mean());

my $stat_12 = Statistics::Descriptive::Full->new();
$stat_12->add_data(@all_og_dist_stdev);
my $a_avg_og_dist_stdev = sprintf("%.4f", $stat_12->mean());

my $stat_13 = Statistics::Descriptive::Full->new();
$stat_13->add_data(@all_scaled_dist);
my $a_avg_scaled_dist = sprintf("%.4f", $stat_13->mean());

my $stat_14 = Statistics::Descriptive::Full->new();
$stat_14->add_data(@all_p);
my $a_avg_p = sprintf("%.4f", $stat_14->mean());

my $stat_15 = Statistics::Descriptive::Full->new();
$stat_15->add_data(@all_perm);
my $a_avg_num_perm = sprintf("%.4f", $stat_15->mean());

print OUTPUT_FILE (
		   "# All (Within and Between) group summary (average):"."\t".
		   sprintf("%.4f", $a_avg_og_dist_avg)."\t".
		   sprintf("%.4f", $a_avg_og_dist_stdev)."\t".
		   sprintf("%.4f", $a_avg_scaled_dist)."\t".
		   sprintf("%.4f", $a_avg_p)."\t".
		   sprintf("%.4f", $a_avg_num_perm)."\n".
		   "#################################################################################"."\n"
		  );


##################################################
##################################################
###################### SUBS ######################
##################################################
##################################################



sub usage {
  my ($err) = @_;
  my $script_call = join('\t', @_);
  my $num_args = scalar @_;
  print STDOUT ($err ? "ERROR: $err" : '') . qq(
script:               $0

DESCRIPTION:
Script to combine within group *.P_VALUE_SUMMARY of one analysis with
between group *.P_VALUE_SUMMARY of another
   
USAGE: combine_summary_stats.pl [-m file_search_mode][-w within_file] [-b between_file] [-o output_file] -h -v -d
 
    -m|file_search_mode   (string) default = $mode
                                   file search mode, can be "exact" to match exact file patch or 
                                   "prefix" to search using file prefix for path and file
          
    -w|within_pattern     (string) NO DEFAULT
                                   if search mode is exact, path and name of *.P_VALUE_SUMMARY from which within group stats will be pulled
                                   if search is "prefix", uses pattern to find path and file of *.P_VALUE_SUMMARY 

    -b|between_pattern    (string) NO DEFAULT
                                   if search mode is exact, path and name of *.P_VALUE_SUMMARY from which within group stats will be pulled
                                   if search is "prefix", uses pattern to find path and file of *.P_VALUE_SUMMARY

    -o|output_file        (string)  default = $output_file
                                    name for the output file          
 _______________________________________________________________________________________

    -h|help                       (flag)       see the help/usage
    -v|verbose                    (flag)       run in verbose mode
    -d|debug                      (flag)       run in debug mode

);
  exit 1;
}



