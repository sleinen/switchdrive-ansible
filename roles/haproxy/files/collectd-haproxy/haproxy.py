#!/usr/bin/env python
# haproxy-collectd-plugin - haproxy.py
#
# Author: Michael Leinartas
# Description: This is a collectd plugin which runs under the Python plugin to
# collect metrics from haproxy.
# Plugin structure and logging func taken from https://github.com/phrawzty/rabbitmq-collectd-plugin

# https://github.com/feraudet/collectd-haproxy/commit/262728e9fecc22c55fc7d25b3324131cd646b619

import socket
import csv
if __name__ != "__main__":
    import collectd
else:
    import sys
    from datetime import datetime
    class Collectd:
        """Proxy class """

        def __init__(self):
            self.values = []
            self.config = None
            self.init = None
            self.read = None

        def register_config(self, function):
            self.config = function

        def register_init(self, function):
            self.init = function

        def register_read(self, function):
            self.read = function

        def Values(self, **args):
            return Values(**args)

        def error(self, msg):
            print("ERROR: " + msg)

        def warning(self, msg):
            print("WARNING: " + msg)

        def info(self, msg):
            print("INFO: " + msg)

    class Configuration:
        """Proxy configuration class"""
        def __init__(self, args):
            self.children = [];
            args.pop(0)
            for arg in args:
                if "=" not in arg:
                    logger('err', 'Invalid argument, must be like key=val')
                else:
                    self.children.append(Node({arg.split("=")[0]: arg.split("=")[1]}))

    class Node:
        """Proxy node class for configuration"""
        def __init__(self, entry):
            self.key = entry.keys()[0]
            self.values = entry.values()

    class Values:
        def __init__(self, **kwargs):
            self.host = kwargs.get('host', socket.getfqdn())
            self.plugin = kwargs.get('plugin', NAME)
            self.plugin_instance = kwargs.get('plugin_instance', '')
            self.type = kwargs.get('type')
            self.type_instance = kwargs.get('type_instance', '')
            self.time = datetime.utcnow()
            self.values = []

        def __str__(self):
            if self.plugin_instance:
                self.plugin_instance = "-" + self.plugin_instance
            if self.type_instance:
                self.type_instance = "-" + self.type_instance
            return "%s: %s/%s%s/%s%s = %s" % (
                self.time,
                self.host,
                self.plugin,
                self.plugin_instance,
                self.type,
                self.type_instance,
                self.values)

        def dispatch(self):
            print(self)


NAME = 'haproxy'
RECV_SIZE = 1024
METRIC_TYPES = {
  'bin': ('bytes_in', 'derive'),
  'bout': ('bytes_out', 'derive'),
  'chkfail': ('failed_checks', 'counter'),
  'CurrConns': ('connections', 'gauge'),
  'downtime': ('downtime', 'counter'),
  'dresp': ('denied_response', 'derive'),
  'dreq': ('denied_request', 'derive'),
  'econ': ('error_connection', 'derive'),
  'ereq': ('error_request', 'derive'),
  'eresp': ('error_response', 'derive'),
  'hrsp_1xx': ('response_1xx', 'derive'),
  'hrsp_2xx': ('response_2xx', 'derive'),
  'hrsp_3xx': ('response_3xx', 'derive'),
  'hrsp_4xx': ('response_4xx', 'derive'),
  'hrsp_5xx': ('response_5xx', 'derive'),
  'hrsp_other': ('response_other', 'derive'),
  'PipesUsed': ('pipes_used', 'gauge'),
  'PipesFree': ('pipes_free', 'gauge'),
  'qcur': ('queue_current', 'gauge'),
  'Tasks': ('tasks', 'gauge'),
  'Run_queue': ('run_queue', 'gauge'),
  'rate': ('session_rate', 'gauge'),
  'req_rate': ('request_rate', 'gauge'),
  'stot': ('connection_total', 'counter'),
  'scur': ('session_current', 'gauge'),
  'wredis': ('redistributed', 'derive'),
  'wretr': ('retries', 'counter'),
  'act': ('active_server', 'gauge'),
  'bck': ('backup_server', 'gauge'),
  'qtime': ('average_queue_time', 'gauge'),
  'ctime': ('average_connect_time', 'gauge'),
  'rtime': ('average_response_time', 'gauge'),
  'ttime': ('average_total_session_time', 'gauge'),
  'Uptime_sec': ('uptime_seconds', 'gauge')
}

METRIC_DELIM = '.' # for the frontend/backend stats

DEFAULT_SOCKET = '/var/lib/haproxy/stats'
DEFAULT_PROXY_MONITORS = [ 'server', 'frontend', 'backend' ]
VERBOSE_LOGGING = False

