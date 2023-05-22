# Terraform Web Server

Source course; [Terraform Course - Automate your AWS cloud infrastructure](https://www.youtube.com/watch?v=SLB_c_ayRMo&ab_channel=freeCodeCamp.org)

## How to run

1. Setup your AWS credentials
2. Run the following commands:

```
terraform init
terraform plan -out plan.out
terraform apply plan.out
```

3. Connect to the web server using the public IP address (must change the keypair public key in the `main.tf` file)
```
ssh -i ~/.ssh/terraform.pem ubuntu@<public_ip>
```

4. Have fun!
