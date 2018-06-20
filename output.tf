output "scheduler_ip" {
  value = "${aws_instance.scheduler.public_ip}"
}

output "worker_cpu_ips" {
  value = [
    "${aws_spot_instance_request.worker_cpu.*.public_ip}"]
}

output "connection_string" {
  value = "ssh -N -L 8786:localhost:8786 -L 8787:localhost:8787 ubuntu@${aws_instance.scheduler.public_ip}"
}