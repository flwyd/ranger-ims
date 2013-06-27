#!/usr/bin/env python

from setuptools import setup


def install_requirements():
    try:
        from pip.req import parse_requirements
    except ImportError:
        return []

    install_reqs = parse_requirements("requirements.txt")
    return [str(ir.req) for ir in install_reqs]


setup(
    name = "ranger-ims",
    version = "0.1",

    description = "Ranger Incident Management System",
   #long_description = open("README").read(),
    url = "https://github.com/burningmantech/ranger-ims",

    author = u"Wilfredo S\xe1nchez",
    author_email = "tool@burningman.com",

    license = "Apache License Version 2.0, January 2004",

    packages = ["ims"],
    scripts = ["bin/imsd"],

    install_requires = install_requirements(),

    classifiers = [
        "Development Status :: 3 - Alpha",
        "License :: OSI Approved :: Apache Software License",
        "Programming Language :: Python :: 2",
        "Topic :: Office/Business",
    ]
)
