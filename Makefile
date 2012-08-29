# Makefile for emr-openbabel-boostrap
#
#
# run 
# % make
# to get the list of options.
#
# karnab@amazon.com

#
# commands setup (ADJUST THESE IF NEEDED)
# 
S3CMD                   = s3cmd
EMR			= elastic-mapreduce
CLUSTERSIZE		= 2
REGION                  = us-east
KEY			= ${HOME}/.ssh/normal.pem
BUCKET			= s3://$(USER).crossbow.emr

# 
# make targets 
#

help:
	@echo "help for Makefile for SimpleEMR sample project"
	@echo "make create           - create an EMR Cluster with default settings (2 x c1.medium)"
	@echo "make submitjob	     - launch the job into the cluster" 
	@echo "make destroy          - clean up everything (terminate cluster and remove s3 bucket)"
	@echo "make ssh              - log into head node of cluster"


#
# removes all data copied to s3
#
cleanbootstrap:
	-${S3CMD} -r rb $(BUCKET)

#
# top level target to tear down cluster and cleanup everything
#
destroy: cleanbootstrap
	@ echo deleting cluster
	-${EMR} -j `cat ./jobflowid` --terminate
	rm ./jobflowid

#
# push data into s3 
#
bootstrap: 
	-${S3CMD} mb ${BUCKET}
	${S3CMD} sync --acl-public ./config ${BUCKET}
	${S3CMD} sync --acl-public ./docs ${BUCKET}

#
# top level target to create a new cluster of c1.mediums
#
create: bootstrap
	@ if [ -a ./jobflowid ]; then echo "jobflowid exists! exiting"; exit 1; fi
	@ echo creating EMR cluster
	${EMR} elastic-mapreduce --create --alive --name "$(USER)'s crossbow Cluster" \
	--num-instances ${CLUSTERSIZE} \
	--instance-type cc1.4xlarge  \
	--bootstrap-action ${BUCKET}/config/config-crossbow.sh | cut -d " " -f 4 > ./jobflowid


#
# logs:  use this to see output of jobs
#

logs: 
	${EMR} -j `cat ./jobflowid` --logs


#
# ssh: quick wrapper to ssh into the master node of the cluster
#
ssh:
	${EMR} -j `cat ./jobflowid` --ssh

sshproxy:
	j=`cat ./jobflowid`; h=`${EMR} --describe -j $$j | grep "MasterPublicDnsName" | cut -d "\"" -f 4`; echo "h=$$h"; if [ -z "$$h" ]; then echo "master not provisioned"; exit 1; fi
	j=`cat ./jobflowid`; h=`${EMR} --describe $$j | grep "MasterPublicDnsName" | cut -d "\"" -f 4`; ssh -L 9100:localhost:9100 -i ${KEY} hadoop@$$h


