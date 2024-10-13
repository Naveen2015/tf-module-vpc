output "subnet_ids" {
  value = aws_subnet.main.*.id
}

output "route_table_ids" {
  value = aws_route_table.example.*.id
}

output "subnet_cidrs" {
  value = aws_subnet.main.*.cidr_block
}