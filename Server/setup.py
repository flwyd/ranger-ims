#!/usr/bin/env python

from setuptools import setup


setup(
    name = "ranger-ims",
    version = "0.1",

    description = "Ranger Incident Management System",
   #long_description = open("README").read(),
    url = "https://github.com/burningmantech/ranger-ims",

    author = u"Wilfredo S\xe1nchez Vega",
    author_email = "tool@burningman.com",

    license = "Apache License Version 2.0, January 2004",

    packages = ["ims"],
    scripts = ["bin/imsd"],

    install_requires = [
        "mock==1.0.1",
        "Werkzeug==0.8.3", # Dont use 0.9.3; see https://github.com/twisted/klein/issues/19
        "zope.interface==4.0.5",
        "Twisted==13.0.0",
        "pyOpenSSL==0.13",
        "klein==0.2.0",
        "mysql-connector-python==1.0.10",
    ],

    classifiers = [
        "Development Status :: 3 - Alpha",
        "License :: OSI Approved :: Apache Software License",
        "Programming Language :: Python :: 2",
        "Topic :: Office/Business",
    ]
)
