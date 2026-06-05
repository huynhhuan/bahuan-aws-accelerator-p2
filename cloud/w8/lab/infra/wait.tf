resource "null_resource" "wait_for_app" {
  depends_on = [
    module.ec2_minikube,
    module.alb
  ]

  triggers = {
    bootstrap_sha1 = sha1(data.cloudinit_config.minikube_bootstrap.rendered)
    instance_id    = module.ec2_minikube.instance_id
    node_port      = tostring(var.app_node_port)
  }

  connection {
    type        = "ssh"
    host        = module.ec2_minikube.public_ip
    user        = "ubuntu"
    private_key = module.ec2_minikube.private_key_pem
    timeout     = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "sudo test -f /opt/k8s-challenge/status.txt",
      "sudo cat /opt/k8s-challenge/status.txt",
      "ok=0; for i in $(seq 1 60); do if curl -fsS http://127.0.0.1:${var.app_node_port}/healthz; then ok=1; break; fi; sleep 5; done; test $ok -eq 1",
      "alb_ok=0; for i in $(seq 1 60); do if curl -fsS http://${module.alb.dns_name}/healthz; then alb_ok=1; break; fi; sleep 10; done; test $alb_ok -eq 1"
    ]
  }
}
