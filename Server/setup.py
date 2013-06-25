#!/usr/bin/env python

from distutils.core import setup

setup(
    name = "ranger-ims",
    version = "0.2-dev",

    description = "Ranger Incident Management System",
   #long_description = open("README").read(),
    url = "https://github.com/burningmantech/ranger-ims",

    author = u"Wilfredo S\xe1nchez",
    author_email = "tool@burningman.com",

    license = "Apache License Version 2.0, January 2004",

    packages = ["ims"],
    scripts = ["bin/imsd"],

    classifiers = [
        "Development Status :: 3 - Alpha",
        "License :: OSI Approved :: Apache Software License",
        "Programming Language :: Python :: 2",
        "Topic :: Office/Business",
    ]
)
