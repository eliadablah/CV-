# How I put this site on AWS

I run these steps myself, in order. Each step says what it does and what I
should see.

## Before I start

I need these installed: Terraform 1.10 or newer, Docker Desktop (running), and
the AWS CLI.

Check that I'm logged in to the right AWS account:

```bash
aws sts get-caller-identity
```

I should see my account number.

Two things to check first:

- **My certificate.** It has to cover `cv.eliadablah.com` (for example a
  `*.eliadablah.com` certificate). If it doesn't, I ask AWS for a new one in
  Certificate Manager, in us-east-1, before I go on.
- **GitHub login provider.** If my AWS account already has the GitHub OIDC
  provider, I add `create_github_oidc_provider = false` to `terraform.tfvars`.

## Step 1: Add my email

In the `terraform` folder, I copy `terraform.tfvars.example`, name the copy
`terraform.tfvars`, and put my real email in it. This is where inquiries,
alarms and budget warnings are sent.

## Step 2: Get Terraform ready

```bash
cd terraform
terraform init
```

I should see "Terraform has been successfully initialized". Nothing is created yet.

## Step 3: Create the image store first

Lambda can't be created until my image exists, so I make the place to put it first.

```bash
terraform apply -target=aws_ecr_repository.api
```

Terraform shows 1 thing to add. I type `yes`.

## Step 4: Build my API image and upload it

First I get the address of my image store:

```bash
terraform output -raw ecr_repository_url
```

In the next three commands, I replace `<ecr_url>` with that address.

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ecr_url>
```

I should see "Login Succeeded".

```bash
docker build --platform linux/amd64 --provenance=false -t <ecr_url>:bootstrap ../backend
```

```bash
docker push <ecr_url>:bootstrap
```

## Step 5: Create everything else

```bash
terraform apply
```

Terraform lists everything it will create. I read the list, then type `yes`.
CloudFront is slow, so this can take 5 to 15 minutes.

When it finishes it prints my outputs, like `site_url` and `frontend_bucket`.
I can print them again any time:

```bash
terraform output
```

## Step 6: Click two emails from AWS

AWS sends me two emails. Nothing gets emailed to me until I click both.

1. **Amazon SES** - proves the email address is mine. Needed for inquiries.
2. **AWS Notifications (SNS)** - turns on my error alerts.

## Step 7: Upload my site

I replace `<frontend_bucket>` with the `frontend_bucket` output.

```bash
aws s3 sync ../frontend s3://<frontend_bucket>
```

## Step 8: Check that it works

I open https://cv.eliadablah.com in my browser. Then I check:

- The page loads with its styles and my photo.
- The visitor count shows at the bottom.
- I send myself a test inquiry and it arrives in my inbox.

I can also check that my API is alive:

```bash
curl https://cv.eliadablah.com/api/health
```

I should see `{"status": "ok"}`.

## Step 9: Turn on automatic deploys

1. I push this folder to my GitHub repository `eliadablah/eliadablahcv`.
2. In GitHub I go to Settings > Secrets and variables > Actions > Variables
   and add these, using my Terraform outputs:

| Variable | Terraform output |
|---|---|
| `AWS_ROLE_ARN` | `github_deploy_role_arn` |
| `ECR_REPOSITORY_URL` | `ecr_repository_url` |
| `LAMBDA_FUNCTION_NAME` | `lambda_function_name` |
| `FRONTEND_BUCKET` | `frontend_bucket` |
| `DISTRIBUTION_ID` | `frontend_distribution_id` |
| `SITE_URL` | `site_url` |

From now on, every push to `main` tests and deploys my site by itself.

## Step 10: Point my old site at the new one

I only do this after Step 8 works.

I copy `github-pages-redirect/index.html` over the `index.html` in my
`eliadablah.github.io` repository and push it. Anyone who opens the old
address is sent to `cv.eliadablah.com`.

## How I turn it all off

This deletes everything this project made and stops all charges for it.

```bash
terraform destroy
```