class HAProxySocket(object):
  def __init__(self, socket_file=DEFAULT_SOCKET):
    self.socket_file = socket_file

  def connect(self):
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(self.socket_file)
    return s

  def communicate(self, command):
    ''' Send a single command to the socket and return a single response (raw string) '''
    s = self.connect()
    if not command.endswith('\n'): command += '\n'
    s.send(command)
    result = ''
    buf = ''
    buf = s.recv(RECV_SIZE)
    while buf:
      result += buf
      buf = s.recv(RECV_SIZE)
    s.close()
    return result

  def get_server_info(self):
    result = {}
    output = self.communicate('show info')
    for line in output.splitlines():
      try:
        key,val = line.split(':')
      except ValueError, e:
        continue
      result[key.strip()] = val.strip()
    return result

  def get_server_stats(self):
    output = self.communicate('show stat')
    #sanitize and make a list of lines
    output = output.lstrip('# ').strip()
    output = [ l.strip(',') for l in output.splitlines() ]
    csvreader = csv.DictReader(output)
    result = [ d.copy() for d in csvreader ]
    return result

def get_stats():
  stats = dict()
  haproxy = HAProxySocket(HAPROXY_SOCKET)

  try:
    server_info = haproxy.get_server_info()
    server_stats = haproxy.get_server_stats()
  except socket.error, e:
    logger('warn', "status err Unable to connect to HAProxy socket at %s" % HAPROXY_SOCKET)
    return stats

  if 'server' in PROXY_MONITORS:
    for key,val in server_info.items():
      try:
        stats[key] = int(val)
      except (TypeError, ValueError), e:
        pass

  for statdict in server_stats:
    if not (statdict['svname'].lower() in PROXY_MONITORS or statdict['pxname'].lower() in PROXY_MONITORS):
      continue
    if statdict['pxname'] in PROXY_IGNORE:
      continue
    for key,val in statdict.items():
      metricname = METRIC_DELIM.join([ statdict['svname'].lower(), statdict['pxname'].lower(), key ])
      try:
        stats[metricname] = int(val)
      except (TypeError, ValueError), e:
        pass
  return stats

def configure_callback(conf):
  global PROXY_MONITORS, PROXY_IGNORE, HAPROXY_SOCKET, VERBOSE_LOGGING, USE_PLUGIN_INSTANCE, NAME
  PROXY_MONITORS = [ ]
  PROXY_IGNORE = [ ]
  HAPROXY_SOCKET = DEFAULT_SOCKET
  VERBOSE_LOGGING = False
  USE_PLUGIN_INSTANCE = False

  for node in conf.children:
    if node.key == "ProxyMonitor":
      PROXY_MONITORS.append(node.values[0])
    elif node.key == "ProxyIgnore":
      PROXY_IGNORE.append(node.values[0])
    elif node.key == "Socket":
      HAPROXY_SOCKET = node.values[0]
    elif node.key == "UsePluginInstance":
      USE_PLUGIN_INSTANCE = bool(node.values[0])
    elif node.key == "Plugin":
      NAME = node.values[0]
    elif node.key == "Verbose":
      VERBOSE_LOGGING = bool(node.values[0])
    else:
      logger('warn', 'Unknown config key: %s' % node.key)

  if not PROXY_MONITORS:
    PROXY_MONITORS += DEFAULT_PROXY_MONITORS
  PROXY_MONITORS = [ p.lower() for p in PROXY_MONITORS ]

def read_callback():
  logger('verb', "beginning read_callback")
  info = get_stats()

  if not info:
    logger('warn', "%s: No data received" % NAME)
    return

  for key,value in info.items():
    key_prefix = ''
    key_root = key
    if not value in METRIC_TYPES:
      try:
        key_prefix, key_root = key.rsplit(METRIC_DELIM,1)
      except ValueError, e:
        pass
    if not key_root in METRIC_TYPES:
      continue

    key_root, val_type = METRIC_TYPES[key_root]
    plugin_instance = ""
    if USE_PLUGIN_INSTANCE:
        plugin_instance = key_prefix
        key_name = key_root
    elif not key_prefix:
        key_name = key_root
    else:
        key_name = METRIC_DELIM.join([key_prefix, key_root])
    val = collectd.Values(plugin=NAME, plugin_instance=plugin_instance, type=val_type)
    val.type_instance = key_name
    val.values = [ value ]
    val.dispatch()

def logger(t, msg):
    if t == 'err':
        collectd.error('%s: %s' % (NAME, msg))
    elif t == 'warn':
        collectd.warning('%s: %s' % (NAME, msg))
    elif t == 'verb':
        if VERBOSE_LOGGING:
            collectd.info('%s: %s' % (NAME, msg))
    else:
        collectd.notice('%s: %s' % (NAME, msg))

if __name__ == "__main__":
    collectd = Collectd()
    conf = Configuration(sys.argv)
    collectd.register_config(configure_callback)
    collectd.register_read(read_callback)
    collectd.config(conf)
    collectd.read()
else:
    collectd.register_config(configure_callback)
    collectd.register_read(read_callback)
