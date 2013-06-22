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
Protocol utilities
"""

__all__ = [
    "url_for",
    "set_response_header",
    "http_sauce",
    "HeaderName",
    "ContentType",
]

from functools import wraps

from twisted.python import log
from twisted.python.constants import Values, ValueConstant
from twisted.web import http

from klein.interfaces import IKleinRequest

from ims.data import InvalidDataError
from ims.store import NoSuchIncidentError
from ims.dms import DatabaseError


def url_for(request, endpoint, *args, **kwargs):
    kwargs["force_external"] = True
    return IKleinRequest(request).url_for(endpoint, *args, **kwargs)


def set_response_header(request, name, value):
    if isinstance(value, ValueConstant):
        value = value.value
    request.setHeader(name.value, value)


def http_sauce(f):
    # FIXME: better for debugging
    return f

    @wraps(f)
    def wrapper(request, *args, **kwargs):
        try:
            return f(request, *args, **kwargs)

        except NoSuchIncidentError as e:
            request.setResponseCode(http.NOT_FOUND)
            set_response_header(request, HeaderName.contenttype, ContentType.plain)
            return "No such incident: {0}\n".format(e)

        except InvalidDataError as e:
            request.setResponseCode(http.BAD_REQUEST)
            set_response_header(request, HeaderName.contenttype, ContentType.plain)
            return "Invalid data: {0}\n".format(e)

        except DatabaseError as e:
            request.setResponseCode(http.INTERNAL_SERVER_ERROR)
            set_response_header(request, HeaderName.contenttype, ContentType.plain)
            log.err(e)
            return "Database error."

        except Exception as e:
            raise
            request.setResponseCode(http.INTERNAL_SERVER_ERROR)
            set_response_header(request, HeaderName.contenttype, ContentType.plain)
            log.err(e)
            return "Server error.\n"

    return wrapper



class HeaderName (Values):
    contentType    = ValueConstant("Content-Type")
    etag           = ValueConstant("ETag")
    incidentNumber = ValueConstant("Incident-Number")
    location       = ValueConstant("Location")



class ContentType (Values):
    HTML  = ValueConstant("text/html")
    JSON  = ValueConstant("application/json")
    XHTML = ValueConstant("application/xhtml+xml")
    plain = ValueConstant("text/plain")
