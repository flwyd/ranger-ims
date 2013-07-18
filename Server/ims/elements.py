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
XHTML Elements
"""

__all__ = [
    "HomePageElement",
    "DispatchQueueElement",
]

from twisted.web.template import Element, renderer
from twisted.web.template import XMLFile

from ims.data import to_json_text



class BaseElement(Element):
    def __init__(self, ims, name, title):
        self.ims = ims
        self._title = title

        self.loader = XMLFile(ims.config.Resources.child(name+".xhtml"))


    @renderer
    def title(self, request, tag):
        return tag(self._title)



class HomePageElement(BaseElement):
    def __init__(self, ims):
        BaseElement.__init__(self, ims, "home", "Ranger Incident Management System")



class DispatchQueueElement(BaseElement):
    def __init__(self, ims):
        BaseElement.__init__(self, ims, "queue", "Dispatch Queue")


    @renderer
    def data(self, request, tag):
        storage = self.ims.storage

        if request.args:
            terms = request.args.get("term", [])

            try:
                show_closed = request.args.get("show_closed", ["n"])[-1] == "y"
            except IndexError:
                show_closed = False

            incident_infos = self.storage.search_incidents(terms=terms, show_closed=show_closed)
        else:
            incident_infos = self.storage.list_incidents()

        def format_date(d):
            if d is None:
                return ""
            else:
                return d.strftime("%a.%H:%M")

        data = []

        for number, etag in incident_infos:
            incident = storage.read_incident_with_number(number)

            if not show_closed and incident.closed is not None:
                continue

            if incident.summary:
                summary = incident.summary
            elif incident.report_entries:
                summary = incident.report_entries[0].text
            else:
                summary = ""

            data.append([
                incident.number,
                incident.priority,
                format_date(incident.created),
                format_date(incident.dispatched),
                format_date(incident.on_scene),
                format_date(incident.closed),
                ", ".join(ranger.handle for ranger in incident.rangers),
                str(incident.location),
                ", ".join(incident.incident_types),
                summary,
            ])

        return to_json_text(data)
