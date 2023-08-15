This is a project carried out for zero paper.
I used terraform to create a vpc, private and public subnets with internet gateway in the public subnet and NAT gateway attached to an elastic Ip inthe private subnet.
I created an aws ec2 t2.micro instance with an auto scaling group launch configuration and put it behind an application load balancer with terraform.
Used ansible to bootstrap the instance to download docker, docker-compose (orchestration technology of choice) and other dependecies for the project.
Used the same ansible server to create a watcher script called watcher.sh which is attached to a cron job that runs every 2 hours.
I used created 2 dockerfiles, one in the sample-node-mongo-api directory, this one was for the nodejs application and another one in the nginx directory for the nginx container.
I created a default.conf file which has the nginx server configuration and port listening.
I created a docker-compose file in the parent directory where I orchestrated the nodejs app container, iniated a mongo db container and the nginx container on a network I created and called zer0network. 
