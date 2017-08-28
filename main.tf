# Specify the provider and access details
provider "aws" {
  region = "${var.region}"
}

#security Groups

resource "aws_security_group" "all" {
    name        = "sg_splunk_all"
    description = "Common rules for all"
    vpc_id      = "${var.vpc_id}"
    # Allow SSH admin access
    ingress {
        from_port   = "22"
        to_port     = "22"
        protocol    = "tcp"
        cidr_blocks = ["${var.admin_cidr_block}"]
    }
    # Allow Web admin access
    ingress {
        from_port   = "${var.httpport}"
        to_port     = "${var.httpport}"
        protocol    = "tcp"
        cidr_blocks = ["${var.admin_cidr_block}"]
    }
    # full outbound  access
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group_rule" "interco" {
    # Allow all ports between splunk servers
    type                        = "ingress"
    from_port                   = "0"
    to_port                     = "0"
    protocol                    = "-1"
    security_group_id           = "${aws_security_group.all.id}"
    source_security_group_id    = "${aws_security_group.all.id}"
}


resource "aws_security_group" "searchhead" {
    name             = "sg_splunk_searchhead"
    description      = "Used in the  terraform"
    vpc_id           = "${var.vpc_id}"
    #HTTP  access  from  the  ELB
    ingress {
        from_port        = "${var.httpport}"
        to_port          = "${var.httpport}"
        protocol         = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

#master

resource "aws_instance" "master" {
    connection {
        user = "${var.instance_user}"
    }
    tags {
        Name = "splunk_master"
    }
    ami                         = "${var.ami}"
    instance_type               = "${var.instance_type_indexer}"
    key_name                    = "${var.key_name}"
    subnet_id                   = "${element(split(",", var.subnets), "0")}"
    user_data                   = "${file("master.sh")}"
    vpc_security_group_ids      = ["${aws_security_group.all.id}"]
}




#Indexers


resource "aws_instance" "indexer" {
    count                       = "${var.count_indexer}"
    connection {
        user = "${var.instance_user}"
    }
    tags {
        Name = "splunk_indexer"
    }
    ami                         = "${var.ami}"
    instance_type               = "${var.instance_type_indexer}"
    key_name                    = "${var.key_name}"
    subnet_id                   = "${element(split(",", var.subnets), count.index)}"
    user_data                   = "${file("slave.sh")}"
    vpc_security_group_ids      = ["${aws_security_group.all.id}"]
}




###################### searchhead autoscaling part ######################
resource "aws_launch_configuration" "searchhead" {
    name = "lc_splunk_searchhead"
    connection {
        user = "${var.instance_user}"
    }
    image_id                    = "${var.ami}"
    instance_type               = "${var.instance_type_searchhead}"
    key_name                    = "${var.key_name}"
    user_data                   = "${file("searchhead.sh")}"
    security_groups             = ["${aws_security_group.all.id}", "${aws_security_group.searchhead.id}"]
}

resource "aws_autoscaling_group" "searchhead" {
    name = "asg_splunk_searchhead"
    availability_zones         = ["${split(",", var.availability_zones)}"]
    vpc_zone_identifier        = ["${split(",", var.subnets)}"]
    min_size                   = "${var.asg_searchhead_min}"
    max_size                   = "${var.asg_searchhead_max}"
    desired_capacity           = "${var.asg_searchhead_desired}"
    health_check_grace_period  = 300
    health_check_type          = "EC2"
    launch_configuration       = "${aws_launch_configuration.searchhead.name}"
    tag {
        key                 = "Name"
        value               = "splunk_searchhead"
        propagate_at_launch = true
    }
}
