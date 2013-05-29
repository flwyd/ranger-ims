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
    "Resource",
]

if __name__ == "__main__":
    import sys
    import os
    sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from twisted.python.filepath import FilePath
from twisted.cred.checkers import FilePasswordDB

from ims.config import Configuration
from ims.auth import guard
from ims.dms import DutyManagementSystem
from ims.protocol import IncidentManagementSystem



# FIXME: Is this janky?  It feels janky.
class GlobalState(object):
    @property
    def config(self):
        if not hasattr(self, "_config"):
            configFile = FilePath(__file__).parent().parent().child("conf").child("imsd.conf")
            self._config = Configuration(configFile)
        return self._config


    @property
    def dms(self):
        if not hasattr(self, "_dms"):
            self._dms = DutyManagementSystem(
                host     = self.config.DMSHost,
                database = self.config.DMSDatabase,
                username = self.config.DMSUsername,
                password = self.config.DMSPassword,
            )
        return self._dms


TheGlobalState = GlobalState()



def Resource():
    return guard(
        lambda: IncidentManagementSystem(TheGlobalState.config.DataRoot, TheGlobalState.dms),
        "Ranger Incident Management System",
        (
            FilePasswordDB(TheGlobalState.config.UserDB.path),
        ),
    )
