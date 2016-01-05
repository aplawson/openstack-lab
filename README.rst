=============
Training labs
=============

About
-----

Deploy OpenStack using the (knock-on-wood) latest version of OpenStack on virtual machines.
This creates a virtual cloud and the goal is to deploy this cloud onto a virtual machine so
it can be replicated over and over with identical IP addresses. The steps in this scripted build process follow
`OpenStack Install Guide <http://docs.openstack.org/#install-guides>`_ as closely as possible.

This repo was written and designed for numerous reasons; for the purpose of enabling proof of
concepts, to provide OpenStack instructors an easy way to setup OpenStack for the
purposes of teaching OpenStack and for advanced users to test features specific to a
particular OpenStack release.
This repository also confirms whether the installation process works as expected or required.

OpenStack-lab started as a fork of the OpenStack training-labs project. For more information
about the original project, see the `OpenStack wiki <https://wiki.openstack.org/wiki/Documentation/training-labs>`_.

* Free software: Apache license
* Documentation: http://github.com/aplawson/openstack-lab/docs
* Source: http://github.com/aplawson/openstack-lab
* Bugs: To Be Determined

Pre-requisite
-------------

The idea was initially to support VirtualBox on all platforms but now the focus has become
more specificy to libvirt/KVM on Linux (Ubuntu to be precise). KVM support is still being
worked out so please use VirtualBox for the time being.

* Download and install `VirtualBox <https://www.virtualbox.org/wiki/Downloads>`_.

How to run the scripts
----------------------

Clone the training-labs repository::

    $ git clone git://github.com/aplawson/openstack-lab.git

What the script installs
------------------------

Running this will automatically spin up 3 virtual machines in VirtualBox/KVM:

* Controller node
* Network node
* Compute node

Now you have a multi-node deployment of OpenStack running with the below services installed.

OpenStack services installed on Controller node:

* Keystone
* Horizon
* Glance
* Nova

  * nova-api
  * nova-scheduler
  * nova-consoleauth
  * nova-cert
  * nova-novncproxy
  * python-novaclient

* Neutron

  * neutron-server

* Cinder

Openstack services installed on Network node:

* Neutron

  * neutron-plugin-openvswitch-agent
  * neutron-l3-agent
  * neutron-dhcp-agent
  * neutron-metadata-agent

Openstack Services installed on Compute node:

* Nova

  * nova-compute

* Neutron

  * neutron-plugin-openvswitch-agent

How to access the services
--------------------------

There are two ways to access the services:

* OpenStack Dashboard (horizon)

You can access the dashboard at: http://192.168.100.51/horizon

Admin Login:

* Username: ``admin``
* Password: ``admin_pass``

Demo User Login:

* Username: ``demo``
* Password: ``demo_pass``

You can ssh to each of the nodes by::

    # Controller node
    $ ssh osbash@10.0.0.11

    # Network node
    $ ssh osbash@10.0.0.21

    # Compute node
    $ ssh osbash@10.0.0.31

Credentials for all nodes:

* Username: ``osbash``
* Password: ``osbash``

After you have ssh access, you need to source the OpenStack credentials in order to access the services.

Two credential files are present on each of the nodes:

* ``demo-openstackrc.sh``
* ``admin-openstackrc.sh``

Source the following credential files

For Admin user privileges::

    $ source admin-openstackrc.sh

For Demo user privileges::

    $ source demo-openstackrc.sh

Now you can access the OpenStack services via CLI.

Specs
-----

To review specifications, see http://specs.openstack.org/openstack/docs-specs/specs/liberty/traininglabs.html

Mailing lists, IRC
------------------

To contribute, join the IRC channel, ``#openstack-doc``, on IRC freenode
or write an e-mail to the OpenStack Documentation Mailing List
``openstack-docs@lists.openstack.org``. Please use ``[training-labs]`` tag in the
subject of the email message.

You might consider
`registering on the OpenStack Documentation Mailing List <http://lists.openstack.org/cgi-bin/mailman/listinfo/openstack-docs>`_
if you want to post your e-mail instantly. It may take some time for
unregistered users, as it requires an administrator's approval.

Sub-team leads
--------------

Feel free to ping Roger or Pranav on the IRC channel ``#openstack-doc`` regarding
any queries about the Labs section.

* Roger Luethi

  * Email: ``rl@patchworkscience.org``
  * IRC: ``rluethi``

* Pranav Salunke

  * Email: ``dguitarbite@gmail.com``
  * IRC: ``dguitarbite``

Meetings
--------

Team meeting for training-labs is on alternating Thursdays on Google Hangouts.
https://wiki.openstack.org/wiki/Documentation/training-labs#Meeting_Information

Wiki
----

Follow various links on training-labs here:
https://wiki.openstack.org/wiki/Documentation/training-labs#Meeting_Information
