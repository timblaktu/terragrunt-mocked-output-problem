# terragrunt-mocked-output-problem

## Run this command to reproduce the problem:

```
AWS_PROFILE=my-profile \
REGION=us-west-1 \
BACKEND_S3_BUCKET=mytfstatebucket \
BACKEND_PREFIX=foo \
BACKEND_DYNAMODB_TABLE=mytfstatetable \
TF_WORKSPACE=whatevs \
TERRAGRUNT_LOG_LEVEL=debug \
    terragrunt run-all validate
```

See what error I got [here in /terragrunt-run-all-validate.script.colorless](https://github.com/timblaktu/terragrunt-mocked-output-problem/blob/main/terragrunt-run-all-validate.script.colorless#L254)).
