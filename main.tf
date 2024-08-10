resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = merge(var.tags, {Name="${var.env}-vpc"})

}

module "subnets"
{
  source="./subnets"

  vpc_id = aws_vpc.main.id
  for_each = var.subnets
  cidr_block = each.value["cidr_block"]
  azs = each.value["azs"]
  tags=var.tags
  env = var.env
  name = each.value["name"]

}