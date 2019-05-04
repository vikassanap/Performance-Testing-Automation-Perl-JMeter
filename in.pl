#!/usr/bin/perl

# use module
use XML::Simple;
use Data::Dumper;
use Getopt::Std;
use File::Copy;
use Class::CSV;
use vars qw / %opt /;
use HTML::TableExtract;
use Config::Properties;
use DateTime;
use Time::HiRes;
use Email::Send::SMTP::Gmail;

$xml = new XML::Simple;

#--Start-Variable Declaration--
my @no_of_users;
my @min_response_time;
my @max_response_time;
my @avg_response_time;
my @error_percentage;
my @failure_rate;
my @url_list;
my @ramp_up_period;
my @scenario_name;
my @test_plan_name;
my @no_of_loops;
my @sno_, @scenario_, @users_, @ramp_, @loop_, @min_rt, @max_rt, @avg_rt,
  @more_info, @min_mem_usage, @max_mem_usage, @avg_mem_usage, @min_cpu_usage,
  @max_cpu_usage, @avg_cpu_usage;
my $test_plan_count = 0;
@temp_csv_list;

#--End-Variable Declaration--

#---Start Reading config.properties---
open my $fh, '<', 'config.properties'
  or die "unable to open configuration file";

my $properties = Config::Properties->new();
$properties->load($fh);
$project_name  = $properties->getProperty('project_name');
$tomcat_url    = $properties->getProperty('tomcat_url');
$mail_dir      = $properties->getProperty('mail_dir');
$output_dir    = $properties->getProperty('output_dir');
$jtl_dir       = $properties->getProperty('jtl_dir');
$tomcat_dir    = $properties->getProperty('tomcat_dir');
$test_interval = $properties->getProperty('test_interval');

$from_email       = $properties->getProperty('from_email');
$from_password    = $properties->getProperty('from_password');
$temp_mail_string = 'to_email';
$i_index          = 0;
@to_mail_list;

while (
	( $properties->getProperty( $temp_mail_string . $i_index ) ) ne 'mail-end' )
{
	$to_mail_list[$i_index] =
	  $properties->getProperty( $temp_mail_string . $i_index );
	$i_index++;
}

#---End Reading config.properties---




sub init {

	my $opt_str = 'h:c:i:';
	getopts( "$opt_str", \%opt );
	usage() if !$opt{c};
	usage() if !$opt{i};
	usage() if $opt{h};

}

sub usage {

	print "\n", "=" x 20, "USAGE", "=" x 20, "\n";
	print "\n USAGE $0 [-h] -c -i\n";
	print "-h Prints this message\n";
	print "-c Config File\n";
	print "-i Input File\n";
	print "\n", "=" x 20, "USAGE", "=" x 20, "\n";
	exit 0;

}

init;
my $config_file = $opt{c};

# read XML file
$data = $xml->XMLin( $opt{i} );
my $config_file = "config.properties";

print $data->{test};
open my $Conf_FH, '<', $config_file
  or die "cannot open file for reading $config_file\n";
my %config_hash;
while (<$Conf_FH>) {

	chomp($_);
	next unless ( $_ =~ m/^(.*)=(.*)$/ );
	{
		$config_hash{$1} = $2;
	}

}

