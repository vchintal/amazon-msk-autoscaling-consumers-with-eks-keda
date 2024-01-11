provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name   = "KafkaConsumerAS"
  region = "us-west-2"

  vpc_cidr = "10.0.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  keda_chart_url     = "https://kedacore.github.io/charts"
  keda_chart_version = "2.12.1"

  tags = {
    Name       = local.name
    Blueprint  = local.name
    GithubRepo = "github.com/aws-samples/amazon-msk-autoscaling-consumers-with-eks-keda"
  }
}
