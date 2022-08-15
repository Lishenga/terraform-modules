resource "aws_security_group" "cluster" {
  name        = var.cluster_name
  vpc_id      = var.vpc_id
  description = var.cluster_name
}

resource "aws_security_group_rule" "cluster-allow-ssh" {
  count                    = var.enable_ssh ? 1 : 0
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  /* cidr_blocks              = ["0.0.0.0/0"] */
  source_security_group_id = var.ssh_sg
}

resource "aws_security_group_rule" "auth-microservice-port" {
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 3010
  to_port                  = 3010
  protocol                 = "tcp"
  source_security_group_id = var.ssh_sg
}

resource "aws_security_group_rule" "account-microservice-port" {
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 3011
  to_port                  = 3011
  protocol                 = "tcp"
  source_security_group_id = var.ssh_sg
}

resource "aws_security_group_rule" "client-microservice-port" {
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 3001
  to_port                  = 3001
  protocol                 = "tcp"
  source_security_group_id = var.ssh_sg
}

resource "aws_security_group_rule" "thing-microservice-port" {
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = var.ssh_sg
}

resource "aws_security_group_rule" "event-microservice-port" {
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 3002
  to_port                  = 3002
  protocol                 = "tcp"
  source_security_group_id = var.ssh_sg
}

resource "aws_security_group_rule" "event-microservice-port" {
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 3100
  to_port                  = 3100
  protocol                 = "tcp"
  source_security_group_id = var.ssh_sg
}

/*
resource "aws_security_group_rule" "cluster-loki-promtail" {
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 4100
  to_port                  = 4100
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "cluster-grafana" {
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "cluster-prometheus" {
  security_group_id        = aws_security_group.cluster.id
  type                     = "ingress"
  from_port                = 9090
  to_port                  = 9090
  protocol                 = "tcp"
} */

resource "aws_security_group_rule" "cluster-egress" {
  security_group_id = aws_security_group.cluster.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

/* resource "aws_security_group" "cluster" {
  name        = var.cluster_name
  vpc_id      = var.vpc_id
  description = var.cluster_name
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 3010
    to_port         = 3010
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster-securitygroup.id]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ecs-cluster"
  }
}

resource "aws_security_group" "cluster-securitygroup" {
  name        = "cluster-app-elb-security-group"
  vpc_id      = var.vpc_id
  description = var.cluster_name
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "cluster-app-elb-security-group"
  }
} */

