# Introduction - What is it?
This repo allows setting up a load testing "rig" using Splunk's eventgen (https://github.com/splunk/eventgen).
Eventgen is a python based application with a number of pre-reqs that make it hard to run.  
Eventgen supports a controller-server architecture, in that is allows for multiple "nodes" to connect to a controlling service.  
This repo configures a controller-server with a specified number of nodes - this overcomes some of the single-threaded nature of eventgen. Please note that the confguration here is designed for the nodes to reside on the same host as the controller service.
It *is* possible to connect external nodes however has not yet been implemented here.

The controller is managed via a REST API - more information is available at http://splunk.github.io/eventgen/REFERENCE.html
# Getting Started

## Pre-Reqs
* Docker (or Docker Dekstop on Mac/Windows)
* make (GNU Make)
* curl

## Basics
Upon starting, the Eventgen bundles (tarballs of Simple Splunk eventgen apps) in the ./bundles directory are loaded and executed. 
For more information on eventgen and bundles visir https://dev.splunk.com/enterprise/tutorials/module_getstarted/useeventgen/  

To get started:
```
make all num=5
make eventgen-start
```
Changing the value of "num" will control the number of nodes created.

### (Optional) Get the current status
`make get-status`

## Commands
Run `make help` to see all available commands

# Future Enhancements
* Allow for remote nodes
* Service Discovery
* Toggling of eventgen bundles
* GUI to manage bundles/nodes

# Known Issues
* Users on ARM64 machines cannot run the default eventgen image. Please use `livehybrid/eventgen:latest` by setting an environment variable `EVENTGEN_IMAGE=livehybrid/eventgen:latest`
