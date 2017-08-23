# Build Automated Machine Images for MISP

## Requirements

* [VirtualBox](https://www.virtualbox.org)
* [Packer](https://www.packer.io)

## Usage

In the file *scripts/bootstrap.sh*, set the value of ``MISP_BASEURL`` according
to the IP address you will associate to your VM
(for example: http://172.16.100.100).

Launch the generation:

    $ packer build misp.json

A VirtualBox image will be generated and stored in the folder
*output-virtualbox-iso*. You can import it in VirtualBox.
