# Define the private cloud

resource "aws_vpc" "allopen-vpc" {

  cidr_block = "10.0.0.0/16"

  enable_dns_support = true

  enable_dns_hostnames = true

}

# Create a gateway to the internet

resource "aws_internet_gateway" "allopen-ig" {

  vpc_id = aws_vpc.allopen-vpc.id

}

# Allow connections to route to the internet

resource "aws_route" "internet-route" {

  route_table_id = aws_vpc.allopen-vpc.main_route_table_id

  destination_cidr_block = "0.0.0.0/0"

  gateway_id = aws_internet_gateway.allopen-ig.id

}

# Scan AWS and get the "available" availability zones

data "aws_availability_zones" "available" {

  state = "available"

}

# For each available zone, create a subnet.

resource "aws_subnet" "allopen-subnets" {

  count = length(data.aws_availability_zones.available.names)

  vpc_id = aws_vpc.allopen-vpc.id

  cidr_block = "10.0.${count.index}.0/24"

  map_public_ip_on_launch = true

  availability_zone = element(data.aws_availability_zones.available.names, count.index)

}

resource "aws_db_subnet_group" "postgresql_subnet_group" {

  name = "allopensubgroup"

  description = "Postgres database open to the world"

  subnet_ids = aws_subnet.allopen-subnets.*.id

}

# Create a security group within the VPC that allows for open connetions in and out

resource "aws_security_group" "allopen-sg" {

  name = "allopen-sg"

  description = "AllOpen security group"

  vpc_id = aws_vpc.allopen-vpc.id

  # Allow all inbound traffic

  ingress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  # Allow all outbound traffic.

  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

}

resource "aws_db_instance" "prod-postgres-db" {

  depends_on = [aws_internet_gateway.allopen-ig]

  allocated_storage = 20

  max_allocated_storage = 150

  vpc_security_group_ids = [aws_security_group.allopen-sg.id]

  db_subnet_group_name = aws_db_subnet_group.postgresql_subnet_group.name

  engine = "postgres"

  engine_version = "14.5"

  instance_class = "db.t3.micro"

  db_name = var.rds_db_name

  username = var.rds_user_name

  password = var.rds_user_password

  publicly_accessible = true

  skip_final_snapshot = true

  allow_major_version_upgrade = true

  auto_minor_version_upgrade = true

  performance_insights_enabled = true

  apply_immediately = true

} 
