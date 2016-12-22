#!/usr/bin/env perl

        my $logfile = "/home/ubuntu/log/t1-2015.05.06-17:27.delete";

        my @lines = `/bin/egrep "FINISHED WITH STATUS" $logfile`;
        chomp(@lines);
        my $status = 0;
        foreach my $line (@lines) {
            print $line, "\n";
            $line =~ s/.*FINISHED WITH STATUS *//;
            print $line, "\n";
            $line =~ s/ .*//;
            print $line, "\n";
            $status = $status + $line;
        }
        my $ok = ($status == 0);
        print "status: ", $status > 0, " ", "'$status'",  "\n";
        
        
         if ($ok) {
            print "ok\n";
        } else {
                       print "nok\n";
            
        }
        
        
        
        
        
        my $logfile = "/home/ubuntu/log/t1-2015.05.06-17:48.upload";

        my @lines = `/bin/egrep "FINISHED WITH STATUS" $logfile`;
        chomp(@lines);
        my $status = 0;
        foreach my $line (@lines) {
            print $line, "\n";
            $line =~ s/.*FINISHED WITH STATUS *//;
            print $line, "\n";
            $line =~ s/ .*//;
            print $line, "\n";
            $status = $status + $line;
        }
        my $ok = ($status == 0);
        print "status: ", $status > 0, " ", "'$status'",  "\n";
        if ($ok) {
        	print "ok\n";
        } else {
        	           print "nok\n";
        	
        }
    my $synctime = `/bin/egrep "^CSync run took" $logfile`;
    chomp($synctime);
    $synctime =~ s/ *$//;
    $synctime =~ s/.* //;
    my $ok = $synctime ne '';
    
    print "synctime: $synctime\n";
    print $ok , "\n";
        
        