if ( ref( $data->{test} ) eq "HASH" ) {
	$command = "ant";
	my $flag = 0;

	# PRINT OLD HASH
	print "\n-------------";
	while ( ( $key, $value ) = each( $data->{test} ) ) {

		print "\n" . $value;
		$temp_csv_list[$flag] = $value;
		$command .= " -D" . $key . "=" . $value;
		$flag++;
	}
	print "\n-------------";
	while ( ( $key, $value ) = each(%config_hash) ) {
		$command .= " -D" . $key . "=" . $value;
	}
	print $command;
	system "$command";
	print "when single test plan---";

	print "!-------------\n";
	for ( $i = 0 ; $i < 6 ; $i++ ) {
		print $temp_csv_list[$i];
	}

	print "\nSleep Started............";
	Time::HiRes::sleep($test_interval);
	print "\nSleep ended..............";

	#-----Start_Parse Html file
	my $att;
	my $count = 0;
	my $string1;
	my $string2;

	print "hello";
	opendir( DIR, $mail_dir ) or die $!;

	my $count = 0;
	while ( my $file = readdir(DIR) ) {

		next unless ( -f "$mail_dir/$file" );

		next unless ( $file =~ m/\.html$/ );

		$att->[$test_plan_count]->{file} = $mail_dir . $file;

		$tmpfile = "";
		print "\t----" . $att->[$test_plan_count]->{file} . "-----\n";
		open( FILE, $att->[$test_plan_count]->{file} )

		  || die "Unable to open file!\n";
		@file = <FILE>;
		foreach $line (@file) {
			$tmpfile = $tmpfile . $line;
		}
		$row_cnt = 0;
		$tables  = [];
		$te      = new HTML::TableExtract( depth => 0, count => 1 );
		$te->parse($tmpfile);
		foreach $ts ( $te->table_states ) {

			#  print "\nTable found at ", join(',', $ts->coords), ":\n";
			foreach $row ( $ts->rows ) {
				if ( $row_cnt == 1 ) {
					$tmp = join( ',', @$row );

					@tmp = split( ',', $tmp );
				}
				$row_cnt++;
			}
		}

		#$no_of_users[$test_plan_count]       = $tmp[0];
		$failure_rate[$test_plan_count]      = $tmp[1];
		$error_percentage[$test_plan_count]  = $tmp[2];
		$avg_response_time[$test_plan_count] = $tmp[3];
		$min_response_time[$test_plan_count] = $tmp[4];
		$max_response_time[$test_plan_count] = $tmp[5];
		print "\n---------------!!!!!!!!!!!";
		print "\n" . $failure_rate[$test_plan_count];
		print "\n" . $error_percentage[$test_plan_count];
		print "\n" . $avg_response_time[$test_plan_count];
		print "\n" . $min_response_time[$test_plan_count];
		print "\n" . $max_response_time[$test_plan_count];

		print "\n---------------!!!!!!!!!!!";

		closedir(DIR);

		#-----End_Parse Html file

		#-----Start Getting Url
		opendir( DIR, $mail_dir ) or die $!;

		while ( my $file = readdir(DIR) ) {

			next unless ( -f "$mail_dir/$file" );

			next unless ( $file =~ m/\.html$/ );
			$att->[$test_plan_count]->{file} = $dir . $file;
			print "$att->[$test_plan_count]->{file}\n";
			my $string4 = $tomcat_url . $file;
			$string4 =~ s/\s/%20/g;
			$url_list[$test_plan_count] = $string4;
			print "\n" . $url_list[$test_plan_count] . "\n";

		}
		closedir(DIR);

		$ramp_up_period[$test_plan_count] = $temp_csv_list[0];
		$test_plan_name[$test_plan_count] = $temp_csv_list[1];
		$no_of_users[$test_plan_count]    = $temp_csv_list[2];
		$no_of_loops[$test_plan_count]    = $temp_csv_list[3];
		$scenario_name[$test_plan_count]  = $temp_csv_list[5];

		print "\n--report--\n";
		print $scenario_name[$test_plan_count] . "\t";
		print $no_of_users[$test_plan_count] . "\t";
		print $ramp_up_period[$test_plan_count] . "\t";
		print $no_of_loops[$test_plan_count] . "\t";
		print $min_response_time[$test_plan_count] . "\t";
		print $max_response_time[$test_plan_count] . "\t";
		print $avg_response_time[$test_plan_count] . "\t";
		print $error_percentage[$test_plan_count] . "\t";
		print $failure_rate[$test_plan_count] . "\t";
		print $url_list[$test_plan_count] . "\n";

		#-----End Getting Data From CSV File

		#-----Start copy from mail dir to Tomcat Dir
		opendir( my $DIR, $mail_dir ) || die "can't opendir $mail_dir: $!";
		my @files = readdir($DIR);

		foreach my $t (@files) {
			if ( -f "$mail_dir/$t" ) {
				print "\ncopying....";

				#Check with -f only for files (no directories)
				copy "$mail_dir/$t", "$tomcat_dir/$t";
			}
		}
		closedir($DIR);

		#-----End copy from mail to Tomcat Dir

		#----Start Delete files from mail dir

		opendir( DIR, $mail_dir ) or die $!;
		while ( my $file = readdir(DIR) ) {

			next unless ( -f "$mail_dir/$file" );

			next unless ( $file =~ m/\.html$/ );
			unlink $mail_dir . $file;
		}
		closedir(DIR);

		#----End Delete files form mail dir

		#----Start Delete from output directory
		opendir( DIR, $output_dir ) or die $!;
		while ( my $file = readdir(DIR) ) {

			next unless ( -f "$output_dir/$file" );

			next unless ( $file =~ m/\.html$/ );
			unlink $output_dir . $file;

		}
		closedir(DIR);

		#----End Delete from output dir

		#----Start delete from jtl dir

		opendir( DIR, $jtl_dir ) or die $!;
		while ( my $file = readdir(DIR) ) {

			next unless ( -f "$jtl_dir/$file" );
			print "\n Deleting JTL Dir...........";
			next unless ( $file =~ m/\.jtl$/ );
			unlink $jtl_dir . $file;

		}
		closedir(DIR);

		#----End delete from jtl dir

		$test_plan_count++;
	}

}
else {

	foreach $count ( @{ $data->{test} } ) {

		$command = "ant";

		my $flag = 0;
		while ( ( $key, $value ) = each($count) ) {
			if ( $flag == 6 ) {

			}
			else {
				@temp_csv_list[$flag] = $value;

			}
			print "\nInside first while";
			print "\n -D" . $key . "=" . $value;
			$command .= " -D" . $key . "=" . $value;
			$flag++;
		}

		print "!-------------\n";
		for ( $i = 0 ; $i < 6 ; $i++ ) {
			print $temp_csv_list[$i];
		}

		while ( ( $key, $value ) = each(%config_hash) ) {

			print "\nInside second while";
			print "\n -D" . $key . "=" . $value;
			$command .= " -D" . $key . "=" . $value;
		}
		print $command. "\n";
		print "\nwhen multiple test plans---";
		system "$command";
		print "\nSleep Started............";
		Time::HiRes::sleep($test_interval);
		print "\nSleep ended..............";

		#-----Start_Parse Html file
		my $att;
		my $count = 0;
		my $string1;
		my $string2;

		print "hello";
		opendir( DIR, $mail_dir ) or die $!;

		my $count = 0;
		while ( my $file = readdir(DIR) ) {

			next unless ( -f "$mail_dir/$file" );

			next unless ( $file =~ m/\.html$/ );

			$att->[$test_plan_count]->{file} = $mail_dir . $file;

			$tmpfile = "";
			open( FILE, $att->[$test_plan_count]->{file} )
			  || die "Unable to open file!\n";
			@file = <FILE>;
			foreach $line (@file) {
				$tmpfile = $tmpfile . $line;
			}
			$row_cnt = 0;
			$tables  = [];
			$te      = new HTML::TableExtract( depth => 0, count => 1 );
			$te->parse($tmpfile);
			foreach $ts ( $te->table_states ) {

				#  print "\nTable found at ", join(',', $ts->coords), ":\n";
				foreach $row ( $ts->rows ) {
					if ( $row_cnt == 1 ) {
						$tmp = join( ',', @$row );

						@tmp = split( ',', $tmp );
					}
					$row_cnt++;
				}
			}

			#$no_of_users[$test_plan_count]       = $tmp[0];
			$failure_rate[$test_plan_count]      = $tmp[1];
			$error_percentage[$test_plan_count]  = $tmp[2];
			$avg_response_time[$test_plan_count] = $tmp[3];
			$min_response_time[$test_plan_count] = $tmp[4];
			$max_response_time[$test_plan_count] = $tmp[5];

			closedir(DIR);

			#-----End_Parse Html file

			#-----Start Getting Url
			opendir( DIR, $mail_dir ) or die $!;

			while ( my $file = readdir(DIR) ) {

				next unless ( -f "$mail_dir/$file" );

				next unless ( $file =~ m/\.html$/ );
				$att->[$test_plan_count]->{file} = $dir . $file;
				print "$att->[$test_plan_count]->{file}\n";
				my $string4 = $tomcat_url . $file;
				$string4 =~ s/\s/%20/g;
				$url_list[$test_plan_count] = $string4;
				print "\n" . $url_list[$test_plan_count] . "\n";

			}
			closedir(DIR);

			$ramp_up_period[$test_plan_count] = $temp_csv_list[0];
			$test_plan_name[$test_plan_count] = $temp_csv_list[1];
			$no_of_users[$test_plan_count]    = $temp_csv_list[2];
			$no_of_loops[$test_plan_count]    = $temp_csv_list[3];
			$scenario_name[$test_plan_count]  = $temp_csv_list[5];

			print "\n--report--\n";
			print $scenario_name[$test_plan_count] . "\t";
			print $no_of_users[$test_plan_count] . "\t";
			print $ramp_up_period[$test_plan_count] . "\t";
			print $no_of_loops[$test_plan_count] . "\t";
			print $min_response_time[$test_plan_count] . "\t";
			print $max_response_time[$test_plan_count] . "\t";
			print $avg_response_time[$test_plan_count] . "\t";
			print $error_percentage[$test_plan_count] . "\t";
			print $failure_rate[$test_plan_count] . "\t";
			print $url_list[$test_plan_count] . "\n";

			#-----End Getting Data From CSV File

			#-----Start copy from mail dir to Tomcat Dir
			opendir( my $DIR, $mail_dir ) || die "can't opendir $mail_dir: $!";
			my @files = readdir($DIR);

			foreach my $t (@files) {
				if ( -f "$mail_dir/$t" ) {
					print "\ncopying....";

					#Check with -f only for files (no directories)
					copy "$mail_dir/$t", "$tomcat_dir/$t";
				}
			}
			closedir($DIR);

			#-----End copy from mail to Tomcat Dir

			#----Start Delete files from mail dir

			opendir( DIR, $mail_dir ) or die $!;
			while ( my $file = readdir(DIR) ) {

				next unless ( -f "$mail_dir/$file" );

				next unless ( $file =~ m/\.html$/ );
				unlink $mail_dir . $file;
			}
			closedir(DIR);

			#----End Delete files form mail dir

			#----Start Delete from output directory
			opendir( DIR, $output_dir ) or die $!;
			while ( my $file = readdir(DIR) ) {

				next unless ( -f "$output_dir/$file" );

				next unless ( $file =~ m/\.html$/ );
				unlink $output_dir . $file;

			}
			closedir(DIR);

			#----End Delete from output dir

			#----Start delete from jtl dir

			opendir( DIR, $jtl_dir ) or die $!;
			while ( my $file = readdir(DIR) ) {

				next unless ( -f "$jtl_dir/$file" );
				print "\n Deleting JTL Dir...........";
				next unless ( $file =~ m/\.jtl$/ );
				unlink $jtl_dir . $file;

			}
			closedir(DIR);

			#----End delete from jtl dir

			$test_plan_count++;
		}

	}
}

