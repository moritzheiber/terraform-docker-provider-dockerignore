# Reproducing a bug in the Terraform Docker provider

The Terraform Docker provider added the ability to interpret a `.dockerignore` file recently, however, there appears to be a bug in it which "ignores" the ignored files in it and adds them to an image anyway /o\.

This repository should aid in reproducing said bug.

## Versions

- Terraform 1.0.5
- Provider version 2.15.0
- Docker 20.10.8, build 3967b7d
- Ubuntu Linux 21.04

## Setup

You need:

- a [Github Access Token which allows for accessing the GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry) (`ghcr.io`)
- a valid GitHub username
- a valid GitHub repository to push to. This module assumes it carries the same name as this very repository.

## Reproducing the bug

Fork this repository and copy the file `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and fill it with content. Alternatively, you can also specify the required variables (see below) manually during the run.

To build the image, run:

```console
$ terraform -chdir=terraform init
$ terraform -chdir=terraform apply
```

You should then have a copy of the pushed image stored locally on your machine.

The `.dockerignore` file contains a ton of files (e.g. the `Dockerfile` itself, the `terraform` directory, to name a few) that shouldn't be present inside the image:

```console
$ cat .dockerignore
some_ignored_file.txt
terraform*
Dockerfile
docs
README.md
```

However, if you peak inside, they are all there:

```console
$ docker run -ti --rm $(terraform -chdir=terraform output -raw image_reference) ls -la
total 72
----------    1 root     root          4128 Jan  1  1970 README.md
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 bin
drwxr-xr-x    5 root     root           360 Sep  2 07:47 dev
d---------    2 root     root          4096 Jan  1  1970 docs
drwxr-xr-x    1 root     root          4096 Sep  2 07:47 etc
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 home
drwxr-xr-x    7 root     root          4096 Aug  5 12:25 lib
drwxr-xr-x    5 root     root          4096 Aug  5 12:25 media
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 mnt
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 opt
dr-xr-xr-x  428 root     root             0 Sep  2 07:47 proc
drwx------    2 root     root          4096 Aug  5 12:25 root
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 run
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 sbin
----------    1 root     root             0 Jan  1  1970 some_file.txt
----------    1 root     root             0 Jan  1  1970 some_ignored_file.txt
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 srv
dr-xr-xr-x   13 root     root             0 Sep  2 07:47 sys
d---------    3 root     root          4096 Jan  1  1970 terraform
drwxrwxrwt    2 root     root          4096 Aug  5 12:25 tmp
drwxr-xr-x    7 root     root          4096 Aug  5 12:25 usr
drwxr-xr-x   12 root     root          4096 Aug  5 12:25 var
```

_Note: the permissions are also horrible wrong, but that's for another bug to consider_

You can verify that the `.dockerignore` file is being properly observed when build the container manually and inspecting its content:

```console
$ docker build -t test-container .
[...]
$ docker run --rm -ti test-container ls -l
total 56
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 bin
drwxr-xr-x    5 root     root           360 Sep  2 07:49 dev
drwxr-xr-x    1 root     root          4096 Sep  2 07:49 etc
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 home
drwxr-xr-x    7 root     root          4096 Aug  5 12:25 lib
drwxr-xr-x    5 root     root          4096 Aug  5 12:25 media
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 mnt
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 opt
dr-xr-xr-x  425 root     root             0 Sep  2 07:49 proc
drwx------    2 root     root          4096 Aug  5 12:25 root
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 run
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 sbin
-rw-rw-r--    1 root     root             0 Sep  2 06:43 some_file.txt
drwxr-xr-x    2 root     root          4096 Aug  5 12:25 srv
dr-xr-xr-x   13 root     root             0 Sep  2 07:49 sys
drwxrwxrwt    2 root     root          4096 Aug  5 12:25 tmp
drwxr-xr-x    7 root     root          4096 Aug  5 12:25 usr
drwxr-xr-x   12 root     root          4096 Aug  5 12:25 var
```

---
