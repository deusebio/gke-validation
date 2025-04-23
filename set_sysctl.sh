while IFS=, read -r node zone; do echo gcloud compute ssh $node --project=deusebio-dev-env --zone=$zone -- 'sudo sysctl fs.inotify.max_user_watches=655360'; done < <(gcloud compute instances list | grep node | awk '{print $1","$2}')

while IFS=, read -r node zone; do echo gcloud compute ssh $node --project=deusebio-dev-env --zone=$zone -- 'sudo sysctl fs.inotify.max_user_instances=1280'; done < <(gcloud compute instances list | grep node | awk '{print $1","$2}')
