use strict;
use warnings;

### this script generates 2 new input keyfiles for Tassel separated by restriction enzyme, with a new FullSampleName column with ids that are the apple IDs 
### originally this script also ignored samples that weren't domestica, but not in this version. 

if ( scalar @ARGV != 2 )	{	die "\nusage: perl parse_keyfile.pl (full keyfile) (date to use as prefix)\n\n\nThis script prepares keyfiles to run SNP calling with Tassel\n\nNote that this script assumes columns called FullSampleName, Enzyme and apple_id are in the input keyfile\nOnly sequencing wells that have associated apple_ids will be retained.\n2 output files will be made: 1 keyfile for ApeKI and 1 keyfile for PstI/EcoT22I\nNote that in the output files FullSampleName is just the apple_ids\n\n";	}  

### user-specified arguments:
my $input_key = $ARGV[0];
my $prefix = $ARGV[1];

### output filenames:
my $PstI_out = $prefix."_gbs_keyfile_ABC_PstI-EcoT22I.txt";
my $ApeKI_out = $prefix."_gbs_keyfile_ABC_ApeKI.txt";

### open output filehandles:
open( 'PSTI' , '>' , $PstI_out ) or die "cant create PSTI $PstI_out\n";
open( 'APEKI' , '>' , $ApeKI_out ) or die "cant create APEKI $ApeKI_out\n";

my $lc = 0; # line count, important to figure out which is header

### column indices for apple_id and enzyme, which will be figured out when header line is read in
my $apple_id_index;
my $enzyme_index;

### read through input keyfile:
open ( 'KEY' , '<' , $input_key  ) or die "can't open KEY $input_key\n";
while( <KEY> )	{
		
	my @s = split( '[\t\n]' , $_ );
		
	if ( $lc == 0 )	{
		
		### since header line, figure out which column is FullSampleName and change name. Add new header called FullSampleName which will be apple_id. 
		### also figure out the column indices for apple_id and enzyme 


		### figure out the column indices for apple_if and enzyme
		my $index = 0;
		foreach my $s ( @s )	{
			if ( $s eq "apple_id" )	{	
				$apple_id_index = $index;
			} elsif ( $s eq "Enzyme" )	{
				$enzyme_index = $index;
			}
			
			++$index;
		}			


		$s[14] = $s[14] . "_old";	### change name of "FullSampleName" in keyfile	
		
		unshift( @s , "FullSampleName"); ### add new column called "FullSampleName"
		my $h = join( "	" , @s );
		print PSTI"$h\n";
		print APEKI "$h\n";
		
		++$lc; 
		next;	
	}		

	my $apple_id = $s[$apple_id_index];
	my $enzyme = $s[$enzyme_index];
		
	if ( ( $apple_id ne "NA" ) and ($apple_id =~ m/\S/g ) )	{

		unshift( @s , $apple_id );
		my $line = join( "	" , @s ) ;

		if ( $enzyme eq "ApeKI" )	{
			print APEKI "$line\n";
		} elsif ( $enzyme eq "PstI/EcoT22I" )	{
			print PSTI "$line\n";
		} else {	
			die "what is enzyme $enzyme at line $.?\n";
		} 
	}
 
} close ( 'KEY');
close( 'APEKI' );
close( 'PSTI' );
