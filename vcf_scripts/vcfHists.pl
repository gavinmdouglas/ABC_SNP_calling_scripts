#!/usr/bin/perl

use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;

my $help; 
my $version_marker;
my $version = "0.1";
my $suppress_qual_marker;
my $suppress_qual = "FALSE";

my $vcf;

my $qual_bin = 5;
my $qual_max = 100;

my $depth_bin = 5;
my $depth_max = 100;

my $qual_out = "vcfHist_qual.txt";
my $depth_out = "vcfHist_depth.txt";
my $log = "vcfHists_log.txt";

my $res = GetOptions(
	"version" => \$version_marker,
	"help|h" => \$help,
	"suppress_qual" => \$suppress_qual_marker,
	"vcf|v=s" => \$vcf,
	"qual_bin=i" => \$qual_bin,
	"qual_max=i" => \$qual_max,
	"depth_bin=i" => \$depth_bin,
	"depth_max=i" => \$depth_max,
	"qual_out=s" => \$qual_out,
	"depth_out=s" => \$depth_out,
	"log|l=s" => \$log,
)	or pod2usage(2);

pod2usage(-verbose=>2) if $help;

if ( $version_marker )	{	print "version $version\n";	exit	}

if ( $suppress_qual_marker ) { $suppress_qual = "TRUE"; }

if ( ! defined $vcf )	{	die "VCF file indicated by \"--vcf\" argument is needed (run \"vcfHists.pl -h\" if you need help)\n";	}
if ( $depth_max % $depth_bin != 0 )	{	die "depth_max ($depth_max) needs to be a multiple of depth_bin ($depth_bin)\n";	}
if ( ( $suppress_qual eq "FALSE" ) and ( $qual_max % $qual_bin != 0 ) )	{	die "qual_max ($qual_max) needs to be a multiple of qual_bin ($qual_bin)\n";	}

#hashes that will keep track of frequencies in each bin
my %d = (); 
my %q = ();

my %d2bin = (); # hash with possible depths as keys and bins as values
my %q2bin = (); # as above but for quality scores

# arrays holding bins in order to be printed.
my @q_bin = ();
my @d_bin = ();

my $tmp_bin = $depth_bin; # first bin
for ( my $i = 1; $i <= $depth_max + 1; ++$i )	{
		if ( $i > $tmp_bin )	{ $tmp_bin += $depth_bin;	}	
		if ( $tmp_bin < $depth_max + $depth_bin )	{
			$d2bin{$i} = $tmp_bin;
			
			if ( ! exists $d{$tmp_bin} )	{	$d{$tmp_bin} = 0; push( @d_bin , $tmp_bin );	}
		} else { 

			$d{">"."$depth_max"} = 0; 
			push( @d_bin, ">"."$depth_max" );
			last; 
		}
} 

if (  $suppress_qual eq "FALSE" )  {
	$tmp_bin = $qual_bin;
	for ( my $i = 1; $i <= $qual_max + 1; ++$i )	{
			if ( $i > $tmp_bin )	{ $tmp_bin += $qual_bin;	}	
			if ( $tmp_bin < $qual_max + $qual_bin)	{
				$q2bin{$i} = $tmp_bin;
				if ( ! exists $q{$tmp_bin} )	{	$q{$tmp_bin} = 0; push( @q_bin , $tmp_bin );	}
			} else { 
				push( @q_bin, ">"."$qual_max" );
				$q{">"."$qual_max"} = 0; 
				last;
			}
	} 
}

open( 'VCF' , '<' , $vcf ) or die "cant open VCF $vcf\n";
while (<VCF> )	{
	
	my $first = substr( $_ , 0 , 1 );
	if ( $first eq "#" )	{	next	}		

	my @s = split( '[\t\n]' , $_ );
	
	my @ind = splice( @s, 9 );
	
	my @d = ();
	my @ind_test = (); # for testing purposes
	
	foreach my $ind ( @ind )	{
		
		my @info = split ( '[\/,:]' , $ind );
		my @fields = split ( ':' , $ind );
		
		if ( ($info[0] eq "." ) or ( $info[1] eq "." ) or ( ! exists $fields[2] ) or ( $fields[2] !~ m/\S/g ) or ( $fields[2] eq "." ) or ( $fields[2] <= 0 ) )	{	next	}

		push ( @d , $fields[2] );
		push ( @ind_test , $ind );
				
	}

	if (  $suppress_qual eq "FALSE" )  {
		my $q_bin;
		my $q = int( $s[5]  );
		if ( $q > $qual_max ) {
			$q_bin = ">".$qual_max;
		} else {
			$q_bin = $q2bin{$q};
		}
		$q{$q_bin} += 1;
	}
	
	my $ind_count = 0;
	
	foreach my $d ( @d )	{
		my $d_bin;
		if ( $d > $depth_max ) {
			$d_bin = ">".$depth_max;
		} else {
			$d_bin = $d2bin{$d};
		}
		
		#if ( $d_bin == 99 )	{ print "99 === $ind_test[$ind_count]\n";	}
		
		####print STDERR "=$d=$d_bin=$ind_test[$ind_count]\n";
		$d{$d_bin} += 1;
		++$ind_count;
	}


} close( 'VCF' );

if (  $suppress_qual eq "FALSE" )  {
	open( 'QUAL_OUT' , '>' , $qual_out ) or die "cant open QUAL_OUT $qual_out\n";
	foreach my $b ( @q_bin)	{
		print QUAL_OUT "$b	".$q{$b}."\n";
	}
	close('QUAL_OUT');
}

open( 'DEPTH_OUT' , '>' , $depth_out ) or die "cant open DEPTH_OUT $depth_out\n";
foreach my $b ( @d_bin)	{
	print DEPTH_OUT "$b	".$d{$b}."\n";
}
close('DEPTH_OUT');

=head1 Name

vcfHists.pl - Simple script to output per-site base quality and depth.

=head1 USAGE

vcfHists.pl --vcf <vcf file to parse> [--help --version --log <logfile> --qual_bin <bin size for qual histogram> --depth_bin <bin size for depth histogram> --qual_max <max quality score to include> --depth_max <max depth to include> --qual_out <quality histogram output file> --depth_out <depth histogram output file>]

=head1 OPTIONS

=over 4

=item B<-h, --help>

Displays the entire help documentation.

=item B<--version>

Displays version number and exits.

=item B<-v, --vcf (file)>

Input vcf to be parsed. Required.

=item B<--suppress_qual>

Output only depth histograms and no quality report.

=item B<--log (file)>

The location to write the log file. Default is vcfHists_log.txt.
 
=item B<--qual_bin (int)>

Quality score histogram bin size (number of bins will be determined by this value). Default value is 5.

=item B<--qual_max (int)>

Maximum quality score to include in quality score histogram (all values >= to qual_max will be included in the final bin). This number needs to be a multiple of "qual_bin". Default value is 100.

=item B<--qual_out (file)>

Output file for quality score histogram. Default is vcfHist_qual.txt.

=item B<--depth_bin (int)>

Depth of coverage histogram bin size (number of bins will be determined by this value). Default value is 5.

=item B<--depth_max (int)>

Maximum depth to include in depth of coverage histogram (all values >= to depth_max will be included in the final bin). This number needs to be a multiple of "depth_bin". Default value is 100.

=item B<--depth_out (file)>

Output file for depth of coverage histogram. Default is vcfHist_depth.txt.

=back

=head1 AUTHOR

Gavin Douglas <gavin.douglas@dal.ca>

=cut