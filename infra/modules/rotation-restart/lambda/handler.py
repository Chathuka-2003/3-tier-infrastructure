"""Restart the ECS service after the database secret has been rotated.

ECS injects secrets only when a task starts, so tasks that started before a rotation hold
a stale password and fail to open new database connections. This function runs every few
minutes. When the secret was rotated AFTER the service's current deployment was created, it
starts a rolling (zero-downtime) deployment so new tasks read the current secret.
"""
import logging
import os

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secretsmanager = boto3.client("secretsmanager")
ecs = boto3.client("ecs")


def handler(event, context):
    cluster = os.environ["CLUSTER"]
    service = os.environ["SERVICE"]
    secret_arn = os.environ["SECRET_ARN"]

    secret = secretsmanager.describe_secret(SecretId=secret_arn)
    rotated_at = secret.get("LastRotatedDate")
    if rotated_at is None:
        logger.info("Secret has never been rotated; nothing to do.")
        return {"action": "none", "reason": "never rotated"}

    services = ecs.describe_services(cluster=cluster, services=[service])["services"]
    if not services:
        raise RuntimeError(f"ECS service {service} not found in cluster {cluster}")

    primary = next((d for d in services[0]["deployments"] if d["status"] == "PRIMARY"), None)
    if primary is None:
        logger.info("No PRIMARY deployment found; nothing to do.")
        return {"action": "none", "reason": "no primary deployment"}

    # Do not start a new deployment while one is still rolling out.
    if primary.get("rolloutState") not in (None, "COMPLETED"):
        logger.info("Deployment is %s; will re-check on the next run.", primary.get("rolloutState"))
        return {"action": "none", "reason": "rollout in progress"}

    if rotated_at > primary["createdAt"]:
        logger.info(
            "Secret rotated at %s, after deployment created at %s. Forcing a new deployment.",
            rotated_at,
            primary["createdAt"],
        )
        ecs.update_service(cluster=cluster, service=service, forceNewDeployment=True)
        return {"action": "restarted", "rotated_at": rotated_at.isoformat()}

    logger.info("Running tasks are newer than the last rotation (%s); nothing to do.", rotated_at)
    return {"action": "none", "reason": "tasks are current"}
