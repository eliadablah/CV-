# This packs my API into a Docker image that AWS Lambda can run.
# I start from the official AWS Python image. It already has Python and boto3,
# so I only need to copy my code in.
FROM public.ecr.aws/lambda/python:3.13

COPY app/ ${LAMBDA_TASK_ROOT}/app/

# Lambda starts my code at lambda_handler() in app/handler.py
CMD ["app.handler.lambda_handler"]
