# terraform-ASG-architecture
## Build a two tier architecture with Auto Scaling Group that scale up or down based on the CPU utilisation.

## For higher Availability, created three public and private subnet on all the AZs in given region. 
## One Jump server which is connected to public subnet with  a security group allow only SSH connection, however the ASG Auto scaling group has been connected to private subnets which has no internet gateway, this way the app server configured on the ASG will be secured.
## However, for the client to access the app via http request, Nat Gateway has been set up and connected to private subnet, thus client/cutomers can access the appserver.
