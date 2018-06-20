# Provisioning a dask cluster on EC2 spot instances with Terraform


## Download and install next HashiCorp tools

* [Terraform](https://www.terraform.io/downloads.html)
* [Packer](https://www.packer.io/downloads.html)

## Step by step tutorial

**Create the base AMI with `packer`** (install docker and build container):

```bash
packer build images/dask_base_cpu.json
```

Note: add argument `--force` to re-create an existing AMI.


**Create the cluster with `terraform`**:

```bash
terraform plan
terraform apply
```

**Create SSH tunnel** to access the dask scheduler:

```bash
ssh -N \
    -L 8786:localhost:8786 \
    -L 8787:localhost:8787 \
    ubuntu@[scheduler.public_ip]
```

Check the DASK scheduler UI: localhost:8787/status

**Destroy all DASK cluster**:

```bash
terraform destroy
```

This project based on [dask-terraform-recipes](https://github.com/martinsotir/dask-terraform-recipes)