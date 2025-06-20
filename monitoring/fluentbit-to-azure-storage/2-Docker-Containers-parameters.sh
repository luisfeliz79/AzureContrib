# Docker Containers should push logs to FluentBit

# Example:
sudo docker run \
    --net host \
    --name mycontainer \
    --log-driver=fluentd \
    --log-opt tag="docker.{{.ID}}" \
    mycontainer:latest