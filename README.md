# Code Server Anywhere You want

This is a Terraform module that deploys and configures Code Server on GCP instances. 

**QUICK START:**
- to run, make sure you are in the directory that your `tf` files exist, then initialize Terraform by running `terraform init`.
- next, run `terraform validate` to make sure everything is in order.
- finally, run `terraform apply` to begin the process. Once it's done, you can access Code Server through one of the server IPs that are outputted after a successful run. Just toss it in your browser. The default password is "my-password". 
- To destory, run `terraform destroy`

NOTE: you can run `terraform apply -auto-approve` to skip the part where Terraform asks you if you are sure you want to run Terraform. Otherwise, you'll have to enter 'yes' or 'no'. Same applies with `terraform destroy`. WHEN YOU DESTROY THEN ALL YOUR WORK ON THE SERVER IS GONE KEEP THAT IN MIND. 

****SKIP TO THIRD HEADER IF YOU WANT THE MEAT****

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
credentials. If you do use Google, [this guide is pretty neat.](https://console.cloud.google.com/projectselector2/apis/credentials/serviceaccountkey?pli=1&supportedpurview=project)
- I have 3 servers that get spun up with Code Server ready to go on them. If you need less or more, go to `variable.tf` and change `cluster_size` variable default value. 
- run `ssh-keygen` to generate your ssh keys needed by Terraform to launch these instances. Save them in their default location. If you change the location or default name then you have to reflect that change in the `variable.tf` file.

### The Annoying Stuff

- One major headache for me was SSH. It just wouldn't connect and for the life of me I could not figure out why. To solve it, I used the metadata resource you see at the beginning of the `main.tf` folder to inject the ssh keys.
