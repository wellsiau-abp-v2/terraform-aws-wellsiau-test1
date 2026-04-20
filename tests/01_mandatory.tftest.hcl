# This is the minimum mandatory test file required by the functional tests workflow.
# It validates that examples/basic/ can be planned and applied successfully.
#
# Authors should create additional .tftest.hcl files for custom test scenarios.
# All .tftest.hcl files in tests/ are auto-discovered by `terraform test`.

provider "aws" {
  region = "us-east-1"
}

run "mandatory_plan_basic" {
  command = plan

  module {
    source = "./examples/basic"
  }
}

run "mandatory_apply_basic" {
  command = apply

  module {
    source = "./examples/basic"
  }
}
