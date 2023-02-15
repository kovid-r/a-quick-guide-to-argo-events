# Get Minikube for your AMD64-based machine.

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start

# Create Kubernetes namespace
kubectl create namespace argo-events

# Install Argo Events from the Argo Proj website
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/manifests/install.yaml

# Install the EventBus
kubectl apply -n argo-events -f https://raw.githubusercontent.com/argoproj/argo-events/stable/examples/eventbus/native.yaml

# Install the webhook EventSource
kubectl apply -n argo-events -f webhook-event-source.yaml

# Install the webhook Sensor
kubectl apply -n argo-events -f webhook-sensor.yaml
