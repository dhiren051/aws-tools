# aws-tools
A small tool set for various Amazon AWS operations

For now, there's only a few tools in the belt but it's expected to grow over time. I tend to pull this into existing projects, for example:

```bash
myHost:project-x userName$ tree -d -L 2
.
├── floppy
├── http
│   └── debian-8
├── scripts
│   ├── common
│   ├── debian
│   └── ubuntu
├── sources
└── zarchive
```

...as a git submodule, by adding it to the scripts directory:

```bash
git submodule add git@github.com:todd-dsm/aws-tools.git scripts/aws-tools

myHost:project-x userName$ tree -d -L 2
.
...
├── scripts
│   ├── aws-tools <-- here
│   ├── common
│   ├── debian
│   └── ubuntu
...
```

Then update it periodically:

`myHost:project-x userName$ git submodule update --recursive --remote`

***

## Find the latest Amazon AMI
This script will help you to find the latest, most up-to-date, AMI of a given distro and version. For example, when this script is ran:

`./find-latest-amis.sh -n jessie  -d debian`

Then it will:

`export amiLatest=$ImageId`

This is helpful when starting a new job with [Packer]. Check the [find-latest-ami] wiki page.


## Access AWS Security Group
This script determines your local gateway address then asks AWS if the specified security group has a rule in place to let you through on port 22. This is great for people with DHCP gateway addresses or people (like me) that sometimes spend too much time in hotel rooms. See the [access-aws-securitygroup] wiki page for more details. To run:

`./access-aws-securitygroup.sh`



[Packer]:https://www.packer.io/intro/
[find-latest-ami]:https://github.com/todd-dsm/aws-tools/wiki/find-latest-ami
[access-aws-securitygroup]:https://github.com/todd-dsm/aws-tools/wiki/access-aws-securitygroup
