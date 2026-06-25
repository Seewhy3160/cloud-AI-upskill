# ---------------------------------------------------------------------------
# REMOTE STATE. The bucket and dynamodb_table values come from the OUTPUTS of
# the bootstrap stack. Edit the two lines marked CHANGE-ME, then run
# `terraform init`. (Backend blocks cannot use variables, so these are
# hard-coded on purpose.)
# ---------------------------------------------------------------------------
terraform {
  backend "s3" {
    bucket         = "CHANGE-ME-streamflix-tfstate" # <- bootstrap output: state_bucket_name
    key            = "streamflix/terraform.tfstate"
    region         = "us-east-1"           # <- region of the state bucket
    dynamodb_table = "streamflix-tf-locks" # <- bootstrap output: lock_table_name
    encrypt        = true
  }
}
