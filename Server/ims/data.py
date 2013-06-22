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
Data model
"""

__all__ = [
    "InvalidDataError",
    "Incident",
    "ReportEntry",
    "Ranger",
    "Location",
    "to_json",
    "from_json_io",
    "from_json_text",
]

from json import dumps, load as from_json_io, loads as from_json_text
from datetime import datetime

from twisted.python.constants import Values, ValueConstant

rfc3339_date_time_format = "%Y-%m-%dT%H:%M:%SZ"



class JSON(Values):
    number           = ValueConstant("number")
    priority         = ValueConstant("priority")
    summary          = ValueConstant("summary")
    location_name    = ValueConstant("location_name")
    location_address = ValueConstant("location_address")
    ranger_handles   = ValueConstant("ranger_handles")
    incident_types   = ValueConstant("incident_types")
    report_entries   = ValueConstant("report_entries")
    author           = ValueConstant("author")
    text             = ValueConstant("text")
    created          = ValueConstant("created")
    dispatched       = ValueConstant("dispatched")
    on_scene         = ValueConstant("on_scene")
    closed           = ValueConstant("closed")



class InvalidDataError (ValueError):
    """
    Invalid data
    """



class Incident(object):
    """
    Incident
    """

    @classmethod
    def from_json_text(cls, text, number=None, validate=True):
        root = from_json_text(text)
        return cls.from_json(root, number, validate)


    @classmethod
    def from_json_io(cls, io, number=None, validate=True):
        if False:
            # For debugging
            text = io.read()
            print "*"*80
            print text
            print "*"*80
            return cls.from_json_text(text, number, validate)
        else:
            root = from_json_io(io)
            return cls.from_json(root, number, validate)


    @classmethod
    def from_json(cls, root, number=None, validate=True):
        if number is None:
            raise TypeError("Incident number may not be null")
        else:
            number = int(number)

        json_number = root.get(JSON.number.value, None)

        if json_number is not None:
            if json_number != number:
                raise InvalidDataError("Incident number may not be modified: {0} != {1}".format(json_number, number))

            root[JSON.number.value] = number

        if type(root) is not dict:
            raise InvalidDataError("JSON incident must be a dict")

        def parse_date(rfc3339):
            if not rfc3339:
                return None
            else:
                return datetime.strptime(rfc3339, rfc3339_date_time_format)

        location = Location(
            name    = root.get(JSON.location_name.value   , None),
            address = root.get(JSON.location_address.value, None),
        )

        ranger_handles = root.get(JSON.ranger_handles.value, None)
        if ranger_handles is None:
            rangers = None
        else:
            rangers = [
                Ranger(handle, None, None)
                for handle in ranger_handles
            ]

        report_entries = [
            ReportEntry(
                author = entry.get(JSON.author.value, u"<unknown>"),
                text = entry.get(JSON.text.value, None),
                created = parse_date(entry.get(JSON.created.value, None)),
            )
            for entry in root.get(JSON.report_entries.value, ())
        ]

        incident = cls(
            number         = number,
            priority       = root.get(JSON.priority.value, None),
            summary        = root.get(JSON.summary.value, None),
            location       = location,
            rangers        = rangers,
            incident_types = root.get(JSON.incident_types.value, None),
            report_entries = report_entries,
            created        = parse_date(root.get(JSON.created.value, None)),
            dispatched     = parse_date(root.get(JSON.dispatched.value, None)),
            on_scene       = parse_date(root.get(JSON.on_scene.value, None)),
            closed         = parse_date(root.get(JSON.closed.value, None)),
        )

        if validate:
            incident.validate()

        return incident


    def __init__(
        self,
        number,
        rangers=(),
        location=None,
        incident_types=(),
        summary=None, report_entries=None,
        created=None, dispatched=None, on_scene=None, closed=None,
        priority=None,
    ):
        if type(number) is not int:
            raise InvalidDataError(
                "Incident number must be an int, not ({0}){1}".format(number.__class__.__name__, number)
            )

        if number < 0:
            raise InvalidDataError(
                "Incident number but be natural, not {0}".format(number)
            )

        if rangers is not None:
            rangers = list(rangers)

        if incident_types is not None:
            incident_types = list(incident_types)

        if report_entries is not None:
            report_entries = list(report_entries)

        if created is None:
            created = datetime.now()

        if priority is None:
            priority = 5

        self.number         = number
        self.rangers        = rangers
        self.location       = location
        self.incident_types = incident_types
        self.summary        = summary
        self.report_entries = report_entries
        self.created        = created
        self.dispatched     = dispatched
        self.on_scene       = on_scene
        self.closed         = closed
        self.priority       = priority


    def validate(self):
        """
        Validate this incident.
        """
        if self.rangers is None:
            raise InvalidDataError("Rangers may not be None.")

        for ranger in self.rangers:
            ranger.validate()

        if self.location is not None:
            self.location.validate()

        if self.incident_types is not None:
            for incident_type in self.incident_types:
                if type(incident_type) is not unicode:
                    raise InvalidDataError(
                        "Incident type must be unicode, not {0}".format(incident_type)
                    )

        if self.summary is not None and type(self.summary) is not unicode:
            raise InvalidDataError(
                "Incident summary must be unicode, not {0}".format(self.summary)
            )

        if self.report_entries is not None:
            for report_entry in self.report_entries:
                report_entry.validate()

        if self.created is not None and type(self.created) is not datetime:
            raise InvalidDataError(
                "Incident created date must be a datetime, not {0}".format(self.created)
            )

        if self.dispatched is not None and type(self.dispatched) is not datetime:
            raise InvalidDataError(
                "Incident dispatched date must be a datetime, not {0}".format(self.dispatched)
            )

        if self.on_scene is not None and type(self.on_scene) is not datetime:
            raise InvalidDataError(
                "Incident on_scene date must be a datetime, not {0}".format(self.on_scene)
            )

        if self.closed is not None and type(self.closed) is not datetime:
            raise InvalidDataError(
                "Incident closed date must be a datetime, not {0}".format(self.closed)
            )

        if type(self.priority) is not int:
            raise InvalidDataError(
                "Incident priority must be an int, not {0}".format(self.priority)
            )

        if not 1 <= self.priority <= 5:
            raise InvalidDataError(
                "Incident priority must be an int, not {0}".format(self.priority)
            )

        return self


    def as_json(self):
        root = {}

        def render_date(date_time):
            if not date_time:
                return None
            else:
                return date_time.strftime(rfc3339_date_time_format)

        if self.incident_types is None:
            incident_types = ()
        else:
            incident_types = self.incident_types

        root[JSON.number.value          ] = self.number
        root[JSON.priority.value        ] = self.priority
        root[JSON.summary.value         ] = self.summary
        root[JSON.location_name.value   ] = self.location.name
        root[JSON.location_address.value] = self.location.address
        root[JSON.incident_types.value  ] = incident_types

        root[JSON.created.value   ] = render_date(self.created)
        root[JSON.dispatched.value] = render_date(self.dispatched)
        root[JSON.on_scene.value  ] = render_date(self.on_scene)
        root[JSON.closed.value    ] = render_date(self.closed)

        root[JSON.ranger_handles.value] = [ranger.handle for ranger in self.rangers]

        root[JSON.report_entries.value] = [
            {
                JSON.author.value: entry.author,
                JSON.text.value: entry.text,
                JSON.created.value: render_date(entry.created),
            }
            for entry in self.report_entries
        ]

        try:
            return to_json(root)
        except TypeError:
            raise AssertionError(
                "{0}.as_json() generated unserializable data: {1}"
                .format(self.__class__.__name__, root)
            )



class ReportEntry(object):
    """
    Report entry
    """

    def __init__(self, author, text, created=None):
        if created is None:
            created = datetime.now()

        self.author  = author
        self.text    = text
        self.created = created


    def __str__(self):
        return "<ReportEntry {author}@{created}: {text}".format(
            author  = self.author,
            text    = self.text,
            created = self.created,
        )


    def validate(self):
        if self.author is not None and type(self.author) is not unicode:
            raise InvalidDataError(
                "Report entry author must be unicode, not {0}".format(self.author)
            )

        if type(self.text) is not unicode:
            raise InvalidDataError(
                "Report entry text must be unicode, not {0}".format(self.text)
            )

        if type(self.created) is not datetime:
            raise InvalidDataError(
                "Report entry created date must be a datetime, not {0}".format(self.created)
            )



class Ranger(object):
    """
    Ranger
    """

    def __init__(self, handle, name, status):
        if not handle:
            raise InvalidDataError("Ranger handle required.")

        self.handle = handle
        self.name   = name
        self.status = status


    def validate(self):
        if type(self.handle) is not unicode:
            raise InvalidDataError(
                "Ranger handle must be unicode, not {0}".format(self.handle)
            )

        if self.name is not None and type(self.name) is not unicode:
            raise InvalidDataError(
                "Ranger name must be unicode, not {0}".format(self.handle)
            )



class Location(object):
    """
    Location
    """

    def __init__(self, name=None, address=None):
        self.name    = name
        self.address = address


    def validate(self):
        if self.name and type(self.name) is not unicode:
            raise InvalidDataError(
                "Location name must be unicode, not {0}".format(self.handle)
            )

        if self.address and type(self.address) is not unicode:
            raise InvalidDataError(
                "Location address must be unicode, not {0}".format(self.handle)
            )



def to_json(obj):
    return dumps(obj, separators=(',',':'))
