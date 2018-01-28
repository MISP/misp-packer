# Build Automated Machine Images for MISP

Build a virtual machine for MISP based on Ubuntu 17.10 server
(for VirtualBox or VMWare).

## Requirements

* [VirtualBox](https://www.virtualbox.org)
* [Packer](https://www.packer.io) from the Packer website
* *tree* -> sudo apt install tree (on deployment side)

## Usage

In the file *scripts/bootstrap.sh*, set the value of ``MISP_BASEURL`` according
to the IP address you will associate to your VM
(for example: http://172.16.100.100).

Launch the generation with the VirtualBox builder:

    $ packer build -only=virtualbox-iso misp.json

A VirtualBox image will be generated and stored in the folder
*output-virtualbox-iso*.

Default credentials are displayed (Web interface, SSH and MariaDB) at the end
of the process. You can directly import the image in VirtualBox.

The sha1 and sha512 checksums of the generated VM will be stored in the files
*packer_virtualbox-iso_virtualbox-iso_sha1.checksum* and
*packer_virtualbox-iso_virtualbox-iso_sha512.checksum* respectively.

In case you encounter a problem with the ``MISP_BASEURL``, you can still change
it when the VM is running. For example the IP address of your VM is
``172.16.100.123`` you can set ``MISP_BASEURL`` from your host with the command:

    $ ssh misp@172.16.100.123 sudo -u www-data /var/www/MISP/app/Console/cake Baseurl http://172.16.100.123

If you want to build an image for VMWare you will need to install it and to
use the VMWare builder with the command:

    $ packer build -only=vmware-iso misp.json

You can also launch all builders in parallel.

### Modules activated by default in the VM

* [MISP galaxy](https://github.com/MISP/misp-galaxy)
* [MISP modules](https://github.com/MISP/misp-modules)
* [MISP taxonomies](https://github.com/MISP/misp-taxonomies)

## Automatic export to GitHub

    $ GITHUB_AUTH_TOKEN=<your-github-auth-token>
    $ TAG=$(curl https://api.github.com/repos/MISP/MISP/releases/latest | jq  -r '.tag_name')
    $ ./upload.sh github_api_token=$GITHUB_AUTH_TOKEN owner=MISP repo=MISP tag=$TAG filename=./output-virtualbox-iso/MISP_demo.ova

## Upload latest release

curl -s https://api.github.com/repos/MISP/MISP/tags  |jq -r '.[0] | .name'


You can add these lines in the *post-processors* section of the file
*misp.json* if you want to automate the process.
