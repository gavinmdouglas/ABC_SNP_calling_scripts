#!/usr/bin/perl

use warnings;
use strict;
use Bio::DB::Fasta;

if ( scalar @ARGV != 1 )	{	die "usage: (closest dist textfile)\n";	}

my $txt = $ARGV[0];
my $fasta = $ARGV[1];

my $lc = 0;

my %dist_count  = (); # keys == dist ; values == count
my %dist_total = (); #keys == dist ; values == total
my %past_snps = (); #snps to ignore

open( 'DIST' , '<' , $txt ) or die "cant open DIST file $txt\n";

while( <DIST> )	{

	if ( $lc == 0 )	{	++$lc;	next	}	

	my @s = split( '\s+' , $_ );

	if ( $s[$#s] > 50 )	{	next	}
	
	my $chrom = $s[0];
	my $start = $s[1];
	
	if ( exists $past_snps{"$chrom,$start"} )	{	next	}

	$past_snps{"$s[3],$s[4]"} = "";

	my $stop = $s[2] + 1;

	my $db = Bio::DB::Fasta->new("/home/gavin/myles_lab/Malus_x_domestica.v1.0-primary_reference/split_by_chr");

#	print "$chrom	$start	$stop\n";
	
	my $seq = $db->seq($chrom, $start => $stop);
	if ( (! defined $seq ) or (length ( $seq ) != 3 ) )	{	next	}
		
	$seq = uc $seq;

	if ( ! exists $dist_total{$s[$#s]} )	{	$dist_total{$s[$#s]} = 0	}
	if ( ! exists $dist_count{$s[$#s]} )    {       $dist_count{$s[$#s]} = 0        }

	$dist_total{$s[$#s]} += 1;

	if ( $seq =~ m/CG/g )	{
		$dist_count{$s[$#s]} += 1;
	} else {}
}

print "dist	count	total	pro\n";
for ( my $i = 1; $i < 51; ++$i )	{

	my $c = $dist_count{$i};
	my $total = $dist_total{$i};
	my $pro = $c / $total;
	print "$i	$c	$total	$pro\n";

}
