data "external" "PowerShellScript" {

    #program = ["pwsh", "-Command", "${path.module}\\scripts\\ReadSecureString.ps1", var.file_path]
    program = ["powershell", "-Command", "${path.module}/scripts/ReadSecureString.ps1", var.file_path]
}