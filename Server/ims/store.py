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
Data store
"""

__all__ = [
    "Storage",
]

from hashlib import sha1 as etag_hash

from twisted.python import log



class Storage(object):
    """
    Back-end storage
    """

    def __init__(self, path):
        self.path = path
        self.incidents = {}


    def provision(self):
        if hasattr(self, "_max_incident_number"):
            return

        if not self.path.exists():
            log.msg(
                "Creating storage directory: {}"
                .format(self.path)
            )
            self.path.createDirectory()
            self.path.restat()

        if not self.path.isdir():
            raise StorageError(
                "Storage location must be a directory: {}"
                .format(self.path)
            )

        max = 0
        for number in self.list_incidents():
            if number > max:
                max = number
        self._max_incident_number = max


    def _open_incident(self, number, mode):
        incident_fp = self.path.child(str(number))
        incident_fh = incident_fp.open(mode)
        return incident_fh


    def list_incidents(self):
        for child in self.path.children():
            name = child.basename()
            try:
                number = int(name)
            except ValueError as e:
                log.err(
                    "Invalid filename in data store: {}"
                    .format(name)
                )
                continue

            yield (number, self.etag_for_incident_with_number(number))


    def etag_for_incident_with_number(self, number):
        data = self.read_incident_with_number_raw(number)
        return etag_hash(data).hexdigest()


    def read_incident_with_number_raw(self, number):
        handle = self._open_incident(number, "r")
        try:
            json = handle.read()
        finally:
            handle.close()
        return json


    def read_incident_with_number(self, number):
        json = self.read_incident_with_number_raw(number)
        return Incident.from_json(json)


    def write_incident(self, incident):
        incident.validate()

        self.provision()

        number = incident.number

        incident_fh = self._open_incident(number, "w")
        try:
            incident_fh.write(incident.as_json())
        finally:
            incident_fh.close()

        self.incidents[number] = incident

        if number > self._max_incident_number:
            self._max_incident_number = number


    def next_incident_number(self):
        self.provision()
        self._max_incident_number += 1
        return self._max_incident_number
