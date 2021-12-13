resource "aws_instance" "RaylyticProject" {
  ami                    = "ami-0567e0d2b4b2169ae"
  instance_type          = "t3.large"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.all-sg-raylytic-project.id]
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "20"
    delete_on_termination = "true"
  }
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file("raylytic.pem")
  }

  provisioner "file" {
    source      = "../build/install.sh"
    destination = "/tmp/install.sh"

  }

  provisioner "file" {
    source      = "../build/uninstall.sh"
    destination = "/tmp/uninstall.sh"
  }

    provisioner "file" {
    source      = "../build/commands.sh"
    destination = "/tmp/commands.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sh /tmp/commands.sh",
    ]
  }

  tags = {
    Name         = "RaylyticProject"
    Usage        = "Project Raylytic"
    Installed_SW = "docker_kubectl_kind"
    Project      = var.project
  }
}



resource "aws_security_group" "all-sg-raylytic-project" {
  name        = "RaylyticBuildRequiredPorts"
  description = "Allowing all ports required for Syna Server"
  dynamic "ingress" {
    iterator = port
    for_each = var.ingressrules
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
