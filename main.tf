
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  enable_dns_support= true
  enable_dns_hostnames= true
  tags=merge(var.tags,{"Name"="${var.env}-vpc"})
}

module "subnets" {
  source = "./subnets"
  for_each = var.subnets
  cidr_block = each.value["cidr_block"]
  azs = each.value["azs"]
  env = var.env
  name = each.value["name"]
  tags = var.tags
  vpc_id = aws_vpc.main.id
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags,{"Name"="${var.env}-igw"})

}