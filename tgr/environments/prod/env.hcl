locals {
  env = "prod"
  frontend_config = {
    CDKTF_API_URL = "https://api-prod.example.com"  # Update with your prod API URL
    # Add more config properties here as needed
    # ENV_NAME      = "production"
    # FEATURE_FLAG_X = "false"
  }
}
