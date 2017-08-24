# Build Automated Machine Images for MISP

## Requirements

* [VirtualBox](https://www.virtualbox.org)
* [Packer](https://www.packer.io)

## Usage

In the file *scripts/bootstrap.sh*, set the value of ``MISP_BASEURL`` according
to the IP address you will associate to your VM
(for example: http://172.16.100.100).

Launch the generation:

    $ packer build -only=virtualbox-iso misp.json

A VirtualBox image will be generated and stored in the folder
*output-virtualbox-iso*. You can directly import it in VirtualBox.

If you want to build an image for VMWare you will need to install it and to
use the VMWare builder with the command:

    $ packer build -only=vmware-iso misp.json

You can also launch all builders in parallel.

### Automatic export to GitHub

- create a new release: https://developer.github.com/v3/repos/releases/#create-a-release
- upload a release asset: https://developer.github.com/v3/repos/releases/#upload-a-release-asset

Example of a binary upload with curl (from the GitHub blog):

    curl -H "Authorization: token <yours>" \
     -H "Accept: application/vnd.github.manifold-preview" \
     -H "Content-Type: application/zip" \
     --data-binary @build/mac/package.zip \
     "https://uploads.github.com/repos/hubot/singularity/releases/123/assets?name=1.0.0-mac.zip"