#----Start Generating the mail body contents
my $dt = DateTime->now;
print join ' ', $dt->ymd, $dt->hms;
my $timestamp = $dt->ymd . " " . $dt->hms;

$mail_body = "<head> <title> </title>
<meta name = viewport content = width = device-width,initial-scale =1.0 /> </head>
</html> 
 <body style = margin: 0;
padding: 0;> 
<table align = center border = 1 cellpadding = 0 cellspacing = 0 width =
  850> 
<tr>
<td align=center bgcolor=#70bbd9 style=padding: 40px 0 30px 0;>
<h2>"
  . $project_name
  . ": Server Side Performance Testing Report on "
  . $timestamp . "</h2>
</td> 
</tr>
<tr>
<td bgcolor=#ffffff>
<table border=1 cellpadding=0 cellspacing=0 width=100%>
<tr>
<td style=padding: 20px 0 30px 0;>
<h4>Team,
<br><br><br>
&nbsp;&nbsp;&nbsp;&nbsp;
This is a auto generated mail after <b>"
  . $project_name
  . "</b> server side performance testing completion. To generate this report Jmeter, Ant,
  Perl is used. This mail is sent to a testing team of a "
  . $project_name
  . ". For more information about testing result visit link of <a href =
  "
  . $tomcat_url
  . "> Result Server</a>. You can also compare previous Ui load testing reports at Result Server . 
