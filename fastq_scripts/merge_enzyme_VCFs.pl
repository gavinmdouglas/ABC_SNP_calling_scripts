#!/usr/bin/perl

use warnings;
use strict;

if ( scalar @ARGV != 3 )	{	
	die "usage: (vcf1 - will keep overlapping sites from this VCF) (vcf2) (outfile)\n\nThis script merges 2 VCF files which have the same sets of samples. For overlapping sites, the site found in vcf1 will be kept.\nNote that 3 tmp files will be created in your current working directory: header_tmp.txt, tmp_sort.vcf and tmp_sort.sorted.vcf. These will be deleted once the job is finished.";
}

my $vcf1 = $ARGV[0];
my $vcf2 = $ARGV[1];
my $out = $ARGV[2];

my %sites = ();

my @vcf1_order = ();
my %vcfSamples2index = ();

open( 'TMP' , '>tmp_sort.vcf' ) or die "cant create TMP\n";
open( 'HEAD' , '>header_tmp.txt' ) or die "cant create HEAD TMP\n";

open( 'VCF1' , '<' , $vcf1 ) or die "cant open VCF1 $vcf1\n";
while (<VCF1> )  {

	my @s = split( '[\t\n]' , $_ );

	my $first = substr( $_ , 0 , 1);

	if ( $first eq "#" )	{	
		print HEAD "$_";
		if ( $s[0] eq "#CHROM" )	{
			@vcf1_order = splice( @s , 9 );
		}
		next;
	}

	my $coor = "$s[0]"."_"."$s[1]";
	$sites{$coor} = "";
	
	print TMP "$_";

} close( 'VCF1' );


open( 'VCF2' , '<' , $vcf2 ) or die "cant open VCF2 $vcf2\n";
while (<VCF2> )  {

	my @s = split( '[\t\n]' , $_ );

	my $first = substr( $_ , 0 , 1);

	if ( $first eq "#" )	{	

		### need to figure out order of individuals in case they differ between the 2 VCFs
		if ( $s[0] eq "#CHROM" )	{
			my @ind = splice( @s , 9 );
			my $i = 0;
			foreach my $ind ( @ind )	{
				$vcfSamples2index{$ind} = $i;
				++$i;
			}
		}
		next;
	}
	
	my $coor = "$s[0]"."_"."$s[1]";
	
	if ( exists $sites{$coor} )	{	next	} ### only print overlapping sites from first VCF
	
	my @ind = splice( @s , 9 );
	
	my @out = splice( @s , 0 );
	
	foreach my $vcf1Ind ( @vcf1_order )	{
		my $index = $vcfSamples2index{$vcf1Ind};
		push( @out , $ind[$index] );
	}
	
	my $line = join( "	" , @out );
	print TMP "$line\n";
	
} close( 'VCF2' );

system("sort -k1,1 -k2,2n tmp_sort.vcf > tmp_sort.sorted.vcf" );
system("cat header_tmp.txt tmp_sort.sorted.vcf > $out" );
system("rm tmp_sort.vcf");
system("rm tmp_sort.sorted.vcf");
system("rm header_tmp.txt" );
