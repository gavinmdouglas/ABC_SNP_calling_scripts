#!/usr/bin/perl

use warnings;
use strict;

if ( scalar @ARGV != 2 )	{	die "(in dir) (out dir)\n";	}

my $in_dir = $ARGV[0];
my $out_dir = $ARGV[1];

opendir(DIR, $in_dir ) or die "cannot open DIR $in_dir\n";
my @f = grep(/\.vcf$/ ,readdir(DIR));

my $c = 0;
my $g = 0;

foreach my $f ( @f )	{

	$f = $in_dir . "/". $f;

	if ( $c == 0 )	{
		print " java -jar /usr/local/prg/GenomeAnalysisTK-3.5/GenomeAnalysisTK.jar  -T CombineGVCFs \    -R /home/gavin/myles_lab/apple_cet/tassel_redo/Malus_x_domestica.v1.0-primary.pseudo_plus_Unass_UI.fa "; 
	}

	print "--variant $f ";
	
	++$c;

	if ( $c == 49 )	{
		$c = 0;
		print "-o $out_dir/$g"."_combined.vcf 2> $out_dir/$g"."_combined.vcf.log &\n\n";
		++$g;
	}
	
}
closedir(DIR);

if ( $c != 49 )	{
	print "-o $out_dir/$g"."_combined.vcf 2> $out_dir/$g"."_combined.vcf.log &\n\n";
}
