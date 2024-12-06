provider "aws" {
  region = "us-east-1"
}

#Get Linux AMI ID using SSM Parameter endpoint in us-east-1
data "aws_ssm_parameter" "linuxAmi" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}


#Create and bootstrap EC2 in us-east-1
resource "aws_instance" "ec2-web-server" {
  depends_on = [aws_db_instance.databaseMariaDB]
  ami                         = data.aws_ssm_parameter.linuxAmi.value
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = ["sg-0873f119ac18c22cc"]
  subnet_id                   = "subnet-061b8ae1786bcfb35"
  key_name                    = "cscie90-hw2"
  user_data = file("userdata.sh")
  tags = {
    Name = "webServer"
    backup = "multier"
  }
}

resource "null_resource" "sleep_example" {
  depends_on = [aws_instance.ec2-web-server]

  provisioner "remote-exec" {
    inline = [
      "echo 'Sleeping for 30 seconds...'",
      "sleep 30",  # Sleep for 30 seconds
      "echo 'Sleep completed!'"
    ]

    connection {
      type        = "ssh"
      host        = aws_instance.ec2-web-server.public_ip
      user        = "ec2-user"
      private_key = file("./cscie90-hw2.pem")
    }
  }
}

# Copy the website.php to the EC2 instance
resource "null_resource" "copy_website" {
  depends_on = [aws_instance.ec2-web-server, null_resource.sleep_example]

  provisioner "file" {
    source      = "./website.php"                            # Local path of website.php
    destination = "/tmp/website.php"              # Destination path on the EC2 instance

    connection {
      type        = "ssh"
      host        = aws_instance.ec2-web-server.public_ip
      user        = "ec2-user"                             # Amazon Linux default user
      private_key = file("./cscie90-hw2.pem")        # Path to your private key
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/website.php /var/www/html/website.php"
      #"sudo chmod 644 /var/www/html/website.php"          # Ensure proper permissions for the file
    ]

    connection {
      type        = "ssh"
      host        = aws_instance.ec2-web-server.public_ip
      user        = "ec2-user"
      private_key = file("./cscie90-hw2.pem")
    }
  }
}

# Copy the dbinfo.inc to the EC2 instance
resource "null_resource" "copy_dbinfo" {
  depends_on = [aws_instance.ec2-web-server, null_resource.sleep_example, null_resource.copy_website]

  provisioner "file" {
    source      = "./dbinfo.inc"                            # Local path of dbinfo.inc
    destination = "/tmp/dbinfo.inc"              # Destination path on the EC2 instance

    connection {
      type        = "ssh"
      host        = aws_instance.ec2-web-server.public_ip
      user        = "ec2-user"                             # Amazon Linux default user
      private_key = file("./cscie90-hw2.pem")        # Path to your private key
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sed -i \"s/define('DB_SERVER', 'replace_me')/define('DB_SERVER', '${aws_db_instance.databaseMariaDB.address}')/\" /tmp/dbinfo.inc",
      "cat /tmp/dbinfo.inc",  # Log the modified file content
      "sudo mv /tmp/dbinfo.inc /var/www/inc/dbinfo.inc"
 
    ]

    connection {
      type        = "ssh"
      host        = aws_instance.ec2-web-server.public_ip
      user        = "ec2-user"
      private_key = file("./cscie90-hw2.pem")
    }
  }
}

# Copy the diagram.jpg to the EC2 instance
resource "null_resource" "copy_diagram" {
  depends_on = [aws_instance.ec2-web-server, null_resource.sleep_example]

  provisioner "file" {
    source      = "./diagram.jpg"                            # Local path of diagram.jpg
    destination = "/tmp/diagram.jpg"              # Destination path on the EC2 instance

    connection {
      type        = "ssh"
      host        = aws_instance.ec2-web-server.public_ip
      user        = "ec2-user"                             # Amazon Linux default user
      private_key = file("./cscie90-hw2.pem")        # Path to your private key
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv /tmp/diagram.jpg /var/www/html/diagram.jpg",
      #"sudo chmod 644 /var/www/html/diagram.jpg"          # Ensure proper permissions for the file
    ]

    connection {
      type        = "ssh"
      host        = aws_instance.ec2-web-server.public_ip
      user        = "ec2-user"
      private_key = file("./cscie90-hw2.pem")
    }
  }
}

output "public_ip" {
  value = aws_instance.ec2-web-server.public_ip
}

output "website_url" {
  value = "http://${aws_instance.ec2-web-server.public_ip}/website.php"
}

output "databse_endpoint" {
  value = aws_db_instance.databaseMariaDB.address
}


# RDS MariaDB Instance
resource "aws_db_instance" "databaseMariaDB" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mariadb"
  engine_version       = "10.11.9"
  instance_class       = "db.t3.micro"
  identifier           = "backend-db"

  db_name              = "mydb"
  username             = "admin"
  password             = "NBEr7fmcoSxZfCATpB57"

  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = false
  #db_subnet_group_name = true
  
  tags = {
    Name = "MariaDBInstance"
    backup = "multier"
  }
}