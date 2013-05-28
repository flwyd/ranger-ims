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
from ims.protocol import IncidentManagementSystem



def Resource():
    configFile = FilePath(__file__).parent().parent().child("conf").child("imsd.conf")
    config = Configuration(configFile)
    
    return guard(
        lambda: IncidentManagementSystem(config.DataRoot),
        "Ranger Incident Management System",
        (
            FilePasswordDB(config.UserDB.path),
        ),
    )
