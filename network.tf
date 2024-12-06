# DB SG
resource "aws_security_group" "db_sg" {
  vpc_id = "vpc-0d7d6a899c951e34b"

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = ["sg-0873f119ac18c22cc"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DBServerSG"
  }
}