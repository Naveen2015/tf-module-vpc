resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  tags = merge(var.tags, {Name="${var.env}-vpc"})

}

module "subnets" {
  source="./subnets"
  vpc_id = aws_vpc.main.id
  for_each = var.subnets
  cidr_block = each.value["cidr_block"]
  azs = each.value["azs"]
  tags=var.tags
  env = var.env
  name = each.value["name"]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {Name="${var.env}-igw"})
}

resource "aws_eip" "ngw" {
  count= length(var.subnets["public"].cidr_block)

  vpc   = true
  tags = merge(var.tags, {Name="${var.env}-ngw"})
}
resource "aws_nat_gateway" "ngw" {
  count= length(var.subnets["public"].cidr_block)

  allocation_id = aws_eip.ngw[count.index].id
  subnet_id     = module.subnets["public"].subnet_ids[count.index]
  tags = merge(var.tags, {Name="${var.env}-ngw"})

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route" "igw" {
  count = length(module.subnets["public"].route_table_ids)
  route_table_id = module.subnets["public"].route_table_ids[count.index]
  gateway_id = aws_internet_gateway.igw.id
  destination_cidr_block = "0.0.0.0/0"
}

