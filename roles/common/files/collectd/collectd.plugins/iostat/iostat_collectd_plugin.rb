#!/usr/bin/ruby
#
# iostat_collectd_plugin.rb
#
# This is a collectd plugin that calls iostat infinately every second.
# For each block device line, it uses ruby regex to reformat the required fields
# as required for collectd Exec plugins, of which it can then be graphed using one
# of the collectd write plugins, such as write graphite.
#
# Please see https://github.com/keirans/collectd-iostat/ for full details.
#
# A couple of notes about the format of the output that the collectd plugin requires:
#
# Collectd's exec plugin uses the plain text protocol to push data into collectd
# * Lines must begin with PUTVAL
# * The identifier string must contain a valid type reference that allows collectd
#   to be aware of the data type that is being provided.
#   In the case of this plugin we are using the gauge type, which is suitable for
#   positive and negative numbers.
# * The value we want to graph is printed in the N:<value> format. The N translates
#   to epoch time within collectd, followed by a colon and the value.
# * The iostat command runs with the _-Nxk_ options, as such,  all statistics are displayed
#   in kilobytes per second instead of blocks per second.
#   Don't forget this when you are building graphs and visualising your data.
#
# We trap the exit signal and then have it clean up all the children processes of the
# plugin. If we dont do this, we have orphaned iostat processes floating around on the server
# after a collectd restart. This isnt ideal.
#
# The plugin should run as nobody via the following exec plugin stanza
#
# <Plugin exec>
#    Exec "nobody" "/var/tmp/iostat_collectd_plugin.sh"
# </Plugin>
#
# Keiran S <Keiran@gmail.com>
#
# C. Schnidrig
# adapted for Ubuntu 14.04

trap("TERM") {cleanup_children_on_exit}

def cleanup_children_on_exit
    puts "Killing child process: " + @output.pid.to_s
    Process.kill("KILL", @output.pid)
    abort("Caught TERM exiting")
end

HOSTNAME=ENV['COLLECTD_HOSTNAME']
INTERVAL=ENV['COLLECTD_INTERVAL']

PLUGINNAME = "iostat"

# Enable auto flush
 STDOUT.sync = true

@output = IO.popen("iostat -Nxk " +INTERVAL)
    while line = @output.gets do
        if  ( line !~ /^(Linux|Time:|avg-cpu|Device| |$)/ )
            device, rrqm_sec,  wrqm_sec, r_s, w_s, rkB_sec, wkB_sec, avgrq_sz, avgqu_sz, await, r_await, w_await, svctm, util = line.split
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-rrqm " + "interval=" + INTERVAL + " N:" + rrqm_sec
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-wrqm " + "interval=" + INTERVAL + " N:" + wrqm_sec
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-rs " + "interval=" + INTERVAL + " N:" + r_s
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-ws " + "interval=" + INTERVAL + " N:" + w_s
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-rkB " + "interval=" + INTERVAL + " N:" + rkB_sec
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-wkB " + "interval=" + INTERVAL + " N:" + wkB_sec
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-avgrqsz " + "interval=" + INTERVAL + " N:" + avgrq_sz
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-avgqusz " + "interval=" + INTERVAL + " N:" + avgqu_sz
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-await " + "interval=" + INTERVAL + " N:" + await
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-rawait " + "interval=" + INTERVAL + " N:" + r_await
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-wawait " + "interval=" + INTERVAL + " N:" + w_await
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-svctm " + "interval=" + INTERVAL + " N:" + svctm
            puts "PUTVAL " + HOSTNAME.chomp + "/" + PLUGINNAME + "-" + device + "/gauge-util " + "interval=" + INTERVAL + " N:" + util
        end
    end
