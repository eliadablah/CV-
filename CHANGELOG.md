# Changelog

## 2026-10-15

### Content — Align experience and projects with current resume

- EZLynx (Applied Systems) title now reads `IT Support Technician III`, with
  bullets for tier-three escalations, plain-language fixes, engineering
  escalations and ticket-trend spotting.
- Novrupt entry now reads `Cloud Engineering Intern`, `Dec 2025 – May 2026`,
  Dallas, TX (Remote). The About bio and FAQ chat call it an internship.
- Mercor title now reads `AI Generalist Expert · Contract`, with bullets for
  grading AI responses, validating AI-generated scripts, and writing reference
  troubleshooting solutions.
- Southside Bank support bullet now includes connectivity issues.
- Added project cards for "Scalable Serverless Web Application" and
  "CI/CD Pipeline Implementation"; the FAQ "projects" answer mentions them.

## 2026-10-06

### CI/CD — Point the deploy pipeline at the `CV-` repository

- The deploy role's trust policy now accepts GitHub Actions runs from the
  `main` branch of `eliadablah/CV-` (it previously named `eliadablah/eliadablahcv`).
- Replaced the `github_repo` variable with `github_oidc_subject_prefix`. GitHub
  issues this repository's OIDC subject in its immutable form, with the owner
  and repository IDs included (`repo:eliadablah@232940632/CV-@1408079494`), so
  a trust rule written with names alone never matches.
- Applied with Terraform: in-place changes to `aws_iam_role.deploy` only.
- Added the six repository variables the workflow reads (`AWS_ROLE_ARN`,
  `ECR_REPOSITORY_URL`, `LAMBDA_FUNCTION_NAME`, `FRONTEND_BUCKET`,
  `DISTRIBUTION_ID`, `SITE_URL`) to `CV-`.

### Content — Add UTC student portal project

- Added a third project card, "UTC Student Portal: 3-Tier AWS Network", linking to `https://github.com/eliadablah/utcapp`.
- FAQ chat "projects" answer now mentions all three projects.

## 2026-10-05

### Content — End Mercor Generalist Expert role

- Experience entry now reads `Aug 2026 – Oct 2026`; removed the "Current" pill and moved the bullets to past tense.
- FAQ chat "experience" answer no longer describes the Mercor contract as current.
