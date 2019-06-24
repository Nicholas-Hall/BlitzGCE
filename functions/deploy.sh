#!/bin/bash
#
# Title:      PGBlitz (Reference Title File)
# Author(s):  Admin9705
# URL:        https://pgblitz.com - http://github.pgblitz.com
# GNU:        General Public License v3.0
################################################################################
source /opt/blitzgce/functions/main.sh

deployserver () {
  variablepull
  ### checks to make sure common variables are filled out
deployfail
  ### prevents deployment if one exists!
servercheck
  if [[ "$gcedeployedcheck" == "DEPLOYED" ]]; then
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 ERROR: PG GCE Instance Already Detected
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

INFORMATION: The prior GCE Server must be deleted prior to deloying a
another one! Exiting!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
  read -p '↘️  Acknowledge Info | Press [ENTER] ' typed < /dev/tty
gcestart; fi

### deletes deployed ip if it exists for some odd reason
#  ipcheck=$(gcloud compute instances list | grep pg-gce | head -n +1 | awk '{print $2}' | grep ".")
#  if [[ "$ipcheck" != "" ]]; then
#tee <<-EOF

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
#🚀 Deleting Old IP Address
#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#EOF
#gcloud compute addresses delete pg-gce --region $ipregion --quiet
#echo
#fi

  ### builds plexguide firewall if it does not exist
  rulecheck=$(gcloud compute firewall-rules list | grep plexguide)
  if [[ "$rulecheck" == "" ]]; then
tee <<-EOF
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Creating Firewall Rules | Does Not Exist
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF

gcloud compute firewall-rules create plexguide --allow all
echo
fi

  ### checks for template; if it exist; it will delete it
  blueprint=$(gcloud compute instance-templates list | grep pg-gce-blueprint)
  if [ "$blueprint" != "" ]; then
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Deleting Old PG Template
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
gcloud compute instance-templates delete pg-gce-blueprint --quiet
echo
fi

  ### Recalls Variables
  variablepull

## NVME counter to add dont edit this lines below
nvme="$(cat /var/plexguide/project.nvme)"
nvmedeploy="$(cat /var/plexguide/deploy.nvme )"

if [ "$nvme" == "1" ]; then
  echo -e "--local-ssd interface=nvme" > /var/plexguide/deploy.nvme
elif [ "$nvme" == "2" ]; then
 echo -e "--local-ssd interface=nvme \ \n--local-ssd interface=nvme " > /var/plexguide/deploy.nvme
elif [ "$nvme" == "3" ]; then
 echo -e "--local-ssd interface=nvme \ \n--local-ssd interface=nvme \ \n--local-ssd interface=nvme " > /var/plexguide/deploy.nvme
elif [ "$nvme" ==  "4" ]; then
 echo -e "--local-ssd interface=nvme \ \n--local-ssd interface=nvme \ \n--local-ssd interface=nvme \ \n--local-ssd interface=nvme " > /var/plexguide/deploy.nvme
fi
### NVME counter to add dont edit this lines above

  ### Deploys the PG Template
  gcloud compute instance-templates create pg-gce-blueprint \
  --custom-cpu $processor --custom-memory $ramcount \
  --image-family ubuntu-1804-lts --image-project ubuntu-os-cloud \
  --boot-disk-auto-delete --boot-disk-size 200GB \
  $nvmedeploy

  ### Deploy the GCE Server
  echo
  gcloud compute instances create pg-gce --source-instance-template pg-gce-blueprint --zone $ipzone

  ### Assigning the IP Address to GCE Box
tee <<-EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Finalizing - Assigned IP Address to Instance
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
  variablepull
  echo
  gcloud compute instances delete-access-config pg-gce --access-config-name "external-nat" --zone $ipzone --quiet

  echo
  gcloud compute instances add-access-config pg-gce --access-config-name "external-nat" --zone $ipzone --address $ipaddress
  echo
  read -p '↘️  Process Complete | Press [ENTER] ' typed < /dev/tty

}
