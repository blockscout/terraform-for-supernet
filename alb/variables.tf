variable "name" {
  type = string
}
variable "internal" {
  type = bool
}
variable "vpc_id" {
  type = string
}
variable "subnets" {
  type = list(any)
}
variable "security_groups" {
  type = string
}
variable "name_prefix" {
  type = string
}
variable "backend_port" {
  type = string
}
variable "health_check_path" {
  type = string
}
variable "tags" {
  type = any
}
variable "ssl_certificate_arn" {
  type    = string
  default = ""
}