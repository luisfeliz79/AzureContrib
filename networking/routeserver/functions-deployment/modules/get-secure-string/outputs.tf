output "value" {
  value = data.external.PowerShellScript.result.value
  sensitive = true
}