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

from twisted.python import log
from twisted.internet import reactor
from twisted.internet.defer import Deferred
from twisted.internet.protocol import Protocol
from twisted.web import http
from twisted.web.static import File
from twisted.web.client import Agent, ResponseDone

from klein import Klein

from ims.data import Incident, JSON, to_json_text, from_json_io
from ims.sauce import url_for, set_response_header
from ims.sauce import http_sauce
from ims.sauce import HeaderName, ContentType
from ims.elements import HomePageElement, DispatchQueueElement
from ims.elements import incidents_from_query



class IncidentManagementSystem(object):
    """
    Incident Management System
    """
    app = Klein()

    protocol_version = "0.0"

    def __init__(self, config):
        self.config = config
        self.avatarId = None
        self.storage = config.storage
        self.dms = config.dms


    @app.route("/", methods=("GET",))
    @http_sauce
    def root(self, request):
        set_response_header(request, HeaderName.contentType, ContentType.HTML)
        return HomePageElement(self)


    @app.route("/resources/", branch=True)
    @http_sauce
    def favicon(self, request):
        return File(self.config.Resources.path)


    @app.route("/ping/", methods=("GET",))
    @http_sauce
    def ping(self, request):
        set_response_header(request, HeaderName.etag, "ack")
        set_response_header(request, HeaderName.contentType, ContentType.JSON)
        return to_json_text("ack")


    @app.route("/rangers/", methods=("GET",))
    @http_sauce
    def list_rangers(self, request):
        set_response_header(request, HeaderName.etag, str(self.dms.rangers_updated))
        set_response_header(request, HeaderName.contentType, ContentType.JSON)

        d = self.dms.rangers()
        d.addCallback(lambda rangers:
            to_json_text(tuple(
                {
                    "handle": ranger.handle,
                    "name"  : ranger.name,
                    "status": ranger.status,
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
        return self.config.IncidentTypesJSON


    @app.route("/incidents/", methods=("GET",))
    @http_sauce
    def list_incidents(self, request):
        #set_response_header(request, HeaderName.etag, "*") # FIXME
        set_response_header(request, HeaderName.contentType, ContentType.JSON)
        return to_json_text(tuple(incidents_from_query(self, request)))


    @app.route("/incidents/<number>", methods=("GET",))
    @http_sauce
    def get_incident(self, request, number):
        # FIXME: For debugging
        #import time
        #time.sleep(0.3)

        set_response_header(request, HeaderName.etag, self.storage.etag_for_incident_with_number(number))
        set_response_header(request, HeaderName.contentType, ContentType.JSON)

        if False:
            #
            # This is faster, but doesn't benefit from any cleanup or
            # validation code, so it's only OK if we know all data in the
            # store is clean by this server version's standards.
            #
            return self.storage.read_incident_with_number_raw(number)
        else:
            #
            # This parses the data from the store, validates it, then
            # re-serializes it.
            #
            incident = self.storage.read_incident_with_number(number)
            return incident.to_json_text()


    @app.route("/incidents/<number>", methods=("POST",))
    @http_sauce
    def edit_incident(self, request, number):
        number = int(number)
        incident = self.storage.read_incident_with_number(number)

        edits_json = from_json_io(request.content)
        edits = Incident.from_json(edits_json, number=number, validate=False)

        #print "-"*80
        #print edits_json
        #print "-"*80

        for key in edits_json.keys():
            key = JSON.lookupByValue(key)

            if key is JSON.report_entries:
                if edits.report_entries is not None:
                    for entry in edits.report_entries:
                        # Edit report entrys to add author
                        entry.author = self.avatarId.decode("utf-8")
                        incident.report_entries.append(entry)
                        #print "Adding report entry:", entry
            elif key is JSON.location_name:
                if edits.location.name is not None:
                    incident.location.name = edits.location.name
                    #print "Editing location name:", edits.location.name
            elif key is JSON.location_address:
                if edits.location.address is not None:
                    incident.location.address = edits.location.address
                    #print "Editing location address:", edits.location.address
            elif key is JSON.ranger_handles:
                if edits.rangers is not None:
                    incident.rangers = edits.rangers
                    #print "Editing rangers:", edits.rangers
            elif key is JSON.incident_types:
                if edits.incident_types is not None:
                    incident.incident_types = edits.incident_types
                    #print "Editing incident types:", edits.incident_types
            else:
                attr_name = key.name
                attr_value = getattr(edits, attr_name)

                if key in (JSON.created, JSON.dispatched, JSON.on_scene, JSON.closed):
                    if edits.created is None:
                        # If created is None, then we aren't editing state.
                        # (If would be weird if others were not None here.)
                        continue
                elif attr_value is None:
                    # None values should not cause edits.
                    continue

                setattr(incident, attr_name, attr_value)
                #print "Editing", attr_name, ":", attr_value

        self.storage.write_incident(incident)

        set_response_header(request, HeaderName.contentType, ContentType.JSON)
        request.setResponseCode(http.OK)

        return "";


    @app.route("/incidents/", methods=("POST",))
    @http_sauce
    def new_incident(self, request):
        incident = Incident.from_json_io(request.content, number=self.storage.next_incident_number())

        # Edit report entrys to add author
        for entry in incident.report_entries:
            entry.author = self.avatarId.decode("utf-8")

        self.storage.write_incident(incident)

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


    @app.route("/queue", methods=("GET",))
    @http_sauce
    def dispatchQueue(self, request):
        if not request.args:
            request.args["show_closed"] = ["false"]

        set_response_header(request, HeaderName.contentType, ContentType.HTML)
        return DispatchQueueElement(self)


    @app.route("/jquery.js", methods=("GET",))
    @http_sauce
    def jquery(self, request):
        version = "jquery-1.10.2.min.js"
        url = "http://code.jquery.com/"+version
        return self.cachedResource(version, url)


    @app.route("/jquery-1.10.2.min.map", methods=("GET",))
    @http_sauce
    def jquery_map(self, request):
        name = "jquery-1.10.2.min.map"
        url = "http://code.jquery.com/"+name
        return self.cachedResource(name, url)


    @app.route("/tidy.js", methods=("GET",))
    @http_sauce
    def tidy(self, request):
        name = "tidy.js"
        url = "https://raw.github.com/nuxy/Tidy-Table/v1.4/jquery.tidy.table.min.js"
        return self.cachedResource(name, url)


    @app.route("/tidy.css", methods=("GET",))
    @http_sauce
    def tidy_css(self, request):
        name = "tidy.css"
        url = "https://raw.github.com/nuxy/Tidy-Table/v1.4/jquery.tidy.table.min.css"
        return self.cachedResource(name, url)


    @app.route("/images/arrow_asc.gif", methods=("GET",))
    @http_sauce
    def tidy_asc(self, request):
        name = "tidy-asc.gif"
        url = "https://raw.github.com/nuxy/Tidy-Table/v1.4/images/arrow_asc.gif"
        return self.cachedResource(name, url)


    @app.route("/images/arrow_desc.gif", methods=("GET",))
    @http_sauce
    def tidy_desc(self, request):
        name = "tidy-desc.gif"
        url = "https://raw.github.com/nuxy/Tidy-Table/v1.4/images/arrow_desc.gif"
        return self.cachedResource(name, url)


    def cachedResource(self, name, url):
        name = "_{0}".format(name)
        filePath = self.config.Resources.child(name)

        if filePath.exists():
            return File(filePath.path)

        class FileWriter(Protocol):
            def __init__(self, fp, fin):
                self.fp = fp
                self.tmp = fp.temporarySibling(".tmp")
                self.fh = self.tmp.open("w")
                self.fin = fin

            def dataReceived(self, bytes):
                self.fh.write(bytes)

            def connectionLost(self, reason):
                self.fh.close()
                if isinstance(reason.value, ResponseDone):
                    self.tmp.moveTo(self.fp)
                    self.fin.callback(None)
                else:
                    self.fin.errback(reason)

        log.msg("Downloading jquery from {0}".format(url))

        agent = Agent(reactor)

        d = agent.request("GET", url)

        def gotResponse(response):
            finished = Deferred()
            response.deliverBody(FileWriter(filePath, finished))
            return finished
        d.addCallback(gotResponse)
        d.addCallback(lambda _: File(filePath.path))

        return d
