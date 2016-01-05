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

When complete, you will have a multi-node deployment of OpenStack running with all required services installed.

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


How to get invovled
------------------

To help contribute to this forked effort, send me an email to ``alawson@aqorn.com``.
Please use the ``[openstack-lab]`` tag (or similar) in the subject of the email message.


Getting involved with OpenStack
--------------

You might consider `registering on the OpenStack Documentation Mailing List <http://lists.openstack.org/cgi-bin/mailman/listinfo/openstack-docs>`_ if you want to post your e-mail instantly. It may take some time for
unregistered users, as it requires an administrator's approval.

This project is being developed with the help of the team leads within the original OpenStack project:

* Roger Luethi

  * Email: ``rl@patchworkscience.org``
  * IRC: ``rluethi``

* Pranav Salunke

  * Email: ``dguitarbite@gmail.com``
  * IRC: ``dguitarbite``


Wiki
----

When a Wiki is available, it will be posted here (most likely at readthedocs.org or similar)
