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
"""[1:]
    )


    def __init__(self, name):
        self._name = name


    @renderer
    def name(self, request, tag):
        return self._name



class DispatchQueueElement(Element):
    loader = XMLString(
"""
<!DOCTYPE html>
<html xmlns:t="http://twistedmatrix.com/ns/twisted.web.template/0.1">
 <head>
  <title><span t:render="title" /></title>
  <link rel="icon" href="/resources/ranger.png" type="image/png" />
  <link rel="stylesheet" type="text/css" href="/tidy.css" />
  <script type="text/javascript" src="/jquery.js" />
  <script type="text/javascript" src="/tidy.js" />
  <script type="text/javascript">

    $(document).ready(function() {
      $('#DispatchQueue').TidyTable(
        {
          // Options
        },
        {
          columnTitles : ['Rank','Programming Language','Ratings Jan 2012','Delta Jan 2012','Status'],
          columnValues : [
            ['1','Java','17.479%','-0.29%','A'],
            ['2','C','16.976%','+1.15%','A'],
            ['3','C#','8.781%','+2.55%','A'],
            ['4','C++','8.063%','-0.72%','A'],
            ['5','Objective-C','6.919%','+3.91%','A']
          ]
        }
      );
    });

  </script>
 </head>
 <body>
  <h1><span t:render="title" /></h1>

  <div id="DispatchQueue"></div>

 </body>
</html>
"""[1:]
    )


    def __init__(self, ims):
        self._ims = ims


    @renderer
    def title(self, request, tag):
        return "Dispatch Queue"
