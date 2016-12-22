package Collectd::Plugins::LDAP;

# https://collectd.org/documentation/manpages/collectd-perl.5.shtml

use strict;
use warnings;

use Net::LDAP;
use Collectd qw( :all );
use Sys::Syslog qw(:standard :macros);

my $PLUGIN_NAME = 'ldap';


my %config = ();
#openlog("collectd-perl", "", LOG_LOCAL0);

sub ldap_config {
    my @config = @{ $_[0]->{children} };
    foreach my $item (@config) {
        my $key = lc ($item->{key});
        my $value = @{$item->{'values'}}[0];
        $config{$key} = $value;
        #syslog("info", $key."->".$value);
    }
}

sub bindToLdap {
   my($ldap);

   if (!($ldap = new Net::LDAP($config{'ip'}, 'port'=> $config{'port'}, 'onerror' => 'warn'))) {
      $@ = "Failed to create socket to $config{'ip'}:$config{'port'}: Perl error:  $@";
      return 0;
   };

   if (!($ldap->bind(
               $config{'user'},
               "password" => $config{'password'},
               "version"  => 3
   ))) {
      $@ = "Failed to bind to LDAP server: Perl error: $@";
      return 0;
   }
   return $ldap;
}

sub getMonitor {
   my($ldap, $dn, $attr, $statname, $stattype) = @_;
   my($searchResults, $entry);

   $searchResults = $ldap->search('base'   => $dn,
                                  'scope'  => 'base',
                                  'filter' => "(objectClass=*)",
                                  'attrs'  => [$attr]
                                  );

   $entry = $searchResults->pop_entry() if $searchResults->count() == 1;

    my $valueList = { 
        'plugin' => 'ldap', 
        'type' => $stattype,
        'type_instance' => $statname
         };
    $valueList->{'values'} = [ $entry->get_value($attr) ];
    plugin_dispatch_values ($valueList);
    return 1;

}

sub getStats {
   my ($ldap) = @_;

   getMonitor($ldap, "cn=Total,cn=Connections,cn=Monitor",     "monitorCounter",     "total_connections",    'counter');
   
   getMonitor($ldap, "cn=Bytes,cn=Statistics,cn=Monitor",      "monitorCounter",     "sent_bytes",           'counter');
   getMonitor($ldap, "cn=PDU,cn=Statistics,cn=Monitor",        "monitorCounter",     "sent_pdus",            'counter');
   getMonitor($ldap, "cn=Referrals,cn=Statistics,cn=Monitor",  "monitorCounter",     "sent_referrals",       'counter');
   getMonitor($ldap, "cn=Entries,cn=Statistics,cn=Monitor",    "monitorCounter",     "sent_entries",         'counter');
   
   getMonitor($ldap, "cn=Operations,cn=Monitor",               "monitorOpCompleted", "operations_completed", 'counter');
   getMonitor($ldap, "cn=Operations,cn=Monitor",               "monitorOpInitiated", "operations_initiated", 'counter');
   #getMonitor($ldap, "cn=Modrdn,cn=Operations,cn=Monitor",     "monitorOpInitiated", "",                     'counter');
   #getMonitor($ldap, "cn=Modrdn,cn=Operations,cn=Monitor",     "monitorOpCompleted", "",                     'counter');
   #getMonitor($ldap, "cn=Abandon,cn=Operations,cn=Monitor",    "monitorOpInitiated", "",                     'counter');
   #getMonitor($ldap, "cn=Abandon,cn=Operations,cn=Monitor",    "monitorOpCompleted", "",                     'counter');
   #getMonitor($ldap, "cn=Extended,cn=Operations,cn=Monitor",   "monitorOpInitiated", "",                     'counter');
   #getMonitor($ldap, "cn=Extended,cn=Operations,cn=Monitor",   "monitorOpCompleted", "",                     'counter');
   
   
   getMonitor($ldap, "cn=Bind,cn=Operations,cn=Monitor",       "monitorOpCompleted", "operations_bind",       'counter');
   getMonitor($ldap, "cn=Unbind,cn=Operations,cn=Monitor",     "monitorOpCompleted", "operations_unbind",     'counter');
   
   getMonitor($ldap, "cn=Add,cn=Operations,cn=Monitor",        "monitorOpInitiated", "operations_add",        'counter');
   getMonitor($ldap, "cn=Delete,cn=Operations,cn=Monitor",     "monitorOpCompleted", "operations_delete",     'counter');
   getMonitor($ldap, "cn=Modify,cn=Operations,cn=Monitor",     "monitorOpCompleted", "operations_modify",     'counter');
   getMonitor($ldap, "cn=Compare,cn=Operations,cn=Monitor",    "monitorOpCompleted", "operations_compare",    'counter');
   getMonitor($ldap, "cn=Search,cn=Operations,cn=Monitor",     "monitorOpCompleted", "operations_search",     'counter');
   getMonitor($ldap, "cn=Write,cn=Waiters,cn=Monitor",         "monitorCounter",     "waiters_write",         'gauge');
   getMonitor($ldap, "cn=Read,cn=Waiters,cn=Monitor",          "monitorCounter",     "waiters_read",          'gauge');

   getMonitor($ldap, "cn=Max,cn=Threads,cn=Monitor",           "monitoredInfo",      "threads_max_configured",'gauge');
   getMonitor($ldap, "cn=Max Pending,cn=Threads,cn=Monitor",   "monitoredInfo",      "threads_max_pending",   'gauge');
   getMonitor($ldap, "cn=Open,cn=Threads,cn=Monitor",          "monitoredInfo",      "threads_open",          'gauge');
   getMonitor($ldap, "cn=Starting,cn=Threads,cn=Monitor",      "monitoredInfo",      "threads_starting",      'gauge');
   getMonitor($ldap, "cn=Active,cn=Threads,cn=Monitor",        "monitoredInfo",      "threads_active",        'gauge');
   getMonitor($ldap, "cn=Pending,cn=Threads,cn=Monitor",       "monitoredInfo",      "threads_pending",       'gauge');
   getMonitor($ldap, "cn=Backload,cn=Threads,cn=Monitor",      "monitoredInfo",      "threads_backload",      'gauge');

   #getMonitor($ldap, "cn=Start,cn=Time,cn=Monitor",            "monitorTimestamp",   "",                      'counter');
   #getMonitor($ldap, "cn=Current,cn=Time,cn=Monitor",          "monitorTimestamp",   "",                      'counter');
   getMonitor($ldap, "cn=Uptime,cn=Time,cn=Monitor",           "monitoredInfo",      "uptime",                'gauge');

}


sub ldap_read {
   my $ldap = bindToLdap();
   if ($ldap) {
      getStats($ldap);
      return 1;
   } else {
       return 0;
   }
}


plugin_register (TYPE_CONFIG, "LDAP", "ldap_config");
plugin_register (TYPE_READ, $PLUGIN_NAME, "ldap_read");

1;

__END__



