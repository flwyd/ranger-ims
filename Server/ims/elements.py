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
    "incidents_from_query",
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
    def columns(self, request, tag):
        return to_json_text([
            "Number",
            "Priority",
            "Created", "Dispatched", "On Scene", "Closed",
            "Rangers",
            "Location",
            "Type",
            "Description"
        ])


    @renderer
    def data(self, request, tag):
        def format_date(d):
            if d is None:
                return ""
            else:
                return d.strftime("%a.%H:%M")

        data = []

        for number, etag in incidents_from_query(self.ims, request):
            incident = self.ims.storage.read_incident_with_number(number)

            if incident.summary:
                summary = incident.summary
            elif incident.report_entries:
                for entry in incident.report_entries:
                    if not entry.system_entry:
                        summary = entry.text
                        break
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


    @renderer
    def hide_closed_column(self, request, tag):
        if show_closed_from_query(request):
            return tag
        else:
            return "$('td:nth-child(6),th:nth-child(6)').hide();"


    @renderer
    def search_value(self, request, tag):
        terms = terms_from_query(request)
        if terms:
            return tag(value=" ".join(terms))
        else:
            return tag


    @renderer
    def show_closed_value(self, request, tag):
        if show_closed_from_query(request):
            return tag(value="true")
        else:
            return tag(value="false")


    @renderer
    def show_closed_checked(self, request, tag):
        if show_closed_from_query(request):
            return tag(checked="")
        else:
            return tag



def incidents_from_query(ims, request):
    if not hasattr(request, "ims_incidents"):
        if request.args:
            request.ims_incidents = ims.storage.search_incidents(
                terms       = terms_from_query(request),
                show_closed = show_closed_from_query(request),
            )
        else:
            request.ims_incidents = ims.storage.list_incidents()

    return request.ims_incidents


def terms_from_query(request):
    if not hasattr(request, "ims_terms"):
        if request.args:
            terms = set()

            for query in request.args.get("search", []):
                for term in query.split(" "):
                    terms.add(term)

            for term in request.args.get("term", []):
                terms.add(term)

            request.ims_terms = terms

        else:
            request.ims_terms = set()

    return request.ims_terms


def show_closed_from_query(request):
    if not hasattr(request, "ims_show_closed"):
        if request.args:
            try:
                request.ims_show_closed = request.args.get("show_closed", ["false"])[-1] == "true"
            except IndexError:
                request.ims_show_closed = False
        else:
            # Must be True to match incidents_from_query() behavior
            request.ims_show_closed = True

    return request.ims_show_closed
