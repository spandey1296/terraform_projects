terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"  # Choose your desired region
  
}

# Get the most recent amazon linux image

data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

# Creating security group for jenkins instence
resource "aws_security_group" "jenkins_sg" {
  name = "jenkins_security_group"

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "JenkinsSecurityGroup"
  }
}

resource "aws_security_group_rule" "allow_all_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins_sg.id
}

resource "aws_security_group_rule" "allow_ssh" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.jenkins_sg.id
}

# Creating EC2 Instance and attaching security group and ssh key to it with installation script of Jenkins
resource "aws_instance" "ec2_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  key_name      = "devops_sample_project"
  security_groups = [aws_security_group.jenkins_sg.name]
  user_data = <<EOF
#!/bin/bash
sudo wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum update -y
sudo yum upgrade -y
sudo yum install epel-release //fails
sudo amazon-linux-extras install epel
sudo amazon-linux-extras install java-openjdk11
sudo yum install jenkins -y
sudo yum install git -y
sudo iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
sudo systemctl start jenkins
sleep 30
url=http://localhost:8080
password=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

# NEW ADMIN CREDENTIALS URL ENCODED USING PYTHON
username=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< "admin")
new_password=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< "password")
fullname=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< "ABC")
email=$(python -c "import urllib;print urllib.quote(raw_input(), safe='')" <<< "abc@abc.com")

# GET THE CRUMB AND COOKIE
cookie_jar="$(mktemp)"
full_crumb=$(curl -u "admin:$password" --cookie-jar "$cookie_jar" $url/crumbIssuer/api/xml?xpath=concat\(//crumbRequestField,%22:%22,//crumb\))
arr_crumb=($${full_crumb//:/ })
only_crumb=$(echo $${arr_crumb[1]})

# MAKE THE REQUEST TO CREATE AN ADMIN USER
curl -X POST -u "admin:$password" $url/setupWizard/createAdminUser \
        -H "Connection: keep-alive" \
        -H "Accept: application/json, text/javascript" \
        -H "X-Requested-With: XMLHttpRequest" \
        -H "$full_crumb" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --cookie $cookie_jar \
        --data-raw "username=$username&password1=$new_password&password2=$new_password&fullname=$fullname&email=$email&Jenkins-Crumb=$only_crumb&json=%7B%22username%22%3A%20%22$username%22%2C%20%22password1%22%3A%20%22$new_password%22%2C%20%22%24redact%22%3A%20%5B%22password1%22%2C%20%22password2%22%5D%2C%20%22password2%22%3A%20%22$new_password%22%2C%20%22fullname%22%3A%20%22$fullname%22%2C%20%22email%22%3A%20%22$email%22%2C%20%22Jenkins-Crumb%22%3A%20%22$only_crumb%22%7D&core%3Aapply=&Submit=Save&json=%7B%22username%22%3A%20%22$username%22%2C%20%22password1%22%3A%20%22$new_password%22%2C%20%22%24redact%22%3A%20%5B%22password1%22%2C%20%22password2%22%5D%2C%20%22password2%22%3A%20%22$new_password%22%2C%20%22fullname%22%3A%20%22$fullname%22%2C%20%22email%22%3A%20%22$email%22%2C%20%22Jenkins-Crumb%22%3A%20%22$only_crumb%22%7D"


EOF   
   
  tags = {
    Name = "JenkinsInstance"
  }
}

output "instance_public_ip" {
  value = "http://${aws_instance.ec2_instance.public_ip}:8080"
}

# To show default userid and password and giving warning to change it
output "User_Name" {
  value = "admin"
}
output "Password" {
  value = "password"
}
output "change_password_warning" {
  value = "Please change the default password"
