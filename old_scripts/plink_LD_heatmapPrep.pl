#!/usr/bin/perl

use warnings;
use strict;
use Math::Round qw(nearest);

if ( scalar @ARGV != 4 )	{	die "(plink --r2 output) (dist to round to, e.g. 100, 1000, etc) (max distance) (rand chr name, to ignore)";	}

my $file = $ARGV[0];
my $round_target = $ARGV[1];
my $max_dist = $ARGV[2];
my $rand_chr = $ARGV[3];

my %t = (); # hash of all combinations, with counts as values
my $lc = 0; # line count

print "R2	dist	count\n";

open( 'LD_FILE' , '<' , $file ) or die "cant open LD_FILE $file\n";
while (<LD_FILE> )	{
	my @s = split( '\s+' , $_ );
	shift( @s ); ### whitespace at start so remove first element
	if ( $lc == 0 )	{	++$lc;	next	}
	if ( ( $s[0] eq $rand_chr) or ( $s[3] eq $rand_chr ) )	{	next	}	###skip because at least one of SNPs is on random chrom
	my $r2 = nearest( 0.05, $s[6] );
	my $dist = nearest( $round_target , abs( $s[1] - $s[4] ) );
	if ( $dist > $max_dist )	{	next	}	### skip if further than max dist
	my $combo = "$r2	$dist";
	if ( ! exists $t{$combo} )	{
		$t{$combo} = 1;
	} else {
		++$t{$combo};
	}
} close( 'LD_FILE' );

foreach my $combo ( keys %t )	{
	my $count = $t{$combo};
	print "$combo	$count\n";
}


