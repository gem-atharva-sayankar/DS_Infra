



output "swagger_endpoint" {
  value       = "${module.alb_server.dns_alb}/api/docs"
  description = "Copy this value in your browser in order to access the swagger documentation"
}
