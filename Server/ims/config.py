##
# See the file COPYRIGHT for copyright information.
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##

"""
Server
"""

__all__ = [
    "Configuration",
]

import os.path

from ConfigParser import SafeConfigParser, NoSectionError, NoOptionError

from twisted.python import log
from twisted.python.filepath import FilePath



class Configuration (object):
    def __init__(self, configFile):
        self.configFile = configFile
        self.load()


    def __str__(self):
        return (
            "Core.ServerRoot: {ServerRoot}\n"
            "Core.ConfigRoot: {ConfigRoot}\n"
            "Core.UserDB: {UserDB}\n"
            "Core.DataRoot: {DataRoot}\n"
            "Core.Resources: {Resources}\n"
            "\n"
            "DMS.Hostname: {DMSHost}\n"
            "DMS.Database: {DMSDatabase}\n"
            "DMS.Username: {DMSUsername}\n"
            "DMS.Password: {DMSPassword}\n"
        ).format(**self.__dict__)


    def load(self):
        configParser = SafeConfigParser()

        def readConfig(configFile):
            for okFile in configParser.read((configFile.path,)):
                log.msg("Read configuration file: {0}".format(configFile.path))

        def valueFromConfig(section, option, default):
            try:
                value = configParser.get(section, option)
                if value:
                    return value
                else:
                    return default
            except (NoSectionError, NoOptionError):
                return default

        def filePathFromConfig(section, option, root, segments):
            if section is None:
                path = None
            else:
                path = valueFromConfig(section, option, None)

            if path is None:
                fp = root
                for segment in segments: 
                    fp = fp.child(segment)

            elif path.startswith("/"):
                fp = FilePath(path)

            else:
                fp = root
                for segment in path.split(os.path.sep):
                    fp = fp.child(segment)

            return fp

        readConfig(self.configFile)

        self.ServerRoot = filePathFromConfig(
            "Core", "ServerRoot",
            self.configFile.parent().parent(), ()
        )
        log.msg("Server root: {0}".format(self.ServerRoot.path))

        self.ConfigRoot = filePathFromConfig("Core", "ConfigRoot", self.ServerRoot, ("conf",))
        log.msg("Config root: {0}".format(self.ConfigRoot.path))

        self.UserDB = filePathFromConfig("Core", "UserDB", self.ConfigRoot, ("users.pwdb",))
        log.msg("User DB: {0}".format(self.UserDB.path))

        self.DataRoot = filePathFromConfig("Core", "DataRoot", self.ServerRoot, ("data",))
        log.msg("Data root: {0}".format(self.DataRoot.path))

        self.Resources = filePathFromConfig("Core", "Resources", self.ServerRoot, ("resources",))
        log.msg("Resources: {0}".format(self.Resources.path))

        self.DMSHost     = valueFromConfig("DMS", "Hostname", None)
        self.DMSDatabase = valueFromConfig("DMS", "Database", None)
        self.DMSUsername = valueFromConfig("DMS", "Username", None)
        self.DMSPassword = valueFromConfig("DMS", "Password", None)
