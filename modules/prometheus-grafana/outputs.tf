output "prometheus_service_name" {
  description = "Name of the Prometheus service"
  value       = kubernetes_service.prometheus.metadata[0].name
}

output "prometheus_namespace" {
  description = "Namespace where Prometheus is deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_service_name" {
  description = "Name of the Grafana service"
  value       = kubernetes_service.grafana.metadata[0].name
}

output "grafana_namespace" {
  description = "Namespace where Grafana is deployed"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "grafana_endpoint" {
  description = "Grafana service endpoint"
  value       = kubernetes_service.grafana.status[0].load_balancer[0].ingress[0].hostname
}
