use strict;
use warnings;

my $lc = 0;

my %plate2file = ();
my %apple_id = ();
my %plates2apple_id = ();

open( 'BARCODE_KEY' , '</home/smyles/myles_lab/apple_GBS/Tassel5_realign/keyfiles/20151116_gbs_keyfile_usda_abc_cet_barcode_splitter.txt') or die "cant open BARCODE_KEY /home/smyles/myles_lab/apple_GBS/Tassel5_realign/keyfiles/20151116_gbs_keyfile_usda_abc_cet_barcode_splitter.txt\n";
while( <BARCODE_KEY> )	{
	
	if ( $lc == 0 )	{	++$lc;	next	};
	
	my @s = split( '\s+' , $_ );
	
	my $plate = $s[4];
	my $well  = $s[5] . $s[6];
	my $dnasample = $s[3];
	
	my $fastq = "/home/smyles/myles_lab/apple_GBS/GBSX_split_fastqs/GBSX_fastqs_trimmed/".$plate."/".$plate."_".$well."_".$dnasample.".trimmed.fastq.gz";
	
	my $location = $plate."_".$well;
	
	$plate2file{$location} = $fastq;
	
} close( 'BARCODE_KEY' );

$lc = 0;

open ( 'KEY' , '</home/smyles/myles_lab/apple_GBS/Tassel5_realign/20151116_gbs_keyfile_usda_abc_cet.txt' ) or die "can't open KEY /home/smyles/myles_lab/apple_GBS/Tassel5_realign/20151116_gbs_keyfile_usda_abc_cet.txt\n";
while( <KEY> )	{
		
	if ( $lc == 0 )	{	++$lc;	next	}
		
	my @s = split( '[\t\n]' , $_ );
	
	my $num_col = scalar @s;
	
	if ( scalar @s == 26 )	{
		push ( @s , "NA" );
	} elsif ( scalar @s == 25 )	{
		push ( @s , ("NA", "NA") );
	} elsif ( $num_col != 27 )	{
		die "num col is $num_col:\n\n$_\n\n";
	}
	
	my $apple_id = $s[$#s - 2];
	$apple_id =~ s/\s//g;
	$s[18] =~ s/\s//g;
	
	if ( $s[18] ne "domestica" )	{	next	}
	
	if ( ( $apple_id =~ m/\S/ ) and ( $apple_id ne "NA" ) )	{
		
		my $plate = $s[4];
		my $well = $s[10];
		
		$plate =~ s/\s//g;
		$well  =~ s/\s//g;
	
		if ( ! exists $apple_id{$apple_id} )	{
			$apple_id{$apple_id} = {};
		}
		
		my $location = $plate."_".$well;
		
		$plates2apple_id{$location} = $apple_id;
		
		my $fastq = $plate2file{$location};
		
		$apple_id{$apple_id}{$fastq} = ""
		
	} 
	
} close( 'KEY' );

$lc = 0;

my %cet_id2apple_id = ();
my %cet_id = ();

open( 'CET' , '</home/smyles/myles_lab/apple_GBS/Tassel5_realign/keyfiles/20160112_cetkeyfile4kendra.txt' ) or die "cant open CET /home/smyles/myles_lab/apple_GBS/Tassel5_realign/keyfiles/20160112_cetkeyfile4kendra.txt\n";
while( <CET> )	{
	
	if ( $lc == 0 )	{	++$lc;	next	}
		
	my @s = split( '[\t\n]' , $_ );
	
	my $plate = $s[4];
	my $well = $s[10];
		
	$plate =~ s/\s//g;
	$well  =~ s/\s//g;
	
	my $location = $plate."_".$well;
	
	my $cet_id = $s[$#s];
	$cet_id =~ s/\s//g;
	
	if ( exists $plates2apple_id{$location} )	{
		$cet_id2apple_id{$cet_id} = $plates2apple_id{$location};
	} else {}
	
	if ( ! exists $cet_id{$cet_id} )	{
		$cet_id{$cet_id} = {};
	} else {}
	
	my $fastq = $plate2file{$location};
	
	$cet_id{$cet_id}{$fastq} = "";
	
} close( 'CET' );

foreach my $id ( keys %cet_id )	{
	
	my @fastqs = keys %{$cet_id{$id}};
	
	if ( exists $cet_id2apple_id{$id} )	{
		
		my $apple_id = $cet_id2apple_id{$id};
		
		my @apple_id_fastqs = keys %{$apple_id{$apple_id}};
		
		if ( scalar @fastqs == scalar @apple_id_fastqs )	{
			
			#print STDERR "match between CET: @fastqs\nand ABC: @apple_id_fastqs\n\n";
			
			print "ln -s /home/smyles/myles_lab/apple_GBS/ABC_domestica_ind_fastqs/$apple_id".".fastq.gz /home/smyles/myles_lab/CET/CET_ind_fastqs/$id".".fastq.gz\n";
			next;
		}
		
	}
	
	print "cat @fastqs > /home/smyles/myles_lab/CET/CET_ind_fastqs/$id".".fastq.gz\n";
	
}
