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
Protocol bits
"""

__all__ = [
    "IncidentManagementSystem",
]

from twisted.web import http

from klein import Klein

from ims.store import Storage
from ims.data import Incident, JSON, to_json, from_json_io
from ims.sauce import url_for, set_response_header
from ims.sauce import http_sauce
from ims.sauce import HeaderName, ContentType
from ims.elements import HomePageElement


class IncidentManagementSystem(object):
    """
    Incident Management System
    """
    app = Klein()

    protocol_version = "0.0"

    def __init__(self, storageDirectory, dms):
        self.storageDirectory = storageDirectory
        self.avatarId = None
        self.dms = dms


    @app.route("/", methods=("GET",))
    def root(self, request):
        set_response_header(request, HeaderName.contentType, ContentType.XHTML)
        return HomePageElement("Ranger Incident Management System")


    @app.route("/ping/", methods=("GET",))
    @http_sauce
    def ping(self, request):
        set_response_header(request, HeaderName.etag, "ack")
        set_response_header(request, HeaderName.contentType, ContentType.JSON)
        return to_json("ack")


    @app.route("/rangers/", methods=("GET",))
    @http_sauce
    def list_rangers(self, request):
        #set_response_header(request, HeaderName.etag, "*") # FIXME
        set_response_header(request, HeaderName.contentType, ContentType.JSON)

        d = self.dms.allRangers()
        d.addCallback(lambda rangers:
            to_json(tuple(
                {
                    "handle": ranger.handle,
                    "name"  : ranger.name,
                }
                for ranger in rangers
            ))
        )

        return d              

    @app.route("/incident_types/", methods=("GET",))
    @http_sauce
    def list_incident_types(self, request):
        #set_response_header(request, HeaderName.etag, "*") # FIXME
        set_response_header(request, HeaderName.contentType, ContentType.JSON)
        return to_json((
            "Admin",
            "Art",
            "Echelon",
            "Eviction",
            "Fire",
            "Gate",
            "Green Dot",
            "HQ",
            "Law Enforcement",
            "Medical",
            "Mental Health",
            "SITE",
            "Staff",
            "Theme Camp",
            "Vehicle",

            "Junk",
        ))


    @app.route("/incidents/", methods=("GET",))
    @http_sauce
    def list_incidents(self, request):
        #set_response_header(request, HeaderName.etag, "*") # FIXME
        set_response_header(request, HeaderName.contentType, ContentType.JSON)
        return to_json(tuple(self.storage().list_incidents()))


    @app.route("/incidents/<number>", methods=("GET",))
    @http_sauce
    def get_incident(self, request, number):
        # FIXME: For debugging
        #import time
        #time.sleep(0.3)

        store = self.storage()

        set_response_header(request, HeaderName.etag, store.etag_for_incident_with_number(number))
        set_response_header(request, HeaderName.contentType, ContentType.JSON)

        if False:
            #
            # This is faster, but doesn't benefit from any cleanup or
            # validation code, so it's only OK if we know all data in the
            # store is clean by this server version's standards.
            #
            return store.read_incident_with_number_raw(number)
        else:
            #
            # This parses the data from the store, validates it, then
            # re-serializes it.
            #
            incident = store.read_incident_with_number(number)
            return incident.as_json()


    @app.route("/incidents/<number>", methods=("POST",))
    @http_sauce
    def edit_incident(self, request, number):
        number = int(number)
        incident = self.storage().read_incident_with_number(number)

        edits_json = from_json_io(request.content)
        edits = Incident.from_json(edits_json, number=number, validate=False)

        #print "-"*80
        #print edits_json
        #print "-"*80

        for key in edits_json.keys():
            if key == "report_entries":
                if edits.report_entries is not None:
                    incident.report_entries += edits.report_entries
                    #print "Adding report entries:", edits.report_entries
            elif key == "location_name":
                if edits.location.name is not None:
                    incident.location.name = edits.location.name
                    #print "Editing location name:", edits.location.name
            elif key == "location_address":
                if edits.location.address is not None:
                    incident.location.address = edits.location.address
                    #print "Editing location address:", edits.location.address
            elif key == "ranger_handles":
                if edits.rangers is not None:
                    incident.rangers = edits.rangers
                    #print "Editing rangers:", edits.rangers
            elif key == "incident_types":
                if edits.incident_types is not None:
                    incident.incident_types = edits.incident_types
                    #print "Editing incident types:", edits.incident_types
            else:
                attr_name = JSON.lookupByValue(key).name
                attr_value = getattr(edits, attr_name)
                setattr(incident, attr_name, attr_value)
                #print "Editing", attr_name, ":", attr_value

        self.storage().write_incident(incident)

        set_response_header(request, HeaderName.contentType, ContentType.JSON)
        request.setResponseCode(http.OK)

        return "";


    @app.route("/incidents/", methods=("POST",))
    @http_sauce
    def new_incident(self, request):
        store = self.storage()

        incident = Incident.from_json_io(request.content, number=store.next_incident_number())
        store.write_incident(incident)

        request.setResponseCode(http.CREATED)

        request.setHeader(
            HeaderName.incidentNumber.value,
            incident.number
        )
        request.setHeader(
            HeaderName.location.value,
            url_for(request, "get_incident", {"number": incident.number})
        )

        return "";


    def storage(self):
        if not hasattr(self, "_storage"):
            storage = Storage(self.storageDirectory)
            storage.provision()
            self._storage = storage
        return self._storage
