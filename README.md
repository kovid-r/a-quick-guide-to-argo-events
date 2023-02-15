## Installing Argo Events

You have several options for installing Argo Events. This tutorial will take you through the installation process using `kubectl`. Alternatively, you can use [Kustomize](https://argoproj.github.io/argo-events/installation/#using-kustomize) or [Helm](https://argoproj.github.io/argo-events/installation/#using-helm-chart) to complete the installation.

### Deploy Kubernetes on your local machine using Minikube

Before installing Argo Events, you need to ensure that the Minikube context is up and running on the Docker Engine. You can use the following commands to install and start Minikube on your machine:

```shell
# Get Minikube for your AMD64-based machine.
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube
# Start Minikube
minikube start
```

You're now ready to install Argo Events.

### Create the namespace

Namespaces in Kubernetes are used to isolate groups of resources in a cluster. Kubernetes comes with a `default` namespace, but it's good practice to create a separate namespace. Using the following command, create a namespace called `argo-events`:

```shell
kubectl create namespace argo-events
```

All services and pods related to EventSources, Sensors, and Triggers, will be created in this namespace.

### Run the installation in the `argo-events` namespace

You can use the following command to run the installation:

```shell
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml
```

Now that the ServiceAccount, cluster role bindings, and the controllers are created, you need to deploy at least one instance of each to see Argo Events in action.

### Deploying the EventBus

A Kubernetes custom resource called EventBus delivers messages from EventSources to Sensors. It's essentially a source and target-agnostic pubsub system, where EventSources publish events and Sensors subscribe to those events to take further action, for instance, trigger Argo Workflows.

The following command retrieves the configuration file from the [Argo Project website](https://argoproj.github.io/) and creates the EventBus:

```shell
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml
```

The EventBus specification defaults the number of replicas to three, so one service and three pods are created after you run the command.

#### Deploying a webhook EventSource

EventSources are responsible for publishing messages accumulated in the EventBus for Sensors to consume. As mentioned earlier in the tutorial, there are several EventSources, such as AWS SNS, AWS SQS, Google Cloud PubSub, GitHub, Slack, Webhooks, etc.

The following command installs a basic webhook EventSource:

```shell
kubectl apply -n argo-events -f webhook-event-source.yaml
```

A webhook source is an EventSource that works via a general-purpose REST API context, which is used in many other EventSources, such as Stripe, Slack, AWS SNS, GitLab, GitHub, BitBucket, and so on.

### Deploying a webhook Sensor

Sensors don't just listen to events; they also act on those events to trigger actions. Sensors, therefore, are a combination of events and triggers. For example, AWS Lambda is a sensor; it will listen to any given EventSource and trigger an action based on the events from that EventSource. 

Use the following command to create a webhook Sensor:

```shell
kubectl apply -n argo-events -f webhook-sensor.yaml
```

This command results in the deployment of the webhook Sensor, which runs in a new Kubernetes pod.

Now that you have the basic framework for listening to events, passing them on, and triggering workflows based on those events, you should be able to trigger workflows using sample events. The next section will take you through working with Argo Events.

### Using Argo Events

If you've succeeded in running the commands in the previous sections, you should be able to test your installation using the following command, which will list the service for the EventSource:

```shell
kubectl -n argo-events get services
```

While the services and pods are up and running, you'll need to set up port forwarding for message delivery and consumption over HTTP. 

To set up port forwarding, you need to get the pod name of the webhook EventSource and store it in the `EVENT_SOURCE_POD_NAME` variable using the following command:

```shell
export EVENT_SOURCE_POD_NAME=$(kubectl -n argo-events get pods - no-headers -o custom-columns=":metadata.name" | grep webhook-eventsource)
```

Now, use the following command to establish port forwarding:

```shell
kubectl -n argo-events port-forward $EVENT_SOURCE_POD_NAME 12000:12000 &
```

Once port forwarding is successfully set up, your Argo Events should be able to receive requests and trigger the creation of Kubernetes resources to service those requests.

### Triggering workflows

In the following example, you'll submit a POST request to the EventSource pod, listening at port 12000:

```shell
curl -d '{"message":"This is the first message from Argo!"}' -H "Content-Type: application/json" -X POST http://localhost:12000/app
```

This POST request to the EventSource triggers a message to be published to the EventBus, which, in turn, triggers the Sensor to create a new pod to complete the workflow.

Sending the POST request a second time should create a second workload pod, as shown below:

```shell
curl -d '{"message":"This is the second message from Argo!"}' -H "Content-Type: application/json" -X POST http://localhost:12000/app
```

Use the following command to see the pod scheduling, creation, and run in action:

```shell
kubectl -n argo-events get events
```

For a more detailed version of events along with the pod details, use the following command:

```shell
kubectl -n argo-events describe pod <workload-pod-name>
```

Running the `kubectl describe` command will give you all the details of a pod, from specifications to events, as shown in the the command's output:

### Validating workflows

Finally, you can check whether your workflow succeeded by checking whether the message was published in the new pod using the following command:

```shell 
kubectl -n argo-events logs -l app=workload
```

This lists all the pod instances created for POST requests on the `app` hosted on your local machine, communicating over port 12000. It lists the outputs of all the workflows one after the other in ascending order.
