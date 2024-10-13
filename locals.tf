locals {
  all_private_route_ids = concat(module.subnets["web"].route_table_ids,module.subnets["app"].route_table_ids,module.subnets["db"].route_table_ids)
}