output "LB-TG-arn" {
  value = aws_lb_target_group.mini-TG.arn
}

output "LB-dns-name" {
  value = aws_lb.mini-LB.dns_name
}

output "LB-zone-id" {
  value = aws_lb.mini-LB.zone_id
}