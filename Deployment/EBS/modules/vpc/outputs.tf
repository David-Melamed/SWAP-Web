output "aws_public_subnet" {
  value = aws_subnet.public_ebslab_subnet.*.id
}

output "vpc_id" {
  value = aws_vpc.ebslab_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.public_ebslab_subnet[*].id
}

output "subnet_availability_zones" {
  value = aws_subnet.public_ebslab_subnet[*].availability_zone
}

output "security_group_id" {
  value = [aws_security_group.ebslab_security_group.id]
}

output "sg_name" {
  value = aws_subnet.public_ebslab_subnet[0].tags["Name"]
}