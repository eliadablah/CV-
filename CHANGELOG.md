# Changelog

## 2026-10-06

### CI/CD — Point the deploy pipeline at the `CV-` repository

- `github_repo` now defaults to `eliadablah/CV-`, so the deploy role's trust
  policy accepts GitHub Actions runs from that repository's `main` branch.
- Applied with Terraform: one in-place change to `aws_iam_role.deploy`.
- Added the six repository variables the workflow reads (`AWS_ROLE_ARN`,
  `ECR_REPOSITORY_URL`, `LAMBDA_FUNCTION_NAME`, `FRONTEND_BUCKET`,
  `DISTRIBUTION_ID`, `SITE_URL`) to `CV-`.

### Content — Add UTC student portal project

- Added a third project card, "Student Portal on a 3-Tier AWS Network", linking to `https://github.com/eliadablah/utcapp`.
- FAQ chat "projects" answer now mentions all three projects.

## 2026-10-05

### Content — End Mercor Generalist Expert role

- Experience entry now reads `Aug 2026 – Oct 2026`; removed the "Current" pill and moved the bullets to past tense.
- FAQ chat "experience" answer no longer describes the Mercor contract as current.
