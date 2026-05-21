terraform {
  # bucket is omitted — pass via: terraform init -backend-config=backend.hcl
  # See backend.hcl.example for the expected format.
  backend "s3" {
    key            = "staging/terraform.tfstate"
    region         = "sa-east-1"
    dynamodb_table = "truckr-tfstate-lock"
    encrypt        = true
  }
}
