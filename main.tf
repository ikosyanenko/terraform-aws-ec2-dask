provider "aws" {
  region = "${var.region}"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_ami" "dask_base_cpu" {
  most_recent = true

  filter {
    name = "name"
    values = [
      "dask_base_cpu"]
  }

  filter {
    name = "virtualization-type"
    values = [
      "hvm"]
  }

  owners = [
    "self"]
}

resource "aws_security_group" "ssh_access" {
  name = "ssh_access_${var.env_tag}"
  vpc_id = "${data.aws_vpc.default.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
    // warning!
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

resource "aws_security_group" "dask_node_self" {
  name = "dask_node_self_${var.env_tag}"
  vpc_id = "${data.aws_vpc.default.id}"

  ingress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    self = true
  }
}

resource "aws_key_pair" "dask_node" {
  key_name = "id_rsa_${var.env_tag}"
  public_key = "${file(var.ssh_public_key)}"
}

resource "aws_instance" "scheduler" {
  ami = "${data.aws_ami.dask_base_cpu.id}"
  instance_type = "${var.instance_type}"
  key_name = "${aws_key_pair.dask_node.key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh_access.id}",
    "${aws_security_group.dask_node_self.id}"]
  associate_public_ip_address = true

  tags {
    Name = "dask_scheduler_${var.env_tag}"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    agent = false
    timeout = "2m"
    private_key = "${file(var.ssh_private_key)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo docker run -dit --restart on-failure --net=host --name scheduler dask_base_cpu dask-scheduler --port 8786 --bokeh-port 8787"]
  }
}

resource "aws_spot_instance_request" "worker_cpu" {
  count = "${var.workers_count}"
  ami = "${data.aws_ami.dask_base_cpu.id}"
  spot_price = "${var.spot_price}"
  instance_type = "${var.instance_type}"
  key_name = "${aws_key_pair.dask_node.key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.ssh_access.id}",
    "${aws_security_group.dask_node_self.id}"]
  associate_public_ip_address = true
  wait_for_fulfillment = true

  tags {
    Name = "worker_cpu_${count.index}_${var.env_tag}"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    agent = false
    timeout = "2m"
    private_key = "${file(var.ssh_private_key)}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo docker run -dit --net=host --name workers --restart on-failure dask_base_cpu dask-worker --reconnect --nprocs 2 ${aws_instance.scheduler.private_ip}:8786"]
  }
}