# This is a script for when we are patching to disable the servers in nagios
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services disable drive-web1.novalocal all 28800 kerins Upgrade
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services disable drive-web2.novalocal all 28800 kerins Upgrade
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services disable drive-web3.novalocal all 28800 kerins Upgrade
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services disable drive-web4.novalocal all 28800 kerins Upgrade

ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services disable drive-sync1.novalocal all 28800 kerins Upgrade
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services disable drive-sync2.novalocal all 28800 kerins Upgrade
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services disable drive-sync3.novalocal all 28800 kerins Upgrade
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services disable drive-sync4.novalocal all 28800 kerins Upgrade

ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services disable drive-db1.novalocal all 28800 kerins Upgrade
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services disable drive-db2.novalocal all 28800 kerins Upgrade
ssh monitor@monitoring.switch.ch /omd/sites/monitor/local/bin/nagios-services disable drive-db3.novalocal all 28800 kerins Upgrade
