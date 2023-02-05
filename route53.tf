variable "dns" {
  default     = "ijustwanttobechairman.me"
  type        = string
  description = "Domain name"
}


# get hosted zone details
resource "aws_route53_zone" "hosted_zone" {
  name = var.dns
  tags = {
    Environment = "dev"
  }
}

# create a record set in route 53
# terraform aws route 53 record
resource "aws_route53_record" "domain" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "mini-project.${var.dns}"
  type    = "A"
  alias {
    name                   = aws_lb.mini-LB.dns_name
    zone_id                = aws_lb.mini-LB.zone_id
    evaluate_target_health = true
  }
}

