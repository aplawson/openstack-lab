Contributing to scripts
=======================

First things first
------------------

Read the OpenStack Style Commandments http://docs.openstack.org/developer/hacking/

Getting started
---------------

.. TODO(aplawson): Fix Me. Add more content here.

Prerequisites
-------------

.. TODO(aplawson): Fix Me. Add more content here.

Coding style
------------

We follow the conventions of other OpenStack projects.

StackTrain
~~~~~~~~~~

.. TODO(aplawson): Fix me. Add more content here.

Osbash
~~~~~~

Osbash is written in BASH and follows conventions of DevStack:
`devstack <http://devstack.org/>`_.

DevStack bash style guidelines can be found at the bottom of:
https://git.openstack.org/cgit/openstack-dev/devstack/blob/master/HACKING.rst

Structure
---------


.. TODO(aplawson): Add more information as the repo gets merged.

OSBASH:
~~~~~~~

**autostart**

osbash copy shell scripts (\*.sh) into this directory to have them
automatically executed (and removed) upon boot.

**config**

Contains the configuration files for all the scripts. The setup can be customized here.

**img**

By default osbash will put into this directory its base disk images
(base-\*-<distro>.vdi), the VM export images (labs-<distro>.ova),
and all installation ISO images it may download.

**lib**

This directory contains bash libraries used by scripts.

**log**

Contains the log files written (and removed) by osbash and
the scripts running within the VMs.

**scripts**

All scripts in this directory run within the VMs.


Testing
-------

Useful tools for checking scripts:

- `bashate <https://github.com/openstack-dev/bashate>`_ (must pass)
- `shellcheck <https://github.com/koalaman/shellcheck.git>`_ (optional)

.. TODO (aplawson): Add Python checks etc.

Submitting patches
------------------

These documents will help you submit patches to OpenStack projects (including
this one):

- http://docs.openstack.org/infra/manual/developers.html#development-workflow
- https://wiki.openstack.org/wiki/GitCommitMessages

If you change the behavior of the scripts as documented in the replace-guides,
add a DocImpact flag to alert the documentation team. For instance, add a line
like this to your commit message:

DocImpact new option added to osbash.sh

- https://wiki.openstack.org/wiki/Documentation/DocImpact

Reviewing
---------

Learn how to review (or what to expect when having your patches reviewed) here:
- http://docs.openstack.org/infra/manual/developers.html#development-workflow

TODO
----

Anything not covered here
-------------------------

Check README.md and get in touch with other scripts developers.

