# gcp2slack

This repo facilitates the creation of Slack notifications for Google Cloud services.

### Overview

1. [Create a Google Cloud Project](https://cloud.google.com/resource-manager/docs/creating-managing-projects).

2. [Create pubsub service credential and download json](https://cloud.google.com/iam/docs/creating-managing-service-account-keys)

3. [Enable Google Secret Manager for your project](https://cloud.google.com/secret-manager/docs/quickstart)

4. [Add secret accessor role](https://cloud.google.com/secret-manager/docs/access-control) to your project's [default compute engine user](https://cloud.google.com/compute/docs/access/service-accounts#default_service_account).

5. [Create a Slack webhook url for your workspace](https://slack.com/help/articles/115005265063-Incoming-webhooks-for-Slack)

6. Create a secret named pubsub_json and upload the pubsub json credential file for its contents.

7. Create a secret named slack_buildchannel_webhook and set its value to your Slack webhook url.

8. [Fork this repo](https://docs.github.com/en/free-pro-team@latest/github/getting-started-with-github/fork-a-repo).

9. Create a Cloud Run Service based on this repo. You have options.
* [Build via Github triggers in console (easier but fewer options)](https://towardsdatascience.com/r-powered-services-that-are-simple-scalabale-and-secure-4c454c159e48)
* [Build via googleCloudRunner R package (tougher set up but far more capabilities)](https://code.markedmondson.me/googleCloudRunner/index.html)

10. [Create a pubsub topic](https://cloud.google.com/pubsub/docs/quickstart-console) named "cloud-builds".

11. [Create a pubsub push subscription to that topic](https://cloud.google.com/pubsub/docs/admin#creating_subscriptions) for that topic which posts to {your Cloud Run service url}/cloudbuild2slack. 

\*\*\* Optional but highly recommended: [Set your pubsub push subscription to use authentication](https://cloud.google.com/pubsub/docs/push#setting_up_for_push_authentication) and set your Cloud Run service to only allow authenticated invocations.

12. Run your service. Either push to your Github repo to trigger the service or use googleCloudRunner to serve it.
