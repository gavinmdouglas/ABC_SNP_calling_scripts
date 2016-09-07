#!/usr/bin/perl

use warnings;
use strict;

use Getopt::Long;
use Pod::Usage;

my $help; 
my $version_marker;
my $version = "0.1";
my $gff3;

my $res = GetOptions(
	"version" => \$version_marker,
	"help|h" => \$help,
	"gff3|g" => \$gff3,
)	or pod2usage(2);

pod2usage(-verbose=>2) if $help;

if ( $version_marker )	{	print "version $version\n";	exit	}
if ( ! defined $gff3 )	{	die "need to indicate input .gff3 file with the --gff3 option (add the \"--help\" option for help)\n";	}

my %c = (); # hash to keep track of contig sizes as keys and # of contigs of that size as values

my $total = 0; # total assembly length (in contig size)
my $num_contigs = 0; # total number of contigs

open( 'GFF3' , '<' , $gff3 ) or die "cant open GFF3 $gff3\n";
while ( <GFF3> )	{
	
	my @s = split( '\s+' , $_ );

	if ( $s[2] eq "contig" )	{
		
		my $length = $s[4] - $s[3] + 1;
		
		$total += $length;
		$num_contigs += 1;

		if ( ! exists $c{$length} )	{
			$c{$length} = 1;
		} else {
			$c{$length} += 1;
		}
	}	
	
} close( 'GFF3' );

my $half = int ( $total / 2 ); # this is the N50 point
my $current = 0; # iterate through contig sizes and add to this scalar
my $L50 = 0;

LENGTHS: for my $length ( sort {$a<=>$b} keys %c) {
           
	my $count = $c{$length};

	TIES: for ( my  $i = 1; $i < $count + 1; ++$i )	{ # most contigs have a unique length anyway, but there could be a few
	
		$current += $length;
		
		$L50 += 1;
	
		if ( $current >= $half )	{
			
			print "total contigs = $num_contigs\n";
			print "total length = $total\n";
			print "N50 length = $length\n";
			print "L50 count = $L50\n";

			last LENGTHS;
			last TIES;
		}

	}
}

=head1 Name

assemblyMetrics.pl - This simple script reads in a gff3 file and outputs the N50 and L50.

=head1 USAGE

assemblyMetrics.pl --gff3 <gff3 file to parse> [--help --version] > output
my $tmp_out = $gff3 . "_tmp.txt";

open( 'TMP' , '>' , $tmp_out ) or die "cant create TMP $tmp_out\n";


=head1 OPTIONS

=over 4

=item B<-h, --help>

Displays the help documentation.

=item B<--version>

Displays version number and exits.

=item B<-g, --gff3 (file)>

Input gff3 to be parsed. Required.

=back

=head1 AUTHOR

Gavin Douglas <gavin.douglas@dal.ca>

=cut
