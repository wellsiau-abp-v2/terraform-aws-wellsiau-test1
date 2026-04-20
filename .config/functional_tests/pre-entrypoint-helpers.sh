#!/bin/bash
# Runs before functional tests (with AWS credentials available).
# Use this for: SSM parameter fetching, build steps (make all), region overrides.
# Example: fetch tfvars from SSM and write to tests/terraform.auto.tfvars
echo "Executing Pre-Entrypoint Helpers"
