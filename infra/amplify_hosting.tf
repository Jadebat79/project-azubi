
# Amplify App
resource "aws_amplify_app" "tts" {
  name        = var.app_name
  repository  = var.repo
  oauth_token = var.github_token        # GitHub PAT with repo scope
  platform    = "WEB"

  # Monorepo build spec: points at your Vite app
  build_spec = <<-YAML
    version: 1
    applications:
      - appRoot: ${var.app_root}
        frontend:
          phases:
            preBuild:
              commands:
                - npm ci
            build:
              commands:
                - npm run build
          artifacts:
            baseDirectory: dist
            files:
              - '**/*'
          cache:
            paths:
              - node_modules/**/* 
  YAML
}

# Branch (sets env var for build: VITE_API_BASE)
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.tts.id
  branch_name = var.branch
  stage       = "PRODUCTION"
  enable_auto_build = true

  environment_variables = {
    VITE_API_BASE = aws_ssm_parameter.api_invoke_url.value
    # optionally: NODE_OPTIONS = "--max-old-space-size=4096"
  }
}

# (Optional) Domain association – add later if you have a custom domain
# resource "aws_amplify_domain_association" "domain" { ... }

output "branch_url"       { value = "${aws_amplify_branch.main.branch_name}.${aws_amplify_app.tts.default_domain}" }
output "vite_api_base"    { 
    value = aws_ssm_parameter.api_invoke_url.value 
    description = "API base URL from SSM for Vite app"
    sensitive = true
}
