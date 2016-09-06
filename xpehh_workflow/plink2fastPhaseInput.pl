#!/usr/bin/perl

use warnings;
use strict;

if ( scalar @ARGV != 2 )	{	die "usage: perl plink2fastPhaseInput.pl (plink file, prefix for .map and .ped files) (output prefix for each file, 1 fastphase input file will be created for each chr)\n";	}

my $map = $ARGV[0] . ".map";
my $ped = $ARGV[0] . ".ped";

my %chr = (); # hash containing all unique chrs
my @chr = (); # array containing all chrs in the order they came up in .map file

my @cultivars = (); # all cultivars and their order

### first read through .map file and figure out all unique chrs
open( 'MAP' , '<' , $map ) or die "cant open MAP $map\n";
while (<MAP> )	{
	my @s = split( '[\t\n]' , $_ );
	if ( ! exists $chr{$s[0]} )	{
		$chr{$s[0]} = "";
		push ( @chr, $s[0] );
	}
} close( 'MAP' );

### then read in .ped and figure out total # cultivars and their order in file
open( 'PED' , '<' , $ped ) or die "cant open PED $ped\n";
while (<PED> )	{
	my @s = split( '\s+' , $_ );
	push ( @cultivars, $s[0] );
} close( 'PED' );

### loop through all unique chr and create a new output file for each one (this means that 1 chr is read into memory at a time)
foreach my $chr ( @chr )	{

	print STDERR "starting on chr $chr\n";

	my %p = (); # hash containing all ped indices as keys and positions as values (for whichever chr is being looped through)
	my %geno = (); # hash containing each cultivar as a key and the 1 and 2 genotypes as values
	my @pos = (); # array with all positions in order
	my $i = 0; 

	### read through .map file again and figure out which positions per chromosome the indices in .ped correspond to
	open( 'MAP' , '<' , $map ) or die "cant open MAP $map\n";
	while (<MAP> )	{
		my @s = split( '[\t\n]' , $_ );
		if ( $s[0] eq $chr )	{
			push ( @pos , $s[3] );
			$p{$i} = $s[3];
			++$i;
			$p{$i} = $s[3];
		} else {
			++$i;
		}
		++$i;
	} close( 'MAP' );
	
	open( 'PED' , '<' , $ped ) or die "cant open PED $ped\n";
	while (<PED> )	{
		my @s = split( '\s+' , $_ );
		my @meta = splice( @s , 0 , 6 );
		my $c = $meta[0];
		$geno{$c} = {};
		$geno{$c}{1} = "";
		$geno{$c}{2} = "";
		
		for ( my $i = 0; $i < scalar @s; ++$i )	{

			if ( ! exists $p{$i} )	{	++$i;	next	}	# mutation is on different chromosome, so skip

			my $pos1 = $p{$i};
			my $b1 = $s[$i];
			++$i;
			my $pos2 = $p{$i};
			my $b2 = $s[$i];
			
						
			if ( $pos1 != $pos2 )	{ die "mismatch of positions?\n";	}
			
			if ( $b1 eq "0" )	{ $b1 = "?" }
			if ( $b2 eq "0" )	{ $b2 = "?" }

			$geno{$c}{1} = $geno{$c}{1} . $b1;
			$geno{$c}{2} = $geno{$c}{2} . $b2;
		}
	} close( 'PED' );
	
	my $out = $ARGV[1] . "_chr"."$chr".".inp";
	print STDERR "creating output file $out\n";
	open ( 'OUT' , '>' , $out ) or die "cant create OUT $out\n";
	my $n_cultivars = scalar @cultivars;
	my $n_pos = scalar @pos;
	my $S_line = "S"x$n_pos;
	print OUT "$n_cultivars\n$n_pos\n";
	print OUT "P @pos\n";
	print OUT "$S_line\n";
	
	foreach my $c ( @cultivars )	{
	
		print OUT "# $c\n";
	
		my $geno1 = $geno{$c}{1};
		my $geno2 = $geno{$c}{2};

		print OUT "$geno1\n";
		print OUT "$geno2\n";
	}
	
	close( 'OUT' );
}