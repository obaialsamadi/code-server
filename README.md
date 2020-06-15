# Code Server Anywhere You want

This is a Terraform module that deploys and configures Code Server on GCP instances. 

Code Server allows you to run VSCODE in a remote environment by accessing it through a web browser. 
For more info:
https://coder.com/
https://github.com/cdr/code-server

**QUICK START:**
- to run, make sure you are in the directory that your `tf` files exist, then initialize Terraform by running `terraform init`.
- next, run `terraform validate` to make sure everything is in order.
- finally, run `terraform apply` to begin the process. Once it's done, you can access Code Server through one of the server IPs that are outputted after a successful run. Just toss it in your browser. The default password is "my-password". 
- To destory, run `terraform destroy`

NOTE: you can run `terraform apply -auto-approve` to skip the part where Terraform asks you if you are sure you want to run Terraform. Otherwise, you'll have to enter 'yes' or 'no'. Same applies with `terraform destroy`. WHEN YOU DESTROY THEN ALL YOUR WORK ON THE SERVER IS GONE KEEP THAT IN MIND. 

## Acknowledgements
Special thanks to Damoon (github: da-moon) for being an unmatched and phenomenal help in my DevOps journey and helping me with the NGINX configuration used in this Terraform module. 

I would also like to thank the creators of Code Server. Excellent job.

**SKIP TO SECOND HEADER IF YOU WANT THE MEAT**

## 1. Why Did I Write This

I wrote it because the startup I was working for needed to test the backend and load balance in live mode, as well as build 
docker images. They were using GitPod at first, which is great and basically the same thing, but the issue with GitPod is 
kernel and permission level access, which was causing headaches with Docker. So we decided to host our own Code Server on GCP
to solve that issue and speed up tests and compilations, as well as utilize limited resources for intensive tasks. Other than
that I think Code Server is pretty cool. 

I'm an aspiring DevOps engineer, which means I'm still learning a whole lot. If you see practices in my Terraform code that can
be better then please by all means tell me. I'd appreciate it.

## 2. Good to Understand

### The Basic Stuff

- Fork or clone the repo, whatever you are comfortable with.
- Make sure you have Terraform v0.12 and above installed. I used some modules that aren't available in older versions.
- In `main.tf`, in the `provider` section, I'm using google as default. Use whatever you like and make sure you supply the proper
credentials. If you do use Google, [this guide is pretty neat.](https://console.cloud.google.com/projectselector2/apis/credentials/serviceaccountkey?pli=1&supportedpurview=project)
- I have 3 servers that get spun up with Code Server ready to go on them. If you need less or more, go to `variable.tf` and change `cluster_size` variable default value. 
- run `ssh-keygen` to generate your ssh keys needed by Terraform to launch these instances. Save them in their default location. If you change the location or default name then you have to reflect that change in the `variable.tf` file.

### The Annoying Stuff

- One major headache for me was SSH. It just wouldn't connect and for the life of me I could not figure out why. To solve it, I used the metadata resource you see at the beginning of the `main.tf` folder to inject the ssh keys. This is why you have to generate your ssh keys like I specified above because the injector will use it, and it won't work otherwise.


### The Null Resource Stuff

The null resources are named in steps for understanding purposes of what we are actually doing, and how each step is dependent on the previous step. Here's a very brief description of what's happening in each step:

- Step 0: Basic instance configuration that we want our instances to have moving forward. 
- Step 1: Installing dependancies (uwf, wget, nginx, unzip) that we will need to configure the server. We are using the key installer template included to make sure we import any missing keys before installing.
- Step 2: This step sets a code-server configuration file (things like proxy) and saves in the `/tmp` directory. We then move that config to `/etc/nginx/conf.d` so that nginx could use this config. The reason we saved it in `/tmp` first is because it does not require sudo access so we won't have any permission issues. 
- Step 3: here we are making sure no previous version of code-server exists, then using `wget` to get the code for code-server and unzipping it.
- Step 4: Simply configuring our code-server service needed to communicate with NGINX, then starting the service.

---

Obviously there are things to improve. I'm currently focused on advancing my skills as DevOps engineer by using Linux Academy's DevOps learning path and working for a startup doing DevOps tasks, so I haven't been focused on this project much, at least not beyond what the startup needs. If you have suggestions, please reach out. Enjoy coding from anywhere!