<br> <br>
Thanks, 
 <br> 
" . $project_name . "
 -QA 
 </td>
</tr>
<tr>
<td>
<table border = 1 cellpadding = 0 cellspacing = 0 width = 100%> 
<tr><th>#</th> <th> Scenario Name </th> <th> No. of Users </th> <th>
  Ramp up period </th> <th> No of loops </th>
 <th> Min. Response Time </th> <th> Max. Response Time </th> <th> Avg. Response Time </th>
<th> Success % </th><th> Failures </th><th> More info. </th></tr>";

#-----
print "\n ................." . $count;
for ( $i = 0 ; $i < $test_plan_count ; $i = $i + 1 ) {
	$temp_index = $i + 1;
	$content_1  =
	    "<tr><td width=500 valign=top>"
	  . $temp_index
	  . "</td><td width=500 valign=top>"
	  . $scenario_name[$i]
	  . "</td><td width=500 valign=top>"
	  . $no_of_users[$i]
	  . "</td><td width=500 valign=top>"
	  . $ramp_up_period[$i]
	  . "</td><td width=500 valign=top>"
	  . $no_of_loops[$i]
	  . "</td><td width=500 valign=top>"
	  . $min_response_time[$i]
	  . "</td><td width=500 valign=top>"
	  . $max_response_time[$i]
	  . "</td><td width=500 valign=top>"
	  . $avg_response_time[$i]
	  . "</td><td width=500 valign=top>"
	  . $error_percentage[$i]
	  . "</td><td width=500 valign=top>"
	  . $failure_rate[$i]
	  . "</td> <td width = 500 valign =
	  top><a href=" . $url_list[$i] . ">Click here</a></td></tr>";

	$mail_body = $mail_body . $content_1;
}

$mail_body = $mail_body
  . "</table></td></tr></table></td></tr><tr><td bgcolor=#CCFFFF>Kindly submit your feedback. </td> </tr></table>";
print "-----------" . $mail_body . "-----------";

#----End Generating the mail body contents

$subject_line = "**"
  . $project_name
  . ": Server Side Performance Testing Report on "
  . $timestamp;
#---Email Configuration----
my $mail = Email::Send::SMTP::Gmail->new(
	-smtp  => 'smtp.gmail.com',
	-login => $from_email,
	-pass  => $from_password
);

#---End Email Configuration----

$mail->send(
	-to          => join( ",", @to_mail_list ),
	-subject     => $subject_line,
	-body        => $mail_body,
	-contenttype => 'text/html '
);
$mail->bye;

