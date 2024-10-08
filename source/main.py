import functions_framework
from google.cloud import bigquery

@functions_framework.http
def hello_get(request):
    """HTTP Cloud Function.
    Args:
        request (flask.Request): The request object.
        <https://flask.palletsprojects.com/en/1.1.x/api/#incoming-request-data>
    Returns:
        The response text, or any set of values that can be turned into a
        Response object using `make_response`
        <https://flask.palletsprojects.com/en/1.1.x/api/#flask.make_response>.
    Note:
        For more information on how Flask integrates with Cloud
        Functions, see the `Writing HTTP functions` page.
        <https://cloud.google.com/functions/docs/writing/http#http_frameworks>
    """
    request_json = request.get_json()
    print(request_json)
    client = bigquery.Client()
    table_id = request_json['tabke_id']
    gcs_uri = request_json['gcs_uri']  # GCS URI, e.g., 'gs://bucket_name/path_to_file.csv'

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        schema=[
        bigquery.SchemaField("context", "STRING"),
        bigquery.SchemaField("reference", "STRING"),
        bigquery.SchemaField("instruction", "STRING"),
    ],
        skip_leading_rows=1,
        autodetect=True,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE  # This will truncate the table before loading new data
    )

    # Load data from GCS
    load_job = client.load_table_from_uri(
        gcs_uri,
        table_id,
        job_config=job_config
    )  # Make an API request.

    load_job.result()  # Waits for the job to complete.

    # Get table details after the load
    table = client.get_table(table_id)
    print(
        "Loaded {} rows and {} columns to {}".format(
            table.num_rows, len(table.schema), table_id
        )
    )
    return "Hello World!"
