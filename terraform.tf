variable "aws_access_key" {
}
variable "aws_secret_key" {
}
variable "aws_region" {
  default = "ap-southeast-1"
}
variable "messenger_id" {
}
variable "slack_hook" {
}
variable "schedule" {
}
variable "message" {
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_iam_role" "iam_role_for_lambda" {
  name = "slack_cron_messenger_iam_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch_logs_policy_for_iam_role" {
  name = "cloudwatch_logs_policy_for_iam_role"
  role = "${aws_iam_role.iam_role_for_lambda.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

resource "aws_lambda_function" "messenger" {
  runtime = "python2.7"
  function_name = "${var.messenger_id}"
  handler = "messenger.main"
  role = "${aws_iam_role.iam_role_for_lambda.arn}"
  memory_size = 128
  timeout = 5
  filename = "build/messenger.zip"
  source_code_hash = "${base64sha256(file("build/messenger.zip"))}"
  environment {
    variables = {
      SLACK_HOOK = "${var.slack_hook}"
      MESSAGE = "${var.message}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "scheduled_run_rule" {
  name = "scheduled_run_${var.messenger_id}"
  schedule_expression = "${var.schedule}"
}

resource "aws_cloudwatch_event_target" "scheduled_run_target" {
  rule = "${aws_cloudwatch_event_rule.scheduled_run_rule.name}"
  target_id = "scheduled_run_target_${var.messenger_id}"
  arn = "${aws_lambda_function.messenger.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_messenger" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.messenger.function_name}"
  principal = "events.amazonaws.com"
  source_arn = "${aws_cloudwatch_event_rule.scheduled_run_rule.arn}"
}
