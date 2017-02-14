# aws-tools
A small tool set for various Amazon AWS operations

For now, there's only 1 tool (singular) in the tool belt but it's expected to grow over time.

## Find the latest Amazon AMI
This script, grew out of frustration of tedium; digging around the AWS Marketplace for ImageIds to use. _NOTE: parameter position shouldn't matter but I haven't fixed that yet._ Until then, please follow the order of things below.


Search examples include:

With debugging:                                                              
Search for your own AMIs: (most common)                                    
`./find-latest-amis.sh -v -n base -d self`


Then there are specific Operating Systems. 

_NOTE: the **name** (-n, --dist-name) is how the search is narrowed._

CoreOS
```bash
./find-latest-amis.sh -v -n CoreOS-stable -d coreos                        
./find-latest-amis.sh -v -n CoreOS-beta   -d coreos                        
./find-latest-amis.sh -v -n CoreOS-alpha  -d coreos                        
```

Of course, the region defaults to the one I use most frequently, us-west-2. This can be changed as well:


CentOS                                                                       
./find-latest-amis.sh -r ap-northeast-1 -n 'CentOS Linux 7' -d centos   
./find-latest-amis.sh --region eu-west-1 -n 'Linux 6' -d centos            
                                                                                   
Ubuntu:                                                                      
```bash
./find-latest-amis.sh -r eu-central-1 -n xenial-16.04-amd64 -d ubuntu   
               But these can substitute: yakkety-16.10-amd64                         
                                         trusty-14.04-amd64                          
                                         precise-12.04-amd64                         
                                                                                   
./find-latest-amis.sh -n 15.04-Snappy-core -d ubuntu                       
```

You get the idea; these are the rest:                                        
Debian:
```bash
./find-latest-amis.sh -n jessie  -d debian                                 
./find-latest-amis.sh -n stretch -d debian                                 
```                                                                            

Amazon AMI
```bash
./find-latest-amis.sh -n ecs-optimized -d amazon                           
```

Red Hat Enterprise Linux
```bash
./find-latest-amis.sh -n RHEL-7 -d rhel                                    
./find-latest-amis.sh -n RHEL-6 -d rhel                                    
```

Until this script has matured a bit, double-check the ImageIds. That's about it. 
