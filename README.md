# travisperkins-ansible
Ansible Playbooks for TravisPerkins

▽
# travisperkins-ansible
Ansible Playbooks for TravisPerkins

The playbooks are designed to manage the autoscaling environment for the OVC application for TravisPerkins

These playbooks are available to run from ansible tower. 

### ami-baker.yml

First in the process is the ami-baker.yml
It does the following:

	1. Creates a server
	2. Installs the necessary application, 
	3. Installs configuration 
	4. Starts services
	3. Bundles the server into an AMI
	4. Destroys the server
  
  To run this playbook from the command line, you will need to include the vault password, as the automation pushes out the SSL keys encrypted and the vault password will decrypt the keys after pushing it out to the server. 
  Here is an example command line: 
  
	ansible-playbook ami-baker.yml --extra-vars "ovc_version=4.12.0" --vault-password-file ~/.vault_pass.txt

  This needs to be run from the Ansible Utility tower server as that is where the file exists, /root/.vault_pass.txt 
  
  In addition to specifying the vault password, you always need the ovc_version or the job will fail. This will determine what version of code to get from S3 to install on the new server. 
  
  The other variables available are set in the file vars/ami-baker-defaults.yml  
  
### update-asg.yml

After you have built a new AMI, you will want to use it in a working autoscaling group. You can do this with update-asg.yml


This playbook takes a few arguments. 

	1. It needs the deploy_type . This needs to be pre-prod or prod. If other deploy_types are needed then we will need to refactor the playbook. 
	2. It also requires the ovc_version, as that is how it searches for AMI's. 
	3. The playbook reads in the variables from vars/pre-prod.yml or vars/prod.yml depending on the deploy_type

Running the update-asg.yml will do the following. 

	1. It finds the newest AMI with the ovc version specified in the AMI name. 
	2. Creates a new launch config using the user data string from scripts/{deploy_type}-user_data.sh
	3. Then it updates the auto scaling group that is named in the vars/{deploy_type}.yml


### create-asg-elb.yml
  
  To setup a brand new Autoscaled stack, you can use the create-asg-elb.yml  playbook
  
  This will do the following: 
  
  	1. Create a new Elastic Load balancer
  	2. Create a new Launch configuration 
  	3. Create a new Autoscaling group using the previously made ELB and LC
  
  This will not need to be run frequently. It is made available in case you need to stand up a new autoscaled Staging, preprod, production or other environment. 

  
  
