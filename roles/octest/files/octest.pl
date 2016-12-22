#!/usr/bin/env perl

use strict;
use warnings;
use POSIX;

my $user           = "t1";
my $passwd         = "oct1";
my $ocUrl          = "https://drive.switch.ch/";
my $rootdir        = "/home/ubuntu";
my $logdir         = "$rootdir/log/$user";
my $occmd          = "/usr/bin/owncloudcmd";
my $sync_dir       = "$rootdir/t1";
my $testdata       = "$rootdir/testdata.tar";
my $graphite_sever = "10.0.24.6 2003";
my $hostname       = `hostname`;
chomp($hostname);
$hostname =~ s/.*-//;

sub runOcTest {
	my ($action) = @_;

	# setup data
	if ( $action eq "upload" ) {
		`/bin/tar -xf $testdata -C $sync_dir`;
	}
	elsif ( $action eq "delete" ) {
		`/bin/rm -rf $sync_dir/*`;
	}
	elsif ( $action eq "download" ) {
		`/bin/rm -rf $sync_dir/.csync*`;
		`/bin/rm -rf $sync_dir/*`;
	}

	my $ok            = 0;
	my $retry_counter = 0;
	my $total_time    = 0;
	while ( !$ok ) {

		# generate log file name
		my $timestring = POSIX::strftime( "%Y.%m.%d-%H:%M", localtime() );
		my $logfile = $logdir . "-" . $timestring . "." . $action;

		# run owncloud sync
		my $cmd =
		    $occmd . " -u " 
		  . $user . " -p " 
		  . $passwd . " "
		  . $sync_dir . " "
		  . $ocUrl . " > "
		  . $logfile . " 2>&1";
		print $cmd. "\n";
		my $start = time();
		`$cmd`;
		my $duration = time() - $start;

		# log dir state
		`find $sync_dir > $logfile.files 2>&1`;

		# fetch duration
		my $synctime = `/bin/egrep "^CSync run took" $logfile`;
		chomp($synctime);
		$synctime =~ s/ *$//;
		$synctime =~ s/.* //;
		$ok = $synctime ne '';

		if ($ok) {
			$duration = $synctime;
		}
		else {
			$duration = $duration * 1000;
		}
		$total_time = $duration + $total_time;

		# check that status is ok
		if ($ok) {
			my @lines = `/bin/egrep "FINISHED WITH STATUS" $logfile`;
			chomp(@lines);
			my $status = 0;
			foreach my $line (@lines) {
				$line =~ s/.*FINISHED WITH STATUS *//;
				$line =~ s/ .*//;
				$status = $status + $line;
			}
			$ok = $status == 0;
		}
        if ($ok) {
            my @lines = `/bin/egrep "INSTRUCTION_ERROR" $logfile`;
            $ok = scalar(@lines) == 0;
            if ( !$ok ) {
                # workaround bugs
                `/bin/rm -rf $sync_dir/.csync*`;
            }
        }
        if ($ok) {
            my @lines = `/bin/egrep "Internal Server Error"`;
            $ok = scalar(@lines) == 0;
        }

		# generate counter name
		my $countername;
		if ($ok) {
			$countername = $action;
			if ($retry_counter) {
				$duration = $total_time;
			}
		}
		else {
			$countername = $action . "_failed";
			if ( !$retry_counter ) {
				$retry_counter++;
				$action = $action . "_retry";
			}
		}

		# post data to graphite
		my $datastr =
		    $hostname
		  . ".octest."
		  . $user . "."
		  . $countername . " "
		  . $duration . " "
		  . $start;
		print $datastr. "\n";
		$cmd = "echo $datastr | /bin/nc $graphite_sever";
		print $cmd. "\n";
		`$cmd`;
	}
}

while (1) {
	runOcTest("upload");

	#	runOcTest("sync");
	runOcTest("download");

	#    runOcTest("sync");
	runOcTest("delete");
}

__END__

