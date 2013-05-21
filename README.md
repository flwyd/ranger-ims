Ranger Incident Management System
=================================

This software package implements software to provide logging for
incidents as they occur and to aid in the dispatch of resources to
respond to those incidents.  It is presently tailored to the specific
needs of the Black Rock Rangers in Black Rock City.

This system includes a server component and one (hopefully more in the
future) client component.  The server is the master repository for
incident information.  Clients connect to the server over the network
and provide an interface to users which enables them to view and edit
incident information.

The components are in the following directories:

 * `Server/` — The server application.

   Written in [Python](http://www.python.org/), should be portable to
   any platform with Python 2.6, or a greater version of Python 2 (but
   not Python 3).

 * `Incidents/` — Mac OS client application.

   Requires Mac OS 10.7 or greater.
