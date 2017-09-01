#!/usr/bin/env python

import manageUserDirs

import unittest
from unittest.mock import MagicMock

#########################################
# constants

configuration_file = "./manageUserDirs.yml.j2"
cache_file = "./manageUserDirs.cache.yml.j2"

#########################################
class OpenstackTest(unittest.TestCase):

    def testSnapshotCreateFailure(self):
        config = manageUserDirs.Config(configuration_file)
        os = manageUserDirs.Openstack(config.getOSConfig()).run()
        #self.assertEqual('foo'.upper(), 'FOO')
        pass



#########################################
# main
def main():
    unittest.main()

if __name__ == '__main__':
    main()

