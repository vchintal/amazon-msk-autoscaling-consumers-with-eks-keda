# Amazon MSK Autoscaling Consumers with Keda on EKS

## Prerequisites:

Ensure that you have the following tools installed locally:
1. [kubectl](https://kubernetes.io/docs/tasks/tools/)
2. [helm](https://helm.sh/docs/intro/install/)
3. [jq](https://jqlang.github.io/jq/download/)

## Deploy

```sh 
# Git clone the repo and cd into it
git clone https://github.com/vchintal/amazon-msk-autoscaling-consumers-with-eks-keda
cd amazon-msk-autoscaling-consumers-with-eks-keda

# Terraform 
terraform init
terraform apply --auto-approve
```

The output should be similar to:

```
kafka_bootstrap_brokers = <<EOT

export BROKERS=b-1.kafkaconsumerasmskclu.kcqtt7.c14.kafka.us-west-2.amazonaws.com:9092,b-2.kafkaconsumerasmskclu.kcqtt7.c14.kafka.us-west-2.amazonaws.com:9092,b-3.kafkaconsumerasmskclu.kcqtt7.c14.kafka.us-west-2.amazonaws.com:9092

EOT
```

Run the embedded `export` command in the output above to set the environment 
variable `BROKERS`.

For example:
```sh
export BROKERS=b-1.kafkaconsumerasmskclu.kcqtt7.c14.kafka.us-west-2.amazonaws.com:9092,b-2.kafkaconsumerasmskclu.kcqtt7.c14.kafka.us-west-2.amazonaws.com:9092,b-3.kafkaconsumerasmskclu.kcqtt7.c14.kafka.us-west-2.amazonaws.com:9092
```

## Set up the environment

Update your local `kubeconfig` with the following command:
```sh
aws eks --region us-west-2 update-kubeconfig --name KafkaConsumerAS-EKS
```

Choose a topic name and run the following set of commands to:
1. Create the topic 
2. Deploy a consumer `kafka-consumer`
3. Deploy the Kafka ScaledObject `kafka-scaledobject` whose target is the 
`kafka-consumer`

```sh 
export TOPIC_NAME=sample-topic
export BROKERS_HELM=`echo $BROKERS | sed 's/,/\\\\,/g'`

# Create the Kafka topic
kubectl -n kafka-clients run kafka-topic-creator -ti \
--image=quay.io/strimzi/kafka:0.39.0-kafka-3.6.1 \
--rm=true --restart=Never -- bin/kafka-topics.sh \
--create --bootstrap-server $BROKERS \
--replication-factor 2 --partitions 5 --topic $TOPIC_NAME

# Deploy the Kafka consumer and Kafka ScaledObject
helm repo add kedacore https://kedacore.github.io/charts
helm repo update 
helm install kafka-clients kafka-clients/ -n kafka-clients \
--set kafka.bootstrapServers=$BROKERS_HELM --set kafka.topicName=$TOPIC_NAME
```

## Testing

1. Check on the # of consumer pods by running the command:
   ```sh
   kubectl get pods -n kafka-clients
   ```
   Output should be similar to:
   ```
   NAME                              READY   STATUS    RESTARTS   AGE
   kafka-consumer-596fb8db7f-kdcf7   1/1     Running   0          6m13s
   ```
2. Check on the scaled object `kafka-scaledobject`
   ```sh 
   kubectl get scaledobject -n kafka-client
   ```
   Output should be similar to:
   ```
   NAME                 SCALETARGETKIND      SCALETARGETNAME   MIN   MAX   TRIGGERS   AUTHENTICATION   READY   ACTIVE   FALLBACK   PAUSED    AGE
   kafka-scaledobject   apps/v1.Deployment   kafka-consumer    1     50    kafka                       True    False    False      Unknown   8m21s
   ```
3. Keep a continuous check on the pods with the following command in separate 
   terminal session:
   ```sh 
   watch -n2 kubectl get pods -n kafka-clients
   ```
4. Kick of the `kafka-producer-perf-test.sh` by running the following command
   ```sh 
   kubectl -n kafka-clients run kafka-producer -ti \
   --image=quay.io/strimzi/kafka:0.39.0-kafka-3.6.1 --rm=true --restart=Never -- \
   bin/kafka-producer-perf-test.sh --topic sample-topic-2 --num-records 3000000 \
   --producer-props acks=all bootstrap.servers=$BROKERS \
   --throughput -1 --record-size 1024
   ```
5. Check on the output of the # of consumer pods in the other session. You should
   see output similar to:
   ```
   Every 2.0s: kubectl get pods -n kafka-clients                          

   NAME                              READY   STATUS    RESTARTS   AGE
   kafka-consumer-7f8979c855-2jcn9   1/1     Running   0          9s
   kafka-consumer-7f8979c855-ch2pl   1/1     Running   0          9s
   kafka-consumer-7f8979c855-fwswc   1/1     Running   0          20m
   kafka-consumer-7f8979c855-pch8w   1/1     Running   0          9s
   kafka-producer                    1/1     Running   0          15s
   ```