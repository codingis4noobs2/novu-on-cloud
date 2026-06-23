terraform {
  backend "s3" {
    # Rick & Morty reference
    bucket       = "youpassbutter" # Just make sure you create the bucket first and then run terraform init
    key          = "./terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
