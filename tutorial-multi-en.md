<walkthrough-tutorial-duration duration="10"></walkthrough-tutorial-duration>

# Connect Multiple GCP Projects to AICOM

## Before You Begin

You’re now in GCP Cloud Shell. This tutorial guides you through adding projects one at a time with the GCP graphical picker, setting project labels, enabling the required APIs, and granting IAM permissions. You’ll then return to AICOM to verify your setup.

Make sure you have permission to update labels, enable APIs, and manage IAM access in every target project.

Projects in the same AICOM connection session can share one Label Value to verify your control over each project. Keep the original AICOM connection window open. If closing the window invalidates the Label Value, start a new connection session and apply the new value to every target project.

## Start the Project List for This Session

Run the following command in the Cloud Shell terminal from this tutorial’s directory. This clears the previously saved list. Run it once when starting a new connection session.

```bash
python3 select-projects.py --language en reset
```

## Select and Add GCP Projects One at a Time

Use the GCP graphical picker below to select the first project you want to connect.

<walkthrough-project-setup></walkthrough-project-setup>

Check that the command below shows the Project ID you just selected. Copy the entire command into the Cloud Shell terminal and run it to add the project to this session’s list.

```bash
python3 select-projects.py --language en add "<walkthrough-project-id/>"
```

The terminal will show the accumulated project list.

To add more projects, stay on this step and repeat the following actions.

1. Use the GCP picker above to switch to another project.
2. Check that the add command above shows the new Project ID, then copy and run the updated command.
3. Check that the terminal’s list includes the project you just added.

Run the add command after every selection. Copy the updated command from the tutorial each time. Commands in your terminal history retain their previous Project IDs. Adding a project twice skips the duplicate and retains the other projects already in the list.

Continue once you have added every project. If you added the wrong project, return to Start the Project List for This Session, reset the list, and select the intended projects again.

## Review the Project List

Run the following command and check that the list contains every project you want to connect in this session.

```bash
python3 select-projects.py --language en list
```

If a project is missing, return to the previous step to select and add it, then review the list again. Continue to the label step once the list is correct.

The list is saved to `.aicom-projects` in this tutorial’s directory. Subsequent steps load the entire list. After opening a new terminal, return to the same tutorial directory to continue. Use `list` to review projects already selected for the current session.

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
