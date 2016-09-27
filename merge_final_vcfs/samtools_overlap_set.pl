#!/usr/bin/perl

use warnings;
use strict;

if ( scalar @ARGV != 2 )	{	die "usage: perl samtools_overlap_set.pl (combined VCF of all 3 SNP callers) (samples to keep, 1 per line)\n";	}

my $combined_vcf = $ARGV[0];
my $samples2keep = $ARGV[1];

my %samtools = ();

my %o = (); ### sites as keys and hash of snp callers that called that site as values

print "##fileformat=VCFv4.0
##Tassel=<ID=GenotypeTable,Description=\"Reference allele is not known. The major allele was used as reference allele\",Version=5>
##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">
##FORMAT=<ID=AD,Number=.,Type=Integer,Description=\"Allelic depths for the reference and alternate alleles in the order listed\">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Read Depth (only filtered reads used for calling)\">\n";

my @header = qw(CHROM POS ID REF ALT QUAL FILTER INFO FORMAT );

$header[0] = "#" . $header[0];

open( 'SAMPLES' , '<' , $samples2keep ) or die "cant open SAMPLES $samples2keep\n";
while( <SAMPLES> )	{
	my @s = split( '\s+' , $_ );
	push( @header , $s[0] );
} close( 'SAMPLES');

my $header_out = join( "	" , @header );
print "$header_out\n";

open( 'VCF' , '<' , $combined_vcf  ) or die "cant open VCF $combined_vcf\n";
while( <VCF> )	{
		
	my @s = split( '\t+' , $_ );

	my $pos = $s[0] . ":" . $s[1];			

	my @pos_info = split( "_" , $s[2] );
	
	my $caller = $pos_info[2];
	
	$o{$pos}{$caller} = "";

} close( 'VCF' );	
			
open( 'VCF' , '<' , $combined_vcf  ) or die "cant open VCF $combined_vcf\n";
while( <VCF> )	{
		
	my @s = split( '\t+' , $_ );

	my $pos = $s[0] . ":" . $s[1];			

	my @pos_info = split( "_" , $s[2] );
	
	my $caller = $pos_info[2];
	
	if ( $caller eq "samtools" )	{
	
		if ( ( exists $o{$pos}{"samtools"} ) and ( ( exists $o{$pos}{"GATK"} ) or ( exists $o{$pos}{"tassel"} ) ) )	{
			
			my @info_fields = splice( @s , 8 );
			my @out = @s;
			
			foreach my $info ( @info_fields )	{

				my @info_split = split( ':' , $info );
				my $info_out = $info_split[0].":". $info_split[1].":".$info_split[2];
				push( @out , $info_out );

			} 
			
			my $out = join( "	" , @out );		
			print "$out\n";
				
		}
	}
	
} close( 'VCF' );	