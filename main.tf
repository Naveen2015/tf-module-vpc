
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

resource "aws_eip" "eip" {
  count = length(var.subnets["public"].cidr_block)
  domain = "vpc"
  tags = merge(var.tags,{"Name"="${var.env}-eip-${count.index+1}"})
}

resource "aws_nat_gateway" "ngw" {
  count = length(var.subnets["public"].cidr_block)
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = module.subnets["public"].subnet_ids[count.index]

  tags = merge(var.tags,{"Name"="${var.env}-ngw"})
}





resource "aws_route" "igw" {
  count= length(module.subnets["public"].route_table_ids)
  route_table_id            = module.subnets["public"].route_table_ids[count.index]
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

resource "aws_route" "ngw" {
  count= length(local.all_private_route_ids)
  route_table_id            = local.all_private_route_ids[count.index]

  nat_gateway_id = element(aws_nat_gateway.ngw.*.id,count.index )
  destination_cidr_block    = "0.0.0.0/0"
}

resource "aws_vpc_peering_connection" "peer" {
  peer_vpc_id   = var.default_vpc_id
  vpc_id        = aws_vpc.main.id
  auto_accept = true

}

resource "aws_route" "peering-connection-route" {
  count= length(local.all_private_route_ids)
  route_table_id            = element(local.all_private_route_ids,count.index)
vpc_peering_connection_id = aws_vpc_peering_connection.peer.id

  destination_cidr_block    = var.default_vpc_cidr
}

resource "aws_route" "peering-connection-route_in_default_vpc" {

  route_table_id            = var.default_vpc_rtid
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id

  destination_cidr_block    = var.cidr_block
}

