terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.34.0"
    }
  }
}

resource "random_id" "default" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name                        = "${random_id.default.hex}-gcf-source" # Every bucket name must be globally unique
  location                    = "US"
  project                     = "sacred-alliance-433217-e3"
  uniform_bucket_level_access = true
}

data "archive_file" "default" {
  type        = "zip"
  output_path = "/tmp/function-source.zip"
  source_dir  = "../source/"
}
resource "google_storage_bucket_object" "object" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.default.name
  source = data.archive_file.default.output_path # Add path to the zipped function source code
}




resource "google_cloudfunctions_function" "function" {
  name        = "ndonthi1-gcs-source-py"
  description = "My function"
  runtime     = "python38"
  project        = "sacred-alliance-433217-e3"
  region     = "us-central1"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.default.name
  source_archive_object = google_storage_bucket_object.object.name
  trigger_http          = true
  entry_point           = "hello_get"
}


resource "google_cloud_scheduler_job" "ndonthi1-schedule-job" {
  name         = "cloudfuntion_trigger"
  project      = "sacred-alliance-433217-e3"
  region     = "us-central1"
  description  = "load the data to gcp"
  schedule     = "0/2 * * * *"
  http_target {
    http_method = "POST"
    uri = "https://us-central1-sacred-alliance-433217-e3.cloudfunctions.net/ndonthi1-gcs-source-py"
    body        = base64encode("{\"table_id\":\"sacred-alliance-433217-e3.llm_evalution.llm_prompt_eval\", \"gcs_uri\":\"gs://llm-finetune-ndonthi1/llm_prompt_eval.csv\"}")
    headers = {
      "Content-Type" = "application/json"
    }
    oidc_token {
      service_account_email = "878726209708-compute@developer.gserviceaccount.com"
    }
  }
}