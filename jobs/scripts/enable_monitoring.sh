# This is a script for when we are patching to disable the servers in nagios
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services enable drive-web1.novalocal all
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services enable drive-web2.novalocal all
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services enable drive-web3.novalocal all
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services enable drive-web4.novalocal all

ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services enable drive-sync1.novalocal all
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services enable drive-sync2.novalocal all
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services enable drive-sync3.novalocal all
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services enable drive-sync4.novalocal all

ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services enable drive-db1.novalocal all
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services enable drive-db2.novalocal all
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services enable drive-db3.novalocal all
