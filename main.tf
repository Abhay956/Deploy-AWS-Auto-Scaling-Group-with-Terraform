resource "aws_launch_template" "asg_ec2_template" {
  name                        = "template1"
  image_id                    = "ami-04b70fa74e45c3917"
  instance_type               = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.sg1.id]
  user_data                   = base64encode(file("user-data.sh"))
  tags = {
    Name = "Auto_scaling-instance"
  }

}

resource "aws_autoscaling_group" "ag" {
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = ["${aws_subnet.subnet1.id}"]
  tag {
    key                 = "Name"
    value               = "AG1"
    propagate_at_launch = true
  }
  launch_template {
    id      = aws_launch_template.asg_ec2_template.id
    version = aws_launch_template.asg_ec2_template.latest_version
  }
}

resource "aws_autoscaling_policy" "asg_policy_up" {
  name                   = "asg_policy_up"
  scaling_adjustment     = 3
  adjustment_type = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ag.name
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_alaram_up" {
    alarm_name          = "asg_cpu_alarm_up"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = "2"
    metric_name         =  "CPUUtilization"
    namespace = "AWS/EC2"
    period = "60"
    statistic = "Average"
    threshold = "70"

    dimensions = {
      autoscaling_group_name = "${aws_autoscaling_group.ag.name}"
    }
    alarm_description = "This metrics monitors e2 cpu utilization"
    alarm_actions = [aws_autoscaling_policy.asg_policy_up.arn]
}

resource "aws_autoscaling_policy" "asg_policy_down" {
  name                   = "asg_policy_down"
  scaling_adjustment     = 1
  adjustment_type = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ag.name
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_alaram_down" {
    alarm_name          = "asg_cpu_alarm_down"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = "2"
    metric_name         =  "CPUUtilization"
    namespace = "AWS/EC2"
    period = "60"
    statistic = "Average"
    threshold = "70"

    dimensions = {
      autoscaling_group_name = "${aws_autoscaling_group.ag.name}"
    }
    alarm_description = "This metrics monitors e2 cpu utilization"
    alarm_actions = [aws_autoscaling_policy.asg_policy_down.arn]
}

## vpc creation
resource "aws_vpc" "myvpc" {
  instance_tenancy = "default"
  cidr_block       = "100.100.0.0/16"
  tags = {
    Name = "VPC1"
  }
}

### gateway
resource "aws_internet_gateway" "mygw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "VPC1-IGW1"
  }
}
### Route Table
resource "aws_route_table" "myroute1" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygw.id
  }
}
## Subnet
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "100.100.100.0/24"
  tags = {
    Name = "VPC1-subnet1"
  }
}
## Route table Association
resource "aws_route_table_association" "myroute_asso" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.myroute1.id
}

## Security Group with HTTP and SSH Access
resource "aws_security_group" "sg1" {
  name        = "sg1"
  description = "Security Group for autoscaling"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "sg1"
  }
}
