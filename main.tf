/*
 * Deal with SSL cert files and ansible
 */
resource "local_file" "ssl_cert" {
  content  = file("${var.ssl_cert_file}")
  filename = "${path.module}/ansible/roles/gitlab-ce/tasks/files/${var.ssl_cert_file}"
}

resource "local_file" "ssl_key" {
  content  = file("${var.ssl_cert_key}")
  filename = "${path.module}/ansible/roles/gitlab-ce/tasks/files/${var.ssl_cert_key}"
}

/*
 * Persistent storage for instance
 */
resource "aws_volume_attachment" "persistent_storage" {
  device_name = "/dev/xvdf"
  volume_id   = data.aws_ebs_volume.persistent_storage.id
  instance_id = aws_instance.instance.id

  # Run the playbook after the volume has mounted
  provisioner "local-exec" {
    command = <<EOT
export ANSIBLE_HOST_KEY_CHECKING=False;
echo '#!/usr/bin/env bash\nexport ANSIBLE_HOST_KEY_CHECKING=False\nansible-playbook -u ${var.ansible_user} --private-key ${var.private_ssh_key} -i ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory ${path.module}/ansible/site.yml' > ./ansible-${var.namespace}-${var.stage}-${var.name}.sh
ansible-playbook -u ${var.ansible_user} --private-key ${var.private_ssh_key} -i ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory ${path.module}/ansible/site.yml
EOT
  }
}

data "aws_ebs_volume" "persistent_storage" {
  most_recent = true

  filter {
    name   = "tag:Name"
    values = [var.data_storage_ebs_name]
  }
}

# resource "aws_ebs_volume" "persistent_storage" {
#   availability_zone = aws_instance.instance.availability_zone # Same zone as instance
#   size              = var.persistent_storage_size

#   tags = {
#     Name      = "${var.namespace}-${var.stage}-${var.name}-storage"
#     NameSpace = var.namespace
#     Stage     = var.stage
#   }
# }

# resource "aws_ebs_snapshot" "persistent_storage" {
#   volume_id   = aws_ebs_volume.persistent_storage.id
#   description = "${var.namespace}-${var.stage}-${var.name}-storage-snapshot"

#   timeouts {
#     create = "24h"  # Snapshot once a day
#     delete = "120h" # Hold onto for 5 days
#   }

#   tags = {
#     Name      = "${var.namespace}-${var.stage}-${var.name}-storage-snapshot"
#     NameSpace = var.namespace
#     Stage     = var.stage
#   }
# }

/*
 * Setup service instance
 */
data "aws_ami" "ubuntu" {
  owners = ["099720109477"] # Canonical User (https://canonical.com/)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  most_recent = true
}

resource "aws_instance" "instance" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = var.instance_type
  security_groups = [aws_security_group.instance.name]
  key_name        = var.ssh_key_pair
  monitoring      = true
  user_data       = "${file("${path.module}/scripts/setup_instance.sh")}"

  root_block_device {
    volume_type           = "standard"
    volume_size           = "10"
    delete_on_termination = true
  }

  # Ansible requires Python to be installed on the remote machine
  provisioner "remote-exec" {
    inline = ["sudo apt-get install -qq -y python"]
  }

  connection {
    type        = "ssh"
    private_key = file(var.private_ssh_key)
    user        = var.ansible_user
    host        = aws_instance.instance.public_ip
  }

  # Install & Configure via Ansible Playbook
  provisioner "local-exec" {
    command = <<EOT
echo "[gitlab]" > ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory;
echo "${aws_instance.instance.public_ip} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.private_ssh_key}" >> ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory;
echo "" >> ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory;
echo "[gitlab:vars]" >> ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory;
echo "ssl_cert = ${var.ssl_cert_file}" >> ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory;
echo "ssl_key = ${var.ssl_cert_key}" >> ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory;
%{for k, v in var.ansible_vars~}
echo "${k} = ${v}" >> ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory;
%{endfor~}
  EOT
    #     command = <<EOT
    # echo "[gitlab]" > ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory;
    # echo "${aws_instance.instance.public_ip} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.private_ssh_key}" >> ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory;
    # echo "\n\n[gitlab:vars]" > ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory;
    # EOT
    # echo "${var.ansible_vars}" > ./ansible-${var.namespace}-${var.stage}-${var.name}.inventory;
    # We need to make sure the additional volume is attached first before running playbook -> see: aws_volume_attachment.persistent_storage
  }

  # provisioner "remote-exec" {
  #   when = "destroy"
  #   inline = [
  #     "sudo docker stop $(docker ps -a -q)",
  #     "sudo umount /mnt/gitlab-data"
  #   ]
  # }

  tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}"
    NameSpace = var.namespace
    Stage     = var.stage
  }

  volume_tags = {
    Name      = "${var.namespace}-${var.stage}-${var.name}-root-volume"
    NameSpace = var.namespace
    Stage     = var.stage
  }
}

/*
 * Create the security group that's applied to the EC2 instance
 */
resource "aws_security_group" "instance" {
  name = "${var.namespace}-${var.stage}-${var.name}-sec-grp"

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound SSH from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = var.name
    NameSpace = var.namespace
    Stage     = var.stage
  }
}
