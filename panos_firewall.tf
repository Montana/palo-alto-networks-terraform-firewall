provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}

resource "random_string" "randPass" {
    length = 15
    lower = true
    upper = true
    number = true
    special = false
}

resource "random_string" "sgName" {
    length = 10
    number = false
    special = false
}

resource "aws_security_group" "sg" {
    name = "${random_string.sgName.result}"
    description = "Lab security group"

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow SSH"
    }

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow HTTPS"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "panos" {
    ami = "${var.panos_ami}"
    instance_type = "m4.xlarge"
    key_name = "${var.aws_ssh_key_name}"
    security_groups = ["${aws_security_group.sg.name}"]
    ebs_block_device {
        device_name = "/dev/xvda"
        volume_type = "gp2"
        delete_on_termination = true
        volume_size = 60
    }
}
resource "null_resource" "fwinit" {
    triggers {
        key = "${aws_instance.panos.public_ip}"
    }
    provisioner "local-exec" {
        command = "ansible-playbook setpass.yml -extra-vars ‘fw_address=${aws_instance.panos.public_ip} fw_keyfile=${var.aws_ssh_key_name} fw_password=${random_string.randPass.result}’"
    }
}
output "panos_ip" {
    value = "${aws_instance.panos.public_ip}"
}

output "panos_password" {
    value = "${random_string.randPass.result}"
}
