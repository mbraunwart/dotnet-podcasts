output "db_password" {
    value = random_password.p.result
    description = "The password for the database"
    sensitive = true
}