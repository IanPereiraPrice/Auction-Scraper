variable "key_name" {
  type    = string
  default = "airflow-ec2-key"
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key_name
  public_key = tls_private_key.pk.public_key_openssh

  provisioner "local-exec" { # Create a "myKey.pem" to your computer!!
    command = "echo '${tls_private_key.pk.private_key_pem}' > ./myKey.pem"
  }
}


#Currently using an arm image to reduce costs

data "aws_ami" "airflow_ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_iam_role" "airflow_ec2_role" {
  name = "airflow-ec2-role"

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

  tags = {
    tag-key = "airflow-ec2"
  }
}

data "aws_iam_policy_document" "s3_read_permissions_for_ec2" {
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:ListBucket",
      "s3:PutObject"
    ]

    resources = ["${aws_s3_bucket.scraping-bucket.arn}",
      "${aws_s3_bucket.scraping-bucket.arn}/*",
    ]
  }
}

# Create EC2 role

resource "aws_iam_instance_profile" "airflow_ec2_profile" {
  name = "airflow_ec2_profile"
  role = aws_iam_role.airflow_ec2_role.name
}

# Declare the IAM role for the EC2 Instance
resource "aws_iam_role_policy" "ec2-s3-read-policy" {
  name   = "testing-ec2-profile"
  role   = aws_iam_role.airflow_ec2_role.name
  policy = data.aws_iam_policy_document.s3_read_permissions_for_ec2.json
}





#Creates ec2 instance, user data in file to pass variables into ec2 environment
#Previously using a .sh file resulted in errors in creating .env file
resource "aws_instance" "web" {
  ami                  = data.aws_ami.airflow_ubuntu.id
  instance_type        = "t4g.medium"
  iam_instance_profile = aws_iam_instance_profile.airflow_ec2_profile.name
  key_name             = aws_key_pair.generated_key.key_name

  user_data_replace_on_change = true
  #user_data                   = file("${path.module}/ec2_script/test_setup.sh")
  user_data = <<EOF
#!/bin/bash
echo "-------------------------START SETUP---------------------------"

echo "-----Installing Docker--------"
apt update -y
apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs)  stable"
apt update -y
apt-get -y install docker-ce
systemctl start docker
systemctl enable docker
groupadd docker
usermod -aG docker ubuntusudo docker pull nginx:latest
docker run --name mynginx1 -p 80:80 -d nginx

yes | docker system prune --all

echo "----------------Test Start----------------------------"
sudo chown $(whoami):$(whoami) /var/run/docker.sock

alias docker-compose = "docker compose"

git clone "https://github.com/IanPereiraPrice/Auction-Scraper.git"

cd Auction-Scraper

chmod -R u=rwx,g=rwx,o=rwx ec2-docker-image
cd ec2-docker-image

echo "-------------------Test End---------------------"

echo "
user=${var.rds_user_name}
passwd=${var.rds_user_password}
db_name=${var.rds_db_name}
port=${aws_db_instance.prod-postgres-db.port}
host=${aws_db_instance.prod-postgres-db.address}
drivername=${var.rds_drivername}
bucket-1=${aws_s3_bucket.scraping-bucket.id}
folder-1=search-dict/
folder-2=store-ids/
folder-3=ids-to-lambda/
file-search-dict=${aws_s3_object.scraped-search-ids.key}
region-name=${var.aws_region}
public-access-key=${var.aws_access_key}
private-key=${var.aws_secret_key}
" > .env

cd dags

echo "
user=${var.rds_user_name}
passwd${var.rds_user_password}
db_name=${var.rds_db_name}
port=${aws_db_instance.prod-postgres-db.port}
host=${aws_db_instance.prod-postgres-db.address}
drivername=${var.rds_drivername}
bucket-1=${aws_s3_bucket.scraping-bucket.id}
folder-1=search-dict/
folder-2=store-ids/
folder-3=ids-to-lambda/
file-search-dict=${aws_s3_object.scraped-search-ids.key}
region-name=${var.aws_region}
public-access-key=${var.aws_access_key}
private-key=${var.aws_secret_key}
" > .env

cd ..

cd transform/data_warehouse

echo "
user=${var.rds_user_name}
passwd${var.rds_user_password}
db_name=${var.rds_db_name}
port=${aws_db_instance.prod-postgres-db.port}
host=${aws_db_instance.prod-postgres-db.address}
drivername=${var.rds_drivername}

" > dbt.env

cd ..
cd ..

docker compose build && docker compose pull && docker compose up


echo "--------------------END SETUP----------------------"

EOF


}
