/* This terraform file holds details about configuring SCM repositories.
   The file is presently used for both SCMs - Bitbucket and Gitlab.
*/

// Create Projects in Bitbucket. Will be executed only if the SCM is Bitbucket.
resource "null_resource" "createProjectsInBB" {
  depends_on = ["null_resource.configureJenkinsServer","aws_elasticsearch_domain.elasticsearch_domain"]
  count = "${var.scmbb}"

  provisioner "local-exec" {
    command = "${var.scmclient_cmd} ${lookup(var.scmmap, "username")} ${lookup(var.scmmap, "passwd")}"
  }
}

// Copy the jazz-build-module to SLF in SCM
resource "null_resource" "copyJazzBuildModule" {
  depends_on = ["null_resource.configureJenkinsServer","aws_elasticsearch_domain.elasticsearch_domain","null_resource.createProjectsInBB"]

  provisioner "local-exec" {
    command = "${var.scmpush_cmd} ${lookup(var.scmmap, "elb")} ${lookup(var.scmmap, "username")} ${lookup(var.scmmap, "passwd")} ${var.cognito_pool_username} ${lookup(var.scmmap, "privatetoken")} ${lookup(var.scmmap, "slfid")} ${lookup(var.scmmap, "type")}  ${lookup(var.jenkinsservermap, "jenkins_elb")} ${lookup(var.jenkinsservermap, "jenkinsuser")} ${lookup(var.jenkinsservermap, "jenkinspasswd")} jazz-build-module"
  }
}

// Configure jazz-installer-vars.json and push it to SLF/jazz-build-module
resource "null_resource" "configureJazzBuildModule" {
 depends_on = ["null_resource.copyJazzBuildModule"]

 connection {
   host = "${lookup(var.jenkinsservermap, "jenkins_public_ip")}"
   user = "${lookup(var.jenkinsservermap, "jenkins_ssh_login")}"
   port = "${lookup(var.jenkinsservermap, "jenkins_ssh_port")}"
   type = "ssh"
   port = "${lookup(var.jenkinsservermap, "jenkins_ssh_port")}"
   private_key = "${file("${lookup(var.jenkinsservermap, "jenkins_ssh_key")}")}"
 }
 provisioner "remote-exec"{
   inline = [
       "git clone http://${lookup(var.scmmap, "username")}:${lookup(var.scmmap, "passwd")}@${lookup(var.scmmap, "elb")}${lookup(var.scmmap, "scmPathExt")}/slf/jazz-build-module.git",
       "cd jazz-build-module",
       "cp ~/cookbooks/jenkins/files/node/jazz-installer-vars.json .",
       "git add jazz-installer-vars.json",
       "git config --global user.email ${var.cognito_pool_username}",
       "git commit -m 'Adding Json file to repo'",
       "git push -u origin master",
       "cd ..",
       "sudo rm -rf jazz-build-module" ]
 }
  //This would be the last command which needs to be run which triggers the Jenkins Build deploy job
 provisioner "local-exec" {
    command = "curl  -X GET -u ${lookup(var.jenkinsservermap, "jenkinsuser")}:${lookup(var.jenkinsservermap, "jenkinspasswd")} http://${lookup(var.jenkinsservermap, "jenkins_elb")}/job/deploy-all-platform-services/buildWithParameters?token=dep-all-ps-71717&region=${var.region}"
  }
}

// Push all other repos to SLF
resource "null_resource" "configureSCMRepos" {
  depends_on = ["null_resource.configureJazzBuildModule"]

  provisioner "local-exec" {
    command = "${var.scmpush_cmd} ${lookup(var.scmmap, "elb")} ${lookup(var.scmmap, "username")} ${lookup(var.scmmap, "passwd")} ${var.cognito_pool_username} ${lookup(var.scmmap, "privatetoken")} ${lookup(var.scmmap, "slfid")} ${lookup(var.scmmap, "type")} ${lookup(var.jenkinsservermap, "jenkins_elb")} ${lookup(var.jenkinsservermap, "jenkinsuser")} ${lookup(var.jenkinsservermap, "jenkinspasswd")}"
  }
}
