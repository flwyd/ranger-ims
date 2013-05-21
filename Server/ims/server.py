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
]

if __name__ == "__main__":
    import sys
    import os
    sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from ConfigParser import SafeConfigParser, NoSectionError, NoOptionError

from twisted.python import log
from twisted.python.filepath import FilePath
from twisted.cred.checkers import FilePasswordDB

from ims.auth import guard
from ims.protocol import IncidentManagementSystem



def Resource():
    configParser = SafeConfigParser()

    def readConfig(configFile):
        for okFile in configParser.read((configFile.path,)):
            log.msg("Read configuration file: {0}".format(configFile.path))

    def filePathFromConfig(section, option, root, segments):
        if section is None:
            path = None
        else:
            try:
                path = configParser.get(section, option)
            except (NoSectionError, NoOptionError):
                path = None

        if path is None:
            fp = root
            for segment in segments:
                fp = fp.child(segment)
        else:
            fp = FilePath(path)

        return fp

    class Config(object):
        pass

    config = Config()

    config.ServerRoot = FilePath(__file__).parent().parent()
    readConfig(config.ServerRoot.child("conf").child("imsd.conf"))

    config.ServerRoot = filePathFromConfig(None, None, config.ServerRoot, ())
    log.msg("Server root: {0}".format(config.ServerRoot.path))

    config.ConfigRoot = filePathFromConfig("Core", "ConfigRoot", config.ServerRoot, ("conf",))
    readConfig(config.ConfigRoot.child("imsd.conf"))

    config.UserDB = filePathFromConfig("Core", "UserDB", config.ConfigRoot, ("users.pwdb",))

    config.DataRoot = filePathFromConfig("Core", "DataRoot", config.ServerRoot, ("data",))
    
    return guard(
        lambda: IncidentManagementSystem(config.DataRoot),
        "Ranger Incident Management System",
        (
            FilePasswordDB(config.UserDB.path),
        ),
    )
