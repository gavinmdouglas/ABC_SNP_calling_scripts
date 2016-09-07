use strict;
use warnings;

if ( scalar @ARGV != 3 )	{	die "(textfile with 1 command per line) (number of commands per file) (text file containing header for sh scripts)\n";	}

### reading in header to use from specified file:
my $settings = "";
open( 'HEAD' , '<' , $ARGV[2] ) or die "cant open HEADER file $ARGV[2]\n";
while( <HEAD> )	{
	$settings = $settings . "$_";
} close( 'HEAD' );

my $file_num = 0;
my $count = 0;

my $out = $ARGV[0] . "_split$file_num.sh";
open( 'OUT' , '>' , $out ) or die "cant open OUT $out\n";
print OUT "$settings\n";
print OUT "echo Job beginning at `date`\n";


open( 'COMMANDS' , '<' , $ARGV[0] ) or die "cant open COMMANDS $ARGV[0]\n";
while ( <COMMANDS> )	{
	
	print OUT "$_";
	
	++$count;

	if ( $count == $ARGV[1] )	{
		$count = 0;
		print OUT "echo Job ending at `date`\n";
		close( 'OUT' );
		++$file_num;
		$out = $ARGV[0] . "_split$file_num.sh";
		open( 'OUT' , '>' , $out ) or die "cant open OUT $out\n";
		print OUT "$settings\n";
		print OUT "echo Job beginning at `date`\n";
	} else {}
	
} close( 'COMMANDS' ); 

if ( tell('OUT') != -1 )	{	#OUT is still open
	print OUT "echo Job ending at `date`\n";
	close( 'OUT' );
}
