#!/usr/bin/perl

use warnings;
use strict;

if ( scalar @ARGV != 1 )	{	die "(folder containing *xpehh.out files)\n";	}

my %c2f = (); #chr to file
opendir(DIR, $ARGV[0] ) or die "cannot open DIR $ARGV[0]\n";
my @f = grep(/\.xpehh\.out$/,readdir(DIR));
print "chr	name	pos	gpos	p1	ihh1	p2	ihh2	xpehh\n";
foreach my $f ( @f )	{
	my @info = split( '_' , $f );
	my $chr = $info[0];
	$chr =~ s/chr//;
	$c2f{$chr} = $f;
}

for my $c ( sort {$a<=>$b} keys %c2f) {
	my $f = $c2f{$c};
	my $lc = 0;
	open( 'CHR_OUT' , '<' , $ARGV[0] ."/".$f ) or die "cant open CHR_OUT $ARGV[0]/$f\n";
	while(<CHR_OUT>)	{
		my @s = split('[\t\n]',$_ );
		if ( $lc == 0 )	{	++$lc;	next	}
		my @coor = split( '_' , $s[0] );
		my $chr = $coor[0];
		$chr =~ s/S//;
		unshift( @s , $chr );
		my $line = join( "	" , @s );
		print "$line\n";
	} close('CHR_OUT');
}
closedir(DIR);

