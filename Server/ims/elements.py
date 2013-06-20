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
]

from twisted.web.template import Element, renderer, XMLString



class HomePageElement(Element):
    loader = XMLString(
"""
<!DOCTYPE html>
<html xmlns:t="http://twistedmatrix.com/ns/twisted.web.template/0.1">
 <head>
  <title><span t:render="name" /></title>
  <link rel="icon" href="/resources/ranger.png" type="image/png" />
 </head>
 <body>
  <h1><span t:render="name" /></h1>
 </body>
</html>
"""
    )


    def __init__(self, name):
        self._name = name


    @renderer
    def name(self, request, tag):
        return self._name
