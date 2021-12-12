variable "project" {
  description = "Project tag."
  default     = "SynaOS"
}
variable "key_name" {
  description = "This will be the keyname"
  default     = "synaos"
}
variable "ingressrules" {
  type    = list(number)
  default = [80, 443, 22]
}