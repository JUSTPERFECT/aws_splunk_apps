variable  "region"                          {}
variable  "admin_cidr_block"                {}
variable  "vpc_id"                          {}
variable  "httpport"                        { default = 8000 }
variable  "ami"                             {}
variable  "instance_user"                   {}
variable  "key_name"                        {}
variable  "instance_type_indexer"           {}
variable  "subnets"                         {}
variable  "count_indexer"                   { default = 2 }
variable  "instance_type_searchhead"           {}
# SearchHead Autoscaling
variable  "asg_searchhead_desired"          { default = 1 }
variable  "asg_searchhead_min"              { default = 1 }
variable  "asg_searchhead_max"              { default = 1 }

variable  "availability_zones"              {}
