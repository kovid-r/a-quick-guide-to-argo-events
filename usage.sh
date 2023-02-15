# List Argo Events services
kubectl -n argo-events get services

# Store EventSource pod name in a variable
export EVENT_SOURCE_POD_NAME=$(kubectl -n argo-events get pods - no-headers -o custom-columns=":metadata.name" | grep webhook-eventsource)

# Set up portforwarding
kubectl -n argo-events port-forward $EVENT_SOURCE_POD_NAME 12000:12000 &

# Send the first POST request to app
curl -d '{"message":"This is the first message from Argo!"}' -H "Content-Type: application/json" -X POST http://localhost:12000/app

# Send the second POST request to app
curl -d '{"message":"This is the second messagefrom Argo!"}' -H "Content-Type: application/json" -X POST http://localhost:12000/app

# List all the events in the namespace
kubectl -n argo-events get events

# List all the pod-specific events in the namespace
kubectl -n argo-events describe pod <workload-pod-name>

# List all the events per workload in the namespace
kubectl -n argo-events logs -l app=workload
