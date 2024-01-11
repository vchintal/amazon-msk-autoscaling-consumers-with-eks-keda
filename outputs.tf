output "kafka_bootstrap_brokers" {
  description = "Command to get create an environment variable for the list of Kafka brokers"
  value       = <<-EOT
    export BROKERS=${module.msk_cluster.bootstrap_brokers_plaintext}
  EOT
}
