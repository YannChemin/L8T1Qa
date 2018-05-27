#!/bin/bash

echo "runGCP.sh $noParallelThreads $localSourceDataDir $localOutputDataDir"
echo "runGCP.sh $1 $2 $3"
echo ""
echo "$1 is number of threads, on my configuration of GCP max is 8"
echo "$2 is the local source directory to upload"
echo "$3 is the local output reception directory"


echo "Run GCP instance"
gcloud beta compute --project=able-bazaar-205117 instances create instance-2 --zone=northamerica-northeast1-a --machine-type=n1-standard-$1 --subnet=default --network-tier=PREMIUM --metadata=startup-script=sudo\ apt-get\ update$'\n'sudo\ apt-get\ install\ subversion\ libgdal-dev\ -y$'\n'svn\ co\ https://github.com/YannChemin/L8T1Qa$'\n'cd\ L8T1Qa/trunk/prog_L8T1Qa/ --maintenance-policy=MIGRATE --service-account=904205699198-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image=ubuntu-1804-bionic-v20180522 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=instance-2

echo "Copy Data from local source (enable manually if needed)"
#PRIOR TO PROCESSING: from local to gcp
##Go to directory from interactive user setting
#cd $2
##Go to directory for Yann Local laptop
##cd ~/RSDATA/2_PreProcessed/L8/
##Upload each tarball with scp from directory set
#for file in *.tar.gz
#do
#	gcloud compute scp $file instance-2:~/L8T1Qa/trunk/RSDATA/2_PreProcessed/L8/
#done

#SETUP
gcloud compute ssh --zone=northamerica-northeast1-a instance-2 --command 'sudo apt-get update && sudo apt-get install subversion libgdal-dev && sudo apt autoremove'
gcloud compute ssh --zone=northamerica-northeast1-a instance-2 --command 'svn co https://github.com/YannChemin/L8T1Qa'

#PROCESSING
gcloud compute ssh --zone=northamerica-northeast1-a instance-2 --command 'cd ~/L8T1Qa/trunk/prog_L8T1Qa/ && bash run.sh 4 L8T1Qa_Cloud'

#POST PROCESSING: from gcp to local (create locally ~/RSDATA and copy incoming tarballs)
mkdir -p ~/RSDATA/
gcloud compute scp --recurse instance-2:~/L8T1Qa/trunk/RSDATA/3_Products/ ~/RSDATA/

#STOP instance
gcloud compute instances stop instance-2

