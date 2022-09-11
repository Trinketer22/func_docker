# Dockerfile for FunC testing

This docker image should come in handy to run [toncli](https://github.com/disintar/toncli) with the [new tests support](https://github.com/disintar/toncli/blob/master/docs/advanced/func_tests_new.md).  
Setting it all up manually could be cumbersome otherwise.  
Inspired by [Dockerfile for the Open Network Node](https://github.com/ton-blockchain/ton/tree/master/docker)  
Image is built on [alpine linux](https://www.alpinelinux.org/) to reduce size.  
**NOT tested on WSL**.  
If you're looking for WSL compatibility check out [master branch](https://github.com/Trinketer22/func_docker).  

## Build
 To build an image run: `docker build . -t toncli-local [ optional --build-arg ]`  
 Where *toncli-local* would be an image name.
 
 In most cases that's it.  
 However, if you need something special, there are custom build arguments available.
 
 ### Custom build arguments
- **TON_GIT** specifies git repo url to fetch sources from. [SpyCheese](https://github.com/SpyCheese/ton) by default.
- **TON_BRANCH** specifies git branch to fetch from. **Set to toncli-local by default** so would likely require change if alternate *TON_GIT* is set.
- **BUILD_DEBUG** is self-explaintatory. By default *Release* binaries are built. Set *BUILD_DEBUG=1* to build debug binaries.
- **CUSTOM_CMAKE** Overrides build process cmake flags. Use it at your own risk. 
	
Example of building debug binaries from [ton-blockchain/ton](https://github.com/ton-blockchain/ton) testnet branch

```console
docker build . -t toncli-local \
--build-arg TON_GIT=https://github.com/ton-blockchain/ton \
--build-arg TON_BRANCH=testnet \
--build-arg BUILD_DEBUG=1
```



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
