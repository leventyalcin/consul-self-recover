provider "aws" {
    region = "${var.aws_region}"
}

resource "aws_iam_role" "consul_iam_role" {
    name = "role-${var.tag_project}-${var.tag_service}-${var.tag_environment}"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "consul_iam_role_policy" {
    name = "policy-${var.tag_project}-${var.tag_service}-${var.tag_environment}"
    role = "${aws_iam_role.consul_iam_role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1455556909000",
            "Effect": "Allow",
            "Action": [
                "s3:ListAllMyBuckets"
            ],
            "Resource": [
                "arn:aws:s3:::*"
            ]
        },
        {
            "Sid": "Stmt1455556937000",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
              "arn:aws:s3:::${var.s3_repo_bucket}",
              "arn:aws:s3:::${var.s3_repo_bucket}/*"
            ]
        },
        {
            "Sid": "Stmt1455556984000",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstances",
                "ec2:DescribeTags",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "consul_ec2_profile" {
    name = "${var.tag_project}-${var.tag_service}-${var.tag_environment}"
    roles = ["${aws_iam_role.consul_iam_role.name}"]
}

resource "aws_security_group" "consul_sg" {
    name = "${var.tag_project}-${var.tag_environment}"
    description = "Consul internal traffic + maintenance."
    vpc_id = "${var.vpc_id}"

    // These are for internal traffic
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/8"]
    }
    ingress {
        from_port = 0
        to_port = 65535
        protocol = "udp"
        cidr_blocks = ["10.0.0.0/8"]
    }
    // These are for maintenance
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    // This is for outbound internet access
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
      Name        = "${var.tag_project}-${var.tag_service}-${var.tag_environment}"
      Environment = "${var.tag_environment}"
      Project     = "${var.tag_project}"
      Service     = "${var.tag_service}"
      Role        = "${var.tag_role}"
      Creator     = "${var.tag_creator}"
    }

}

resource "aws_launch_configuration" "consul_launch_configuration" {
  name = "${var.tag_project}-${var.tag_environment}"
  image_id = "${lookup(var.aws_amis, var.aws_region)}"
  iam_instance_profile = "${aws_iam_instance_profile.consul_ec2_profile.name}"
  instance_type = "${var.aws_instance_type}"
  associate_public_ip_address = false
  security_groups = ["${aws_security_group.consul_sg.id}"]
  user_data = "${file("userdata.sh")}"
  key_name = "${var.aws_key_name}"
}

resource "aws_autoscaling_group" "consul_asg" {
  name = "${var.tag_project}-${var.tag_environment}"
  max_size = "${var.cluster_size}"
  min_size = "${var.cluster_size}"
  desired_capacity = "${var.cluster_size}"
  force_delete = true
  launch_configuration = "${aws_launch_configuration.consul_launch_configuration.name}"
  vpc_zone_identifier = ["${var.subnet_az1_id}","${var.subnet_az2_id}","${var.subnet_az3_id}"]
  tag {
    key = "Name"
    value = "${var.tag_project}-${var.tag_environment}"
    propagate_at_launch = "true"
  }
  tag {
    key = "Environment"
    value = "${var.tag_environment}"
    propagate_at_launch = "true"
  }
  tag {
    key = "Project"
    value = "${var.tag_project}"
    propagate_at_launch = "true"
  }
  tag {
    key = "Service"
    value = "${var.tag_service}"
    propagate_at_launch = "true"
  }
  tag {
    key = "Role"
    value = "${var.tag_role}"
    propagate_at_launch = "true"
  }
  tag {
    key = "Creator"
    value = "${var.tag_creator}"
    propagate_at_launch = "true"
  }
}
