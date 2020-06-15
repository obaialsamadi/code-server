# Code Server Anywhere You want

This is a Terraform module that deploys and configures Code Server on GCP instances. 

**SKIP TO THIRD HEADER IF YOU WANT THE MEAT**

## Why did I write this

I wrote it because the startup I was working for needed to test the backend and load balance in live mode, as well as build 
docker images. They were using GitPod at first, which is great and basically the same thing, but the issue with GitPod is 
kernel and permission level access, which was causing headaches with Docker. So we decided to host our own Code Server on GCP
to solve that issue and speed up tests and compilations, as well as utilize limited resources for intensive tasks. Other than
that I think Code Server is pretty cool. 

## Things to Know

I'm an aspiring DevOps engineer, which means I'm still learning a whole lot. If you see practices in my Terraform code that can
be better then please by all means tell me. I'd appreciate it.

## To run

### The Basic Stuff

- Fork or clone the repo, whatever you are comfortable with.
- Make sure you have Terraform v0.12 and above installed. I used some modules that aren't available in older versions.
- In `main.tf`, in the `provider` section, I'm using google as default. Use whatever you like and make sure you supply the proper
credentials. If you do use Google, (this guide is pretty neat) [https://console.cloud.google.com/projectselector2/apis/credentials/serviceaccountkey?pli=1&supportedpurview=project]
