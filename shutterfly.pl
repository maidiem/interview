
#######################################################
=begin INTRO
	This program that will return the name of the nth largest subdirectory in a
root directory on a remote host. For example, assume this directory structure exists on a server, host.example.com:

host.example.com:
dist/
a-1.0/ # 1.2 MBytes
a-1.1/ # 1.3 MBytes
a-1.2/ # 1.35 MBytes
b-2.7/ # 600 KBbytes
b-2.7.1/ # 623 KBytes
README.txt # 300 bytes

Given the input parameters "host.example.com", "/dist", and "3", your program
should return "a-1.0".

=end INTRO
=cut
########################################################
use strict;
use warnings;  
use Getopt::Long;
use Net::Ping;

my ($host,$path,$pos,$help) ;
my @data = ();

&get_opts();
#check if the remote host can be connected to
&check_remote_host($host);
&check_dir($host,$path);
sub check_dir
{
	my ($remote_host, $dir) = @_;
	my $command =  "ssh $remote_host \'test -e $dir \' ";
        system( "/bin/bash -c \"$command\" >/dev/null 2>&1" );
	my $rc = $? >> 8;
	if ($rc) {
    		print "$dir doesn't exist on the remote host $remote_host\n";
		exit 1;
	} 
	return;
}

#find the disk usage on the remote host at $path
&find_disk_usage($host,$path);
&compare_pos_vs_number_of_dir;


&print_output;

sub compare_pos_vs_number_of_dir
{
	#array index starting at 0
	my $index = $pos -1;
	if ($index > $#data)
	{
   		print "\nPlease try again. The position you enter is bigger than the number of directoris\n";
   		exit 1;
	}
}

sub print_output
{
   	my $i =0;
	#array index starting at 0
	my $index = $pos -1;
   	print "\tRemote_host:  $host\n";
	print "\tPATH:$path\n";
	print "\tnth_position: $pos\n\n";

   	for $i ( 0 .. $#data ) 
   	{
       		my $ele = $i+1;
       		print "\t\t$ele  is { ";
                my $role = '';
       		for $role ( keys %{ $data[$i] } ) 
		{
         		print "$data[$i]{$role} ";
       		}
       		print "}\n";
   	}
	print "\nThe " . $pos . "nth largest directory under $path: $data[$index]{'dir'}\n\n";
}

sub find_disk_usage
{
   my ($host, $path) = @_;
   my $cmd = "ssh eat1-app857.stg.linkedin.com \"cd /export/content ;  find . -type d -maxdepth 1  | xargs du -ksh | sort -rh \" 2> /tmp/$$.err ";
   my @output = `$cmd`;
   foreach (@output)
   {
	if (/^[0-9]/)
	{
	   my ($usage, $dir) = split(/\s+/);
           #skip the dot directory
	   if (($dir =~ /^\.$/) || ($dir =~ /\.\.$/)) { next;}
	   else 
	   {
		my $rec = {};
		$rec ->{'du'} = $usage;	
		$rec->{'dir'} = $dir;	
		push(@data, $rec);
	   }
	}
	else 
	{
		next;
	}
  }
}
sub check_remote_host
{
   my $remote_host = shift;
   my $p = Net::Ping->new();
   if (! $p->ping($remote_host)) 
   {
	print "Please check the remote host and try again\n";
        $p->close();
	exit 1;
   }
}

sub usage
{
    print "usage: $0 [--host HOST] [--path PATH] [--position POSITION_OF_NTH_LARGEST][--help|-?]\n";
    exit;
} 

sub get_opts
{
   if ( scalar(@ARGV) > 5   ) {
   GetOptions(
       'host|name=s'    => \$host,
       'path=s'     => \$path,
       'position=i' => \$pos,
       'help|h'     => \&usage,
      ) or &usage; 
   }
   else { &usage;}
   if ($pos <1) {
 	print "nth_largest position must be >=1\n";
	&usage;
   }
}

