Google Sheets Sample App
========================

<a href="https://githubsfdeploy.herokuapp.com?owner=financialforcedev&repo=ffhttp-googlesheets-samples">
    <img alt="Deploy to Salesforce"
        src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/src/main/webapp/resources/img/deploy.png">
</a>

Summary
-------
This app has been built to demonstrate the use of the [Core](https://github.com/financialforcedev/ffhttp-core) and [Google Sheets](https://github.com/financialforcedev/ffhttp-googlesheets) libraries. Specifically, it demonstrates how the library can be used to transfer a list of Opportunity records to Google Sheets.

**Note:** Currently, no test coverage for the sample apps has been provided.

Configuration
-------------

This section explains how to configure the Google Sheets Sample App.

1. Deploy the [Core](https://githubsfdeploy.herokuapp.com?owner=financialforcedev&repo=ffhttp-core) package to your Salesforce organisation.
2. Deploy the [OAuth Sample App](https://githubsfdeploy.herokuapp.com?owner=financialforcedev&repo=ffhttp-core-samples).
3. Deploy the [Google Sheets](https://githubsfdeploy.herokuapp.com?owner=financialforcedev&repo=ffhttp-googlesheets) package. 
4. Deploy the [Google Sheets Sample App](https://githubsfdeploy.herokuapp.com?owner=financialforcedev&repo=ffhttp-googlesheets-samples).
5. Go to **Setup** > **Manage Users** > **Users**.
6. Select your user.
7. Select **Edit Assignments** in the **Permission Set Assignments** section.
8. Add the **OAuth Sample App Permissions** and **Google Sheets Sample App Permissions** permission sets and **Save**.
9. Select the **Google Sheets Sample App** from the app menu. 
    + The **Test Harness**, **Opportunities**, **Connector Types** and **Connectors** tabs should be displayed.
10. Create a Google App following the steps in the **Create an app in Google** section below.
11. Follow the **Create a Google Sheets Connector in Salesforce** steps below.
12. Select the **Opportunities** tab, choose to view **All Opportunities** and select **Go**.
13. Check that the **Export to Google Sheets** button is shown.

### Create an app in Google

1. Log in to your Google account.
2. Go to https://console.developers.google.com/project and select **Create Project**.
3. Enter a project name and ok the dialog.
4. Select the hyperlink for the project name that you just created.
5. Select **Credentials**.
6. Select **Create new Client ID**.
7. Select **Web application**.
8. Set the **Authorized Javascript Origins** url to the URL of the Salesforce organisation e.g. https://eu3.salesforce.com.
9. Set the **Authorized Redirect URIs** to the same as above with *apex/connector* appended: e.g. https://eu3.salesforce.com/apex/connector.
10. Make sure you know the **Client Id** and **Client Secret** as they will be needed later.
11. Select the **Consent screen**.
12. Enter a **Product Name** and save.

### Create a Google Sheets Connector in Salesforce
1. Log in to your Salesforce organisation.
2. Go to the **Developer Console** and select **Debug** > **Open Execute Anonymous Window**.
3. Run the following code changing the parameters to the appropriate values:

    ```
    GoogleSheetsConfigure.configure(<Google App Client Id>, <Google App Client Secret>, <Salesforce domain>);
    ```

4. Check that the connector has been created and activate it.

Use
---

Once the project is configured:

### Test Harness
1. Select the **Test Harness** tab.
2. Check that you get a message starting with 'Successful authentication'. If you do not, check that all the configuration steps have been peformed correctly.
3. Expand any section to display the API calls, then select **Submit** to test the call.

### Transfer Opportunities To Google Sheets Sample App
1. Select the **Opportunities** tab, choose to view **All Opportunities** and select **Go**.
2. Select some Opportunities and then **Export to Google Sheets**.
3. Select the fields that you wish to export, the spreadsheet, and the worksheet that you wish to export the data to.
4. Select **Export to Google Sheets**.
5. The data will have been exported to Google Sheets.

Reporting Issues & Enhancements
-------------------------------

Please report any issues using the github [issues](https://github.com/financialforcedev/ffhttp-googlesheets.-samples/issues) feature. Suggestions / bug reports are welcome as are extensions containing additional functionality.
