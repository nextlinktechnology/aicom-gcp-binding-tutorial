<walkthrough-tutorial-duration duration="10"></walkthrough-tutorial-duration>

# Connect Multiple GCP Projects to AICOM

## Before You Begin

You’re now in GCP Cloud Shell. This tutorial guides you through selecting projects from an interactive terminal menu, setting project labels, enabling the required APIs, and granting IAM permissions. You’ll then return to AICOM to verify your setup.

Make sure you have permission to update labels, enable APIs, and manage IAM access in every target project.

Projects in the same AICOM connection session can share one Label Value to verify your control over each project. Keep the original AICOM connection window open. If closing the window invalidates the Label Value, start a new connection session and apply the new value to every target project.

## Select Your GCP Projects

Run the following command in the Cloud Shell terminal from this tutorial’s directory. Complete Cloud Shell authorization if prompted.

```bash
bash setup-multi.sh --select --language en
```

The menu lists project names and IDs accessible by the active account. Enter the numbers of the projects you want to connect, separated by spaces, such as `1 3`, then press Enter.

```text
Select projects to connect to AICOM
No.   Project name / Project ID
1     Production
      company-prod
2     Staging
      company-staging
3     Development
      company-dev

Enter numbers separated by spaces (for example 1 3), or q to cancel > 1 3
```

This is an example. Your actual list depends on your account. Choose projects where you can update labels, enable APIs and grant IAM access.

Review the selected projects, then enter one of the following options.

- `y` to confirm and save the list, then continue to the next step.
- `a` to return to the menu and add more projects, keeping the current selection.
- `n` to clear the current selection and start over.
- `q` to cancel. Run the selector again before continuing.

You can select multiple numbers at once or add projects over several rounds. Repeated projects are automatically combined.

After you enter `y`, the list is saved to `.aicom-projects` in this tutorial’s directory and loaded by subsequent steps. Running `--select` again clears the previous list and starts a new selection. If you cancel or loading fails, select and confirm again. After opening a new terminal, return to the same tutorial directory to use the saved list.

## Set the Project Labels

Replace `<LABEL-VALUE>` with the Label Value copied from the current AICOM connection window, then run the entire command. The script applies the same `aicom-binding` label value to every project in your list.

```bash
LABEL_VALUE="<LABEL-VALUE>"
bash setup-multi.sh --label "$LABEL_VALUE" --selected
```

Confirm that all projects completed this step before enabling APIs. If any fail, resolve the reported errors and rerun this step. To retry only failed projects, replace `--selected` with their quoted Project IDs.

## Enable the Required APIs

Run the following command to enable these APIs in every listed project so AICOM can retrieve cloud resource and monitoring data.

- Cloud Resource Manager API
- Compute Engine API
- Cloud SQL Admin API
- Cloud Storage API
- BigQuery API
- Cloud Monitoring API
- Vertex AI API
- Cloud Asset API

```bash
bash setup-multi.sh --enable-apis --selected
```

Wait for the summary, especially when processing many projects. Contact your project administrator if you receive a permission error. Some APIs may already have been enabled when a failure occurs. Resolve the error and rerun this step. Continue once every project succeeds.

## Grant AICOM Access

Run the following command to grant AICOM’s designated service account the Viewer (`roles/viewer`) role in each project so AICOM can read cloud resource and monitoring data.

```bash
bash setup-multi.sh --selected
```

The script processes every project in turn, continues after individual failures, and lists successful and failed projects for this step. Resolve errors and rerun the failed step as needed. Completed changes are retained. After IAM authorization succeeds, also confirm that the label and API steps succeeded for every project.

## Return to AICOM to Verify

After every project has completed the label, API, and IAM steps, return to the original AICOM connection window.

Follow the AICOM interface to provide the Project IDs and connection names for this session, verify the projects, and complete their connections. Confirm that every project in your list has passed verification.

If verification fails, check that the project uses the current session’s Label Value and has completed all three setup steps, then verify again.
