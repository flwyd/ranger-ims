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
    "set_content_type",
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



def url_for(request, endpoint, *args, **kwargs):
    kwargs["force_external"] = True
    return IKleinRequest(request).url_for(endpoint, *args, **kwargs)


def set_content_type(request, content_type):
    request.setHeader(HeaderName.contentType.value, content_type.value)


def http_sauce(f):
    @wraps(f)
    def wrapper(request, *args, **kwargs):
        try:
            return f(request, *args, **kwargs)

        except NoSuchIncidentError as e:
            request.setResponseCode(http.NOT_FOUND)
            set_content_type(request, ContentType.plain)
            return "No such incident: {}\n".format(e)

        except InvalidDataError as e:
            request.setResponseCode(http.BAD_REQUEST)
            set_content_type(request, ContentType.plain)
            return "Invalid data: {}\n".format(e)

        except Exception as e:
            raise
            request.setResponseCode(http.INTERNAL_SERVER_ERROR)
            set_content_type(request, ContentType.plain)
            log.err(e)
            return "Server error.\n"

    return wrapper



class HeaderName (Values):
    contentType = ValueConstant("Content-Type")
    location    = ValueConstant("Location")



class ContentType (Values):
    plain = ValueConstant("text/plain")
    HTML  = ValueConstant("text/html")
    JSON  = ValueConstant("application/json")
