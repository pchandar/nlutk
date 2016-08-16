#!/usr/bin/env python
# -*- coding: utf-8 -*-

from setuptools import setup, Extension

with open('README.rst') as readme_file:
    readme = readme_file.read()

with open('requirements.txt') as req_file:
    requirements = [req.strip() for req in req_file]

setup(
    name='nlutk',
    version='0.0.1',
    description="Natural Language Understanding Toolkit",
    long_description=readme + '\n\n',
    author="Praveen Chandar",
    author_email='pcr@udel.edu',
    url='https://github.com/pchandar/nlutk',
    packages=[
        'nlutk',
    ],
    package_dir={'nlutk': 'nlutk'},
    entry_points={
        'console_scripts': [
            'nlutk=nlutk.cli:main'
        ]
    },
    include_package_data=True,
    install_requires=requirements,
    license="MIT license",
    zip_safe=False,
    keywords='nlutk',
    classifiers=[
        'Development Status :: 2 - Pre-Alpha',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Natural Language :: English',
        'Programming Language :: Python :: 3.5',
    ],
    test_suite='tests',
    ext_modules=[
        Extension("nlutk.text.vocab",
                  language="c++",
                  sources=['nlutk/text/vocab.pyx'],
                  define_macros=[('CYTHON_TRACE', '1')]),
        Extension("nlutk.text.text",
                  language="c++",
                  sources=['nlutk/text/text.pyx'],
                  include_dirs=['nlutk/text/include'],
                  define_macros=[('CYTHON_TRACE', '1')])]
)
