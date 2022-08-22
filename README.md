﻿# Dockerfile for FunC testing

This docker image should come in handy to run [toncli](https://github.com/disintar/toncli) with the [new tests support](https://github.com/disintar/toncli/blob/master/docs/advanced/func_tests_new.md).  
Setting it all up manually could be cumbersome otherwise.  
Inspired by [Dockerfile for the Open Network Node](https://github.com/ton-blockchain/ton/tree/master/docker)  
Built on Ubuntu 20.04 so should be WSL docker compatible.

## Build
 To build an image run: `docker build . -t toncli-local`  
 Where *toncli-local* would be an image name

## Use
 You're going to need to pass your workdir as a volume to make things happen
 ### Creating project
 Run  
 
 ``` console
 docker run --rm -it \
 -v ~/Dev:/code \
 toncli-local start --name test_project wallet 
 ```
 
 You're going to see the toncli project structure in *~/Dev/test_project*  
 `README.md  build  fift  func  project.yaml  tests`
  
 ### Building
 
  Run  
  
  ``` console
  docker run --rm -it \
  -v ~/Dev/test_project:/code \
  toncli-local build
  ```
	
 ### Running tests
   
   ``` console
   docker run --rm -it \
   -v ~/Dev/test_project:/code \
   toncli-local run_test
   ``` 

 ### Deploying contract
   Now here is the tricky part.  
   **Toncli** stores deployment info in it's config directory instead of your project directory.  
   So we're going to have to create another volume for that to persist.  
   
  Run
  ``` console
  docker run --rm -it \
  -v ~/Dev/test_project:/code \
  -v /path/to/toncli_conf_dir/:/root/.config \
  toncli-local update_libs
  ```
  After that you should go through standard toncli initialization dialog and pass absolute paths to the binaries
  - /usr/local/bin/func
  - /usr/local/bin/fift
  - /usr/local/bin/lite-client
  
  Don't get confused those path's are inside the docker image and not your local system.  
  After that you should get an initialized toncli directory on your local system at */path/to/toncli_conf_dir/toncli*.  
  Looking like:
  
  ``` console
  config.ini
  fift-libs
  func-libs
  test-libs
  ``` 
  
  Now you can use it in the deploy or any other process like so. 
  
  Run  
  
  ``` console
  docker run --rm -it \
  -v /path/to/project:/code \
  -v /path/to/toncli_conf_dir/:/root/.config \
  toncli-local deploy --net testnet
  ```
  
  **wallet** directory would be created inside your local config dir with all the usefull deployment information
### General usage
 ``` console
 docker run --rm -it \
 -v <code_volume> \
 -v [optional config volume] \
 <docker image name> \
 <toncli command you want to run>
 ```