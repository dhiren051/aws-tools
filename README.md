# aws-tools
A small tool set for various Amazon AWS operations

For now, there's only a few tools in the tool belt but it's expected to grow over time.

## Find the latest Amazon AMI
This script will help you to find the latest, most up-to-date, AMI of a given distro and version, then:

`export amiLatest=$ImageId` to the enviroment

This is helpful when starting a new job with [Packer]. Check the [find-latest-ami] wikipage




[Packer]:https://www.packer.io/intro/
[find-latest-ami]:https://github.com/todd-dsm/aws-tools/wiki/find-latest-ami
