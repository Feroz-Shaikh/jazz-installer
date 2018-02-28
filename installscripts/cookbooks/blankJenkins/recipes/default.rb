if node[:platform_family].include?("rhel")
    execute 'resizeJenkinsMemorySettings' do
      command "sudo sed -i 's/JENKINS_JAVA_OPTIONS=.*.$/JENKINS_JAVA_OPTIONS=\"-Djava.awt.headless=true -Xmx1024m -XX:MaxPermSize=512m\"/' /etc/sysconfig/jenkins"
    end
    execute 'chmodservices' do
      command "chmod -R 755 #{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files;"
    end
    directory '#{node['jenkins']['home']}/workspace' do
      owner 'jenkins'
      group 'jenkins'
      mode '0777'
      recursive true
      action :create
    end
    execute 'startjenkins' do
      command "sudo service jenkins start"
    end
    execute 'copyJenkinsClientJar' do
      command "cp #{node['client']['jar']} #{node['jenkins']['SSH_user_homedir']}/jenkins-cli.jar; chmod 755 #{node['jenkins']['SSH_user_homedir']}/jenkins-cli.jar"
    end
    execute 'createJobExecUser' do
      command "sleep 30;echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount(\"jobexec\", \"jenkinsadmin\")' | java -jar #{node['client']['jar']} -auth @#{node['authfile']} -s http://#{node['jenkinselb']}/ groovy ="
    end
    execute 'copyEncryptGroovyScript' do
      command "cp #{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/default/encrypt.groovy #{node['jenkins']['SSH_user_homedir']}/encrypt.groovy"
    end
    execute 'copyXmls' do
      command "tar -xvf #{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/default/xmls.tar"
      cwd "#{node['jenkins']['home']}"
    end
    execute 'copyConfigXml' do
      command "cp #{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/node/config.xml ."
      cwd "#{node['jenkins']['home']}"
    end
    execute 'copyCredentialsXml' do
      command "cp #{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/credentials/credentials.xml ."
      cwd "#{node['jenkins']['home']}"
    end
    # script approvals going in with  xmls.tar will be overwritten
    execute 'copyScriptApprovals' do
      command "cp #{node['jenkins']['scriptApprovalfile']} #{node['jenkins']['scriptApprovalfiletarget']}"
    end
    # Configure Gitlab Plugin
    execute 'configuregitlabplugin' do
      only_if  { node[:scm] == 'gitlab' }
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/node/configuregitlab.sh #{node['scmelb']}"
    end
    execute 'configuregitlabuser' do
      only_if  { node[:scm] == 'gitlab' }
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/credentials/gitlab-user.sh #{node['jenkinselb']} #{node['jenkins']['SSH_user']}"
    end
    execute 'configuregitlabtoken' do
      only_if  { node[:scm] == 'gitlab' }
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/credentials/gitlab-token.sh #{node['jenkinselb']} #{node['jenkins']['SSH_user']}"
    end
    service "jenkins" do
      supports [:stop, :start, :restart]
      action [:restart]
    end
    if (File.exist?("#{node['jenkins']['SSH_user_homedir']}/jazz-core"))
    	execute 'downloadgitproj' do
      		command "rm -rf #{node['jenkins']['SSH_user_homedir']}/jazz-core"
      		cwd "#{node['jenkins']['SSH_user_homedir']}"
    	end
    end
    execute 'downloadgitproj' do
      command "git clone -b #{node['git_branch']} https://github.com/tmobile/jazz.git jazz-core"

      cwd "#{node['jenkins']['SSH_user_homedir']}"
    end
    execute 'copylinkdir' do
      command "cp -rf #{node['jenkins']['SSH_user_homedir']}/jazz-core/aws-apigateway-importer /var/lib; chmod -R 777 /var/lib/aws-apigateway-importer"
    end
    execute 'createcredentials-jenkins1' do
      only_if  { node[:scm] == 'bitbucket' }
      command "sleep 300;#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/credentials/jenkins1.sh #{node['jenkinselb']} #{node['jenkins']['SSH_user']}"
    end
    execute 'createcredentials-jobexecutor' do
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/credentials/jobexec.sh #{node['jenkinselb']} #{node['jenkins']['SSH_user']}"
    end
    execute 'createcredentials-aws' do
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/credentials/aws.sh #{node['jenkinselb']} #{node['jenkins']['SSH_user']}"
    end
    execute 'createcredentials-cognitouser' do
      command "sleep 30;#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/credentials/cognitouser.sh #{node['jenkinselb']} #{node['jenkins']['SSH_user']}"
    end
    execute 'configJenkinsLocConfigXml' do
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/node/configJenkinsLocConfigXml.sh  #{node['jenkinselb']} #{node['jenkins']['SES-defaultSuffix']}"
    end
    execute 'createJob-create-service' do
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/jobs/job_create-service.sh #{node['jenkinselb']} create-service #{node['scmpath']} #{node['jenkins']['SSH_user']}"
    end
    execute 'createJob-delete-service' do
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/jobs/job_delete-service.sh #{node['jenkinselb']} delete-service #{node['scmpath']} #{node['jenkins']['SSH_user']}"
    end
    execute 'createJob-job_build_pack_api' do
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/jobs/job_build_java_api.sh #{node['jenkinselb']} build_pack_api #{node['scmpath']} #{node['jenkins']['SSH_user']}"
    end
    execute 'createJob-bitbucketteam_newService' do
      only_if  { node[:scm] == 'bitbucket' }
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/jobs/job_bitbucketteam_newService.sh #{node['jenkinselb']} bitbucketteam_newService #{node['scmelb']}  #{node['jenkins']['SSH_user']}"
    end
	  execute 'createJob-platform_api_services' do
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/jobs/job_platform_api_services.sh #{node['jenkinselb']} Platform_API_Services #{node['scmelb']}  #{node['jenkins']['SSH_user']}"
    end
    execute 'job_build-deploy-platform-service' do
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/jobs/job_build-deploy-platform-service.sh #{node['jenkinselb']} build-deploy-platform-service  #{node['scmpath']}  #{node['region']}  #{node['jenkins']['SSH_user']}"
    end
    execute 'job_cleanup_cloudfront_distributions' do
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/jobs/job_cleanup_cloudfront_distributions.sh #{node['jenkinselb']} cleanup_cloudfront_distributions  #{node['scmpath']} #{node['jenkins']['SSH_user']}"
    end
    execute 'createJob-job-pack-lambda' do
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/jobs/job_build_pack_lambda.sh #{node['jenkinselb']} build-pack-lambda #{node['scmpath']}  #{node['jenkins']['SSH_user']}"
    end
    execute 'createJob-job-build-pack-website' do
      command "#{node['jenkins']['SSH_user_homedir']}/cookbooks/jenkins/files/jobs/job_build_pack_website.sh #{node['jenkinselb']} build-pack-website #{node['scmpath']}  #{node['jenkins']['SSH_user']}"
    end
    execute 'job-gitlab-trigger' do
      only_if  { node[:scm] == 'gitlab' }
      command "#{node['jenkins']['SSH_user_homedir']}/jenkins/files/jobs/job-gitlab-trigger.sh #{node['jenkinselb']} #{node['jenkins']['SSH_user']} #{node['scmpath']}"
    end
	execute 'job-trigger-platform-services-build' do
      only_if  { node[:scm] == 'gitlab' }
      command "#{node['jenkins']['SSH_user_homedir']}/jenkins/files/jobs/job-trigger-platform-services-build.sh #{node['jenkinselb']} #{node['jenkins']['SSH_user']} #{node['scmpath']}"
    end
    link '/usr/bin/aws-api-import' do
      to "#{node['jenkins']['SSH_user_homedir']}/jazz-core/aws-apigateway-importer/aws-api-import.sh"
      owner 'jenkins'
      group 'jenkins'
      mode '0777'
    end
    link '/usr/bin/aws' do
      to '/usr/local/bin/aws'
      owner 'root'
      group 'root'
      mode '0777'
    end
    execute 'chownJenkinsfolder' do
      command "chown jenkins:jenkins #{node['jenkins']['home']}"
    end
    service "jenkins" do
      supports [:stop, :start, :restart]
      action [:restart]
    end
