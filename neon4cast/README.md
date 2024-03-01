# Introduction

FaaSr is a package that makes it easy for developers to create R functions and workflows that can run in the cloud, on-demand, based on triggers - such as timers, or repository commits. It is built for Function-as-a-Service (FaaS) cloud computing, and supports both widely-used commercial (GitHub Actions, AWS Lambda, IBM Cloud) and open-source platforms (OpenWhisk). It is also built for cloud storage, and supports the S3 standard also widely used in commercial (AWS S3), open-source (Minio) and research platforms (Open Storage Network). With FaaSr, you can focus on developing the R functions, and leave dealing with the idiosyncrasies of different FaaS platforms and their APIs to the FaaSr package.

# Objectives

This example guides you through the setup and execution of FaaSr workflows that implement the [neon4cast NEON forecast example](https://github.com/eco4cast/neon4cast). In this tutorial, you will learn how to describe, configure, and execute a FaaSr workflow of R functions in the cloud, using GitHub Actions for cloud execution of functions, and a public Minio S3 “bucket” for cloud data storage. With the knowledge gained from this tutorial, you will be able to also run FaaSr workflows in OpenWhisk and Amazon Lambda, as well as use an S3-compliant bucket of your choice. 

# Requirements

You will need a GitHub account (and a personal access token, PAT with "workflow" and "read:org" scopes). You will also need RStudio and the FaaSr package installed. For a reproducible experience, you may want to consider using RStudio in a local Docker container or Posit Cloud instance [by following the instructions in the main FaaSr tutorial](https://github.com/FaaSr/FaaSr-tutorial/blob/main/README.md) 

# Install FaaSr package and required dependences

You may already have some of these dependences in your RStudio desktop:

```
# install dependences - devtools
install.packages('devtools')
library('devtools')

# install dependences - sodium
install.packages('sodium')
library('sodium')

# install dependences - minioclient
install.packages('minioclient')
library('minioclient')
install_mc()

# install FaaSr
install.packages('FaaSr')
library('FaaSr')

# add credentials library
library('credentials')
```

# Configure Rstudio to use GitHub Token

You may already have this setup in your RStudio environment. If you don't, configure the environment to use your GitHub account (replace with your username and email)

```
usethis::use_git_config(user.name = "YOUR_GITHUB_USERNAME", user.email = "YOUR_GITHUB_EMAIL")
```

```
credentials::set_github_pat()
```

# Clone the example repository

```
system('git clone https://github.com/FaaSr-examples/neon4cast')
setwd('~/neon4cast')
```

# Configure the FaaSr secrets file with your GitHub token

Open the file named env in the editor. You need to enter your GitHub token here: replace the string <<YOUR_GITHUB_TOKEN>> with your GitHub token, and save this file. 

The secrets file stores all credentials you use for FaaSr. You will notice that this file has the pre-populated credentials (secret key, access key) to access the Minio "play" bucket

# Configure the FaaSr JSON simple workflow template with your GitHub username

Open the file neon4cast.json and replace the string <<YOUR_USER_NAME>> with your GitHub username, and save this file.

The JSON file stores the configuration for your workflow. We'll come back to that later.

# Clean up data in the S3 folder

By default, this example uses a shared S3 folder faasr/faasr-neon4cast in Minio play (you can configure a different folder in the JSON file) to save the file that is also submitted. Clean it up before you run your example (substitute with the appropriate date):

```
mc_ls("play/faasr/faasr-neon4cast")
mc_rm("play/faasr/faasr-neon4cast/aquatics-2024-02-02-faasr.csv.gz")
```

# Register and invoke the simple workflow with GitHub Actions

Now you're ready for some Action! The steps below will:

* Use the faasr function in the FaaSr library to load the neon4cast.json and faasr_env in a list called faasr_tutorial
* Use the register_workflow() function to create a repository for the workflow actions in GitHub, and configure the workflow there using GitHub Actions
* Use the invoke_workflow() function to invoke the execution of your workflow

```
neon4cast <- faasr(json_path="neon4cast.json", env="env")
neon4cast$register_workflow()
```

When prompted, select "public" to create a public repository. Now run the workflow:

```
neon4cast$invoke_workflow()
```

# Browse the S3 Data Store to view outputs

Now the workflow is running; soon it will create outputs in the Minio play S3 bucket. You can use the mc_ls command to browse the outputs:

```
mc_ls("play/faasr/faasr-neon4cast")
```

# Add a timer trigger

In the example above, you triggered the tutorial workflow once (manually) with the invoke_workflow() function. You can also set a timer trigger for your workflow with set_workflow_timer(cron), where cron is a string in the cron format. For example, you can set a timer for every 10 minutes:

```
neon4cast$set_workflow_timer("*/10 * * * *")
```

Check your Actions tab in your FaaSr-tutorial repo, wait for the next 10-minute interval (note that GitHub does not guarantee a precise start time "on the dot"), and you will see that the workflow now will get invoked multiple times. Make sure you unset the timer once you're done testing this feature:

```
neon4cast$unset_workflow_timer()
```



