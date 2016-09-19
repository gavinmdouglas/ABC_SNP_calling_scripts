#!/usr/bin/perl

use warnings;
use strict;

my %s = (); ### pos as key and every possible site at that pos as value

print "##fileformat=VCFv4.0
##Tassel=<ID=GenotypeTable,Description=\"Reference allele is not known. The major allele was used as reference allele\",Version=5>
##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">
##FORMAT=<ID=AD,Number=.,Type=Integer,Description=\"Allelic depths for the reference and alternate alleles in the order listed\">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Read Depth (only filtered reads used for calling)\">\n";

my @header = qw(CHROM POS ID REF ALT QUAL FILTER INFO FORMAT );

$header[0] = "#" . $header[0];

open( 'SAMPLES' , '<samples2keep.txt' ) or die "cant open SAMPLES samples2keep.txt\n";
while( <SAMPLES> )	{
	my @s = split( '\s+' , $_ );
	push( @header , $s[0] );
} close( 'SAMPLES');

my $header_out = join( "	" , @header );
print "$header_out\n";

my @pos_order = ();

open( 'VCF' , '<GATK_samtools_tassel_combined_raw.vcf'  ) or die "cant open VCF GATK_samtools_tassel_combined_raw.vcf\n";
while( <VCF> )	{
		
	my @s = split( '\t+' , $_ );

	my $pos = $s[0] . ":" . $s[1];			

	if ( ! exists $s{$pos} )	{
		$s{$pos} = {};
		push( @pos_order , $pos );
	}
	
	$s{$pos}{$_} = "";

} close( 'VCF' );	
			
foreach my $pos ( @pos_order )	{

	my %tmp = %{$s{$pos}};
	my @lines = ( keys %tmp );
	my @s = split( '\s+' , $lines[rand @lines] ) ;
	
	my @info_fields = splice( @s , 8 );
	my @out = @s;

	foreach my $info ( @info_fields )       {

		my @info_split = split( ':' , $info );
		my $info_out = $info_split[0].":". $info_split[1].":".$info_split[2];
		push( @out , $info_out );

	}

	my $out = join( "	" , @out );
	
	print "$out\n";
}