end

#For debian based systems
if node[:platform_family].include?("debian")
    directory '#{node['jenkins']['home']}/workspace' do
      owner 'jenkins'
      group 'jenkins'
      mode '0777'
      recursive true
      action :create
    end
    execute 'startjenkins' do
      command "sudo service jenkins start"
    end
    execute 'copyJenkinsClientJar' do
      command "curl -sL http://#{node['jenkinselb']}/jnlpJars/jenkins-cli.jar -o ~/jenkins-cli.jar; chmod 755 #{node['jenkins']['home']}/jenkins-cli.jar"
    end
    execute 'createJobExecUser' do
      command "sleep 30;echo 'jenkins.model.Jenkins.instance.securityRealm.createAccount(\"jobexec\", \"jenkinsadmin\")' | java -jar ~/jenkins-cli.jar -auth @#{node['jenkins']['home']}/cookbooks/jenkins/files/default/authfile -s http://#{node['jenkinselb']}/ groovy ="
    end
    execute 'copyEncryptGroovyScript' do
      command "cp #{node['jenkins']['home']}/cookbooks/jenkins/files/default/encrypt.groovy #{node['jenkins']['home']}/encrypt.groovy"
    end
    execute 'copyXmls' do
      command "tar -xvf #{node['jenkins']['home']}/cookbooks/jenkins/files/default/xmls.tar"
      cwd "#{node['jenkins']['home']}"
    end
    execute 'copyConfigXml' do
      command "cp #{node['jenkins']['home']}/cookbooks/jenkins/files/node/config.xml ."
      cwd "#{node['jenkins']['home']}"
    end
    execute 'copyCredentialsXml' do
      command "cp #{node['jenkins']['home']}/cookbooks/jenkins/files/credentials/credentials.xml ."
      cwd "#{node['jenkins']['home']}"
    end
    # script approvals going in with  xmls.tar will be overwritten
    execute 'copyScriptApprovals' do
      command "cp #{node['jenkins']['home']}/cookbooks/jenkins/files/scriptapproval/scriptApproval.xml #{node['jenkins']['scriptApprovalfiletarget']}"
    end
    service "jenkins" do
      supports [:stop, :start, :restart]
      action [:restart]
    end
    if (File.exist?("#{node['jenkins']['home']}/jazz-core"))
      execute 'downloadgitproj' do
          command "rm -rf #{node['jenkins']['home']}/jazz-core"
          cwd "#{node['jenkins']['home']}"
      end
    end
    execute 'downloadgitproj' do
      command "git clone -b #{node['git_branch']} https://github.com/tmobile/jazz.git jazz-core"
      cwd "#{node['jenkins']['home']}"
    end
    execute 'copylinkdir' do
      command "cp -rf #{node['jenkins']['home']}/jazz-core/aws-apigateway-importer /var/lib; chmod -R 777 /var/lib/aws-apigateway-importer"
    end
    execute 'settingexecutepermissiononallscripts' do
      command "chmod +x #{node['jenkins']['home']}/cookbooks/jenkins/files/credentials/*.sh"
    end
    execute 'configuregitlabuser' do
      only_if  { node[:scm] == 'gitlab' }
      command "sleep 30;#{node['jenkins']['home']}/cookbooks/jenkins/files/credentials/gitlab-user.sh #{node['jenkinselb']} root"
    end
    execute 'configuregitlabtoken' do
      only_if  { node[:scm] == 'gitlab' }
      command "sleep 30;#{node['jenkins']['home']}/cookbooks/jenkins/files/credentials/gitlab-token.sh #{node['jenkinselb']} root"
    end
    execute 'createcredentials-jenkins1' do
      only_if  { node[:scm] == 'bitbucket' }
      command "sleep 30;#{node['jenkins']['home']}/cookbooks/jenkins/files/credentials/jenkins1.sh #{node['jenkinselb']} root"
    end
    execute 'createcredentials-jobexecutor' do
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/credentials/jobexec.sh #{node['jenkinselb']} root"
    end
    execute 'createcredentials-aws' do
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/credentials/aws.sh #{node['jenkinselb']} root"
    end
    execute 'createcredentials-cognitouser' do
      command "sleep 30;#{node['jenkins']['home']}/cookbooks/jenkins/files/credentials/cognitouser.sh #{node['jenkinselb']} root"
    end
    execute 'settingexecutepermissiononallservices' do
      command "chmod +x #{node['jenkins']['home']}/cookbooks/jenkins/files/jobs/*.sh"
    end
    execute 'createJob-create-service' do
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/jobs/job_create-service.sh #{node['jenkinselb']} create-service #{node['scmpath']} root"
    end
    execute 'createJob-delete-service' do
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/jobs/job_delete-service.sh #{node['jenkinselb']} delete-service #{node['scmpath']} root"
    end
    execute 'createJob-job_build_pack_api' do
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/jobs/job_build_java_api.sh #{node['jenkinselb']} build_pack_api #{node['scmpath']} root"
    end
    execute 'createJob-bitbucketteam_newService' do
      only_if  { node[:scm] == 'bitbucket' }
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/jobs/job_bitbucketteam_newService.sh #{node['jenkinselb']} bitbucketteam_newService #{node['scmelb']}  root"
    end
    execute 'createJob-platform_api_services' do
      only_if  { node[:scm] == 'bitbucket' }
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/jobs/job_platform_api_services.sh #{node['jenkinselb']} Platform_API_Services #{node['scmelb']}  root"
    end
    execute 'job_build-deploy-platform-service' do
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/jobs/job_build-deploy-platform-service.sh #{node['jenkinselb']} build-deploy-platform-service  #{node['scmpath']}  #{node['region']}  root"
    end
    execute 'job_cleanup_cloudfront_distributions' do
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/jobs/job_cleanup_cloudfront_distributions.sh #{node['jenkinselb']} cleanup_cloudfront_distributions  #{node['scmpath']} root"
    end
    execute 'createJob-job-pack-lambda' do
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/jobs/job_build_pack_lambda.sh #{node['jenkinselb']} build-pack-lambda #{node['scmpath']}  root"
    end
    execute 'createJob-job-build-pack-website' do
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/jobs/job_build_pack_website.sh #{node['jenkinselb']} build-pack-website #{node['scmpath']}  root"
    end
    execute 'job-gitlab-trigger' do
      only_if  { node[:scm] == 'gitlab' }
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/jobs/job-gitlab-trigger.sh #{node['jenkinselb']} root #{node['scmpath']}"
    end
	execute 'job-trigger-platform-services-build' do
      only_if  { node[:scm] == 'gitlab' }
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/jobs/job-trigger-platform-services-build.sh #{node['jenkinselb']} root #{node['scmpath']}"
    end
    link '/usr/bin/aws-api-import' do
      to "#{node['jenkins']['home']}/jazz-core/aws-apigateway-importer/aws-api-import.sh"
      owner 'jenkins'
      group 'jenkins'
      mode '0777'
    end
    link '/usr/bin/aws' do
      to '/usr/local/bin/aws'
      owner 'root'
      group 'root'
      mode '0777'
    end
    execute 'settingexecutepermissiononallnodescripts' do
      command "chmod +x #{node['jenkins']['home']}/cookbooks/jenkins/files/node/*.sh"
    end
    execute 'configuregitlabplugin' do
      only_if  { node[:scm] == 'gitlab' }
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/node/configuregitlab.sh #{node['scmelb']}"
    end

    execute 'configJenkinsLocConfigXml' do
      command "#{node['jenkins']['home']}/cookbooks/jenkins/files/node/configJenkinsLocConfigXml.sh  #{node['jenkinselb']} #{node['jenkins']['SES-defaultSuffix']}"
    end

    execute 'chownJenkinsfolder' do
      command "chown jenkins:jenkins #{node['jenkins']['home']}"
    end
    service "jenkins" do
      supports [:stop, :start, :restart]
      action [:restart]
    end
end
