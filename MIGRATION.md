# Migration Guide: ABP v1 to v2

This guide documents how to migrate an existing ABP v1 Terraform module to the v2 GitHub Actions-based pipeline.

## Overview

ABP v2 replaces the in-repo pipeline automation (`.project_automation/`, `.project_config.yml`) with centralized reusable GitHub Actions workflows hosted in `aws-ia/.github`. Module repos contain only thin caller workflow files (~10 lines each) that invoke the central workflows.

## Coexistence Strategy

ABP v1 artifacts and v2 caller workflows can coexist in the same repository during the transition period. The v1 pipeline and v2 GitHub Actions workflows run independently and do not conflict. This allows you to verify v2 works before removing v1.

## Migration Sequence

### Step 1: Add v2 Caller Workflows

Copy the following files from this template into your module repository:

- `.github/workflows/static-tests.yml`
- `.github/workflows/functional-tests.yml`
- `.github/workflows/publication.yml`

Update `terraform-version` in each caller to match your module's `required_version` constraint.

If your module has application code (e.g., Lambda), uncomment `run-build-step: true` in the static and functional test callers.

### Step 2: Verify v2 Pipelines Work

1. Open a PR and verify the **Static Tests** workflow runs and passes
2. Comment `/do-e2e-tests` on the PR to trigger **Functional Tests**
3. Merge to `main`, bump `VERSION`, and verify the **Publication** workflow triggers

### Step 3: Remove ABP v1 Artifacts

Once v2 pipelines are verified, remove the following ABP v1 files:

- `.project_automation/` (entire directory)
- `.project_config.yml`
- `.copier-answers.yml`

### Step 4: Update CODEOWNERS

Update your `CODEOWNERS` file to include protection for the new paths:

```
* @aws-ia/aws-ia
.config/ @aws-ia/aws-ia
.github/workflows/ @aws-ia/aws-ia
```

## Additional Updates

### Add Makefile

Copy the `Makefile` from this template for local development targets (`make init`, `make validate`, `make lint`, `make docs`, `make security-scan`, etc.).

### .config/ Directory — No Changes Needed

The `.config/` directory (`.checkov.yml`, `.tflint.hcl`, `.mdlrc`, `.terraform-docs.yaml`, helper scripts) is compatible with both ABP v1 and v2. No changes are required during migration.

### Migrating tfsec Custom Checks to Checkov

tfsec is dropped in v2. If your module has custom tfsec checks in `.config/.tfsec/`:

1. Review each custom JSON check in `.config/.tfsec/`
2. Create equivalent Checkov custom policies in `.config/.checkov.yml` or as Python-based custom checks
3. Common mappings:
   - tfsec `required_labels` checks map to Checkov `CKV_AWS_*` tag checks
   - tfsec `encryption_at_rest` checks map to Checkov encryption-related checks
   - For complex custom logic, use [Checkov custom Python policies](https://www.checkov.io/3.Custom%20Policies/Python%20Custom%20Policies.html)
4. Remove `.config/.tfsec/` after porting all checks
5. Run `make lint` and Checkov locally to verify the new policies catch the same issues

### GitHub Environment Setup

Create the `publication` GitHub environment with required reviewers:

1. Go to **Settings** > **Environments** > **New environment**
2. Name it `publication`
3. Add required reviewers

### OIDC Federation

If your module's functional tests use AWS credentials, set up OIDC federation:

1. Create an IAM role with the trust policy scoped to `aws-ia/.github` reusable workflow path
2. Store the role ARN as repository secret `AWS_OIDC_ROLE_ARN`
