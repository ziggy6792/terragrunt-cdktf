locals {
  env = "dev"
  frontend_config = {
    CDKTF_API_URL = "https://api-dev.example.com"  # Update with your dev API URL
    # Add more config properties here as needed
    # ENV_NAME      = "development"
    # FEATURE_FLAG_X = "true"
  }
}
