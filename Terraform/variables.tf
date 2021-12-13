variable "project" {
  description = "Project tag."
  default     = "Raylytic"
}
variable "key_name" {
  description = "This will be the keyname"
  default     = "raylytic"
}
variable "ingressrules" {
  type    = list(number)
  default = [80, 443, 22, 8080]
}
