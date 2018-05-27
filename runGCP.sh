#!/bin/bash

echo "runGCP.sh $noParallelThreads $localSourceDataDir $localOutputDataDir"
echo ""
#$1 is number of threads, on my configuration of GCP max is 8
#$2 is the local source directory to upload
#$3 is the local output reception directory


echo "Run GCP instance"
gcloud beta compute --project=able-bazaar-205117 instances create instance-2 --zone=northamerica-northeast1-a --machine-type=n1-standard-$1 --subnet=default --network-tier=PREMIUM --metadata=startup-script=sudo\ apt-get\ update$'\n'sudo\ apt-get\ install\ subversion\ libgdal-dev\ -y$'\n'svn\ co\ https://github.com/YannChemin/L8T1Qa$'\n'cd\ L8T1Qa/trunk/prog_L8T1Qa/ --maintenance-policy=MIGRATE --service-account=904205699198-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/devstorage.read_only,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/trace.append --image=ubuntu-1804-bionic-v20180522 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=instance-2


#PRIOR TO PROCESSING: from local to gcp
#Go to directory
cd $2
#cd ~/RSDATA/2_PreProcessed/L8/
#Upload each tarball with scp
for file in *.tar.gz
do
	gcloud compute scp $file instance-2:~/L8T1Qa/trunk/RSDATA/2_PreProcessed/L8/
done

#PROCESSING
gcloud compute ssh --zone=northamerica-northeast1-a instance-2 --command 'sudo apt-get update && sudo apt-get install subversion libgdal-dev && sudo apt autoremove'
gcloud compute ssh --zone=northamerica-northeast1-a instance-2 --command 'svn co https://github.com/YannChemin/L8T1Qa'
gcloud compute ssh --zone=northamerica-northeast1-a instance-2 --command 'cd ~/L8T1Qa/trunk/prog_L8T1Qa/ && bash run.sh $1 L8T1Qa_Cloud'


#POST PROCESSING: from gcp to local
gcloud compute scp --recurse instance-2:~/3_Products/ ~/RSDATA/

#STOP instance
gcloud compute instances stop instance-2

