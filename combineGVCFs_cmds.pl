#!/usr/bin/perl

use warnings;
use strict;

if ( scalar @ARGV != 5 )	{	die "(in dir) (number samples per combined GVCF) (out dir) (Path to GATK jarfile) (Path to reference fasta)\n"	}

my $in_dir = $ARGV[0];
my $num = $ARGV[1];
my $out_dir = $ARGV[2];
my $GATK = $ARGV[3];
my $ref = $ARGV[4];

opendir(DIR, $in_dir ) or die "cannot open DIR $in_dir\n";
my @f = grep(/\.vcf$/ ,readdir(DIR));

my $c = 0; ### sample count
my $g = 0; ### rep count

if ( ! -e $out_dir )	{	system( "mkdir $out_dir" )	}

foreach my $f ( @f )	{

	$f = $in_dir . "/". $f;

	if ( $c == 0 )	{
		print " java -jar $GATK  -T CombineGVCFs \    -R $ref "; 
	}

	print "--variant $f ";
	
	++$c;

	if ( $c == $num )	{
		$c = 0;
		print "-o $out_dir/$g"."_combined.vcf 2> $out_dir/$g"."_combined.vcf.log\n\n";
		++$g;
	}
	
}
closedir(DIR);

if ( $c != $num )	{
	print "-o $out_dir/$g"."_combined.vcf 2> $out_dir/$g"."_combined.vcf.log\n\n";
}

