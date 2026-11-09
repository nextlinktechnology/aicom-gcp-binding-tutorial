<walkthrough-tutorial-duration duration="5"></walkthrough-tutorial-duration>

# Connect Your GCP Project to AICOM

## Before You Begin

You’re now in GCP Cloud Shell. Follow this tutorial and run the commands provided by AICOM to connect your project.

You’ll select a project, set a project label, enable the required APIs, and grant IAM permissions. Once you’re done, return to AICOM to verify your setup.

Before you begin, make sure you have the Editor (`roles/editor`) role and the permissions needed to update labels, enable APIs, and manage IAM access for the target project. Keep the AICOM connection window open.

## Select a GCP Project

Select the GCP project you want to connect to AICOM. The project label, API settings, and IAM permissions configured in this tutorial will apply to this project.

If you don’t have a suitable project, create one, then return here to select it.

<walkthrough-project-setup></walkthrough-project-setup>

## Set the Project Label

The command below already includes your selected Project ID. Replace `<LABEL-VALUE>` with the Label Value you copied from AICOM, then paste the entire command into the Cloud Shell terminal on the left and press Enter.

```bash
gcloud alpha projects update "<walkthrough-project-id/>" \
  --update-labels="aicom-binding=<LABEL-VALUE>"
```

**Note.** Closing the AICOM connection window will invalidate the Label Value. If this happens, start the connection process again.

## Enable the Required APIs

Run the command below to enable the following APIs for your selected project so AICOM can retrieve cloud resource and monitoring data.

- Cloud Resource Manager API
- Compute Engine API
- Cloud SQL Admin API
- Cloud Storage API
- BigQuery API
- Cloud Monitoring API
- Vertex AI API
- Cloud Asset API

```bash
gcloud services enable \
  cloudresourcemanager.googleapis.com \
  compute.googleapis.com \
  sqladmin.googleapis.com \
  storage.googleapis.com \
  bigquery.googleapis.com \
  monitoring.googleapis.com \
  aiplatform.googleapis.com \
  cloudasset.googleapis.com \
  --project="<walkthrough-project-id/>"
```

Paste the entire command into the Cloud Shell terminal on the left and press Enter. If you receive a permission error, contact your project administrator for assistance.

## Grant AICOM Access

Run the command below to grant AICOM’s designated service account the IAM permissions needed to read cloud resource and monitoring data from your selected project.

The command already includes your selected Project ID. Copy and paste the entire command into the Cloud Shell terminal on the left, press Enter, and wait for it to finish.

```bash
bash setup.sh "<walkthrough-project-id/>"
```

Once the command completes successfully, return to the AICOM connection window and click “Next.” Enter the Project ID and a name for the connection, then click “Verify.”

After verification succeeds, click “Finish” to complete the project connection.
