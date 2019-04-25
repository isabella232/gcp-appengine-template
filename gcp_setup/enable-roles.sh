#!/bin/sh
#
# This script pulls together all of the roles needed for the project.
# It will place the role yaml in /tmp/ for you to review.
#
# Execute this like "./enable-roles.sh -c" to create/update the roles
# automatically.
#

# make sure we are in the right directory
if [ ! -f project-owner.yaml ] ; then
	echo "you need to be in the gcp_setup directory to run this script so that it can find it's files"
	exit 1
fi

# make sure that we have the GOOGLE_PROJECT_ID set
if [ -z "${GOOGLE_PROJECT_ID}" ] ; then
	echo "GOOGLE_PROJECT_ID has not been set: set this to the GCP project ID that you want to add these roles to"
	exit 1
fi

# This is the function that pulls down the base policies, removes the
# permissions that are improper, and creates/updates the custom policies in the
# GCP Project
create_policy () {
	rm -f /tmp/iam_permissions.$$

	for i in ${ROLES} ; do
		gcloud iam roles describe "$i" | grep -v serviceusage.services.enable | grep -E '^- ' >> /tmp/iam_permissions.$$
	done

	rm -f /tmp/new_role.$$
	cat <<EOF > /tmp/new_role.$$
title: ${TITLE}
description: ${DESCRIPTION}
stage: GA
includedPermissions:
EOF
	sort -u /tmp/iam_permissions.$$ >> /tmp/new_role.$$
	rm -f /tmp/iam_permissions.$$


	if [ "$1" = "-c" ] ; then
		# update the role if it exists, otherwise create it
		if gcloud iam roles describe "$NAME" >/dev/null 2>&1 ; then
			gcloud iam roles update "$NAME" --project "${GOOGLE_PROJECT_ID}" --file /tmp/new_role.$$
		else
			gcloud iam roles create "$NAME" --project "${GOOGLE_PROJECT_ID}" --file /tmp/new_role.$$
		fi
		rm -f /tmp/new_role.$$
	else
		mv /tmp/new_role.$$ "/tmp/${NAME}.yaml"
		echo "created /tmp/${NAME}.yaml role for your review, but did not create/update it in GCP"
	fi
}

####################################################
# create the terraform policy
ROLES="
 roles/editor
 roles/logging.admin
"
TITLE="GSA Project Terraform"
DESCRIPTION=$(echo "$ROLES without serviceusage.services.enable" | tr -d '\n' )
NAME=gsa-project-terraform
create_policy "$1"

####################################################
# create the project owner policy
ROLES="
 roles/editor
 roles/logging.admin
 roles/securitycenter.adminEditor
 roles/monitoring.admin
 roles/billing.viewer
"
TITLE="GSA Project Owner"
DESCRIPTION=$(echo "$ROLES without serviceusage.services.enable" | tr -d '\n' )
NAME=gsa-project-owner
create_policy "$1"

####################################################
# create the project admin policy
ROLES="
 roles/editor
 roles/logging.admin
 roles/securitycenter.adminEditor
 roles/monitoring.admin
 roles/billing.viewer
"
TITLE="GSA Project Admin"
DESCRIPTION=$(echo "$ROLES without serviceusage.services.enable" | tr -d '\n' )
NAME=gsa-project-admin
create_policy "$1"

####################################################
# create the project dev read/write policy
ROLES="
 roles/editor
 roles/monitoring.admin
"
TITLE="GSA Project Developer - rw"
DESCRIPTION=$(echo "$ROLES without serviceusage.services.enable" | tr -d '\n' )
NAME=gsa-project-dev-rw
create_policy "$1"

####################################################
# create the project dev readonly policy
ROLES="
 roles/viewer
 roles/monitoring.viewer
"
TITLE="GSA Project Developer - rw"
DESCRIPTION=$(echo "$ROLES without serviceusage.services.enable" | tr -d '\n' )
NAME=gsa-project-dev-ro
create_policy "$1"