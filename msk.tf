module "msk_cluster" {
  source = "terraform-aws-modules/msk-kafka-cluster/aws"

  name                   = "${local.name}-MSK-Cluster"
  kafka_version          = "3.6.0"
  number_of_broker_nodes = 3

  encryption_in_transit_client_broker = "PLAINTEXT"

  configuration_server_properties = {
    "auto.create.topics.enable" = true
    "delete.topic.enable"       = true
  }

  broker_node_client_subnets  = module.vpc.private_subnets
  broker_node_instance_type   = "kafka.m5.xlarge"
  broker_node_security_groups = [module.security_group.security_group_id]

  tags = local.tags
}
