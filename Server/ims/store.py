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
from ims.data import Incident



class StorageError(RuntimeError):
    """
    Storage error.
    """



class NoSuchIncidentError(StorageError):
    """
    No such incident.
    """



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
                "Creating storage directory: {0}"
                .format(self.path)
            )
            self.path.createDirectory()
            self.path.restat()

        if not self.path.isdir():
            raise StorageError(
                "Storage location must be a directory: {0}"
                .format(self.path)
            )

        max = 0
        for number, etag in self.list_incidents():
            if number > max:
                max = number
        self._max_incident_number = max


    def _incident_fp(self, number, ext=""):
        if ext:
            ext    = ".{0}".format(ext)
            prefix = "."
        else:
            ext    = ""
            prefix = ""

        return self.path.child("{0}{1}{2}".format(prefix, number, ext))


    def _open_incident(self, number, mode):
        incident_fp = self._incident_fp(number)
        try:
            incident_fh = incident_fp.open(mode)
        except (IOError, OSError):
            raise NoSuchIncidentError(number)
        return incident_fh


    def list_incidents(self):
        for child in self.path.children():
            name = child.basename()
            if name.startswith("."):
                continue
            try:
                number = int(name)
            except ValueError:
                log.err(
                    "Invalid filename in data store: {0}"
                    .format(name)
                )
                continue

            yield (number, self.etag_for_incident_with_number(number))


    def etag_for_incident_with_number(self, number):
        etag_fp = self._incident_fp(number, "etag")
        try:
            etag = etag_fp.getContent()
        except (IOError, OSError):
            data = self.read_incident_with_number_raw(number)
            etag = etag_hash(data).hexdigest()
            try:
                etag_fp.setContent(etag)
            except (IOError, OSError) as e:
                log.err("Unable to store etag for incident {0}: {1}".format(number, e))
        else:
            return etag


    def read_incident_with_number_raw(self, number):
        handle = self._open_incident(number, "r")
        try:
            json = handle.read()
        finally:
            handle.close()
        return json


    def read_incident_with_number(self, number):
        handle = self._open_incident(number, "r")
        try:
            return Incident.from_json_io(handle, number=number)
        finally:
            handle.close()


    def write_incident(self, incident):
        incident.validate()

        self.provision()

        number = incident.number

        incident_fh = self._open_incident(number, "w")
        try:
            incident_fh.write(incident.to_json_text())
        finally:
            incident_fh.close()

        etag_fp = self._incident_fp(number, "etag")
        try:
            etag_fp.remove()
        except (IOError, OSError):
            pass

        self.incidents[number] = incident

        if number > self._max_incident_number:
            self._max_incident_number = number


    def next_incident_number(self):
        self.provision()
        self._max_incident_number += 1
        return self._max_incident_number
