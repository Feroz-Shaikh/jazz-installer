/* This terraform file holds details about configuring provisioners like git, maven, npm etc. for jenkins server.
*/

resource "null_resource" "configureProvisioners" {
// Modifying config values before copying cookbooks to Jenkins server.

  depends_on = ["aws_api_gateway_rest_api.jazz-dev", "aws_s3_bucket.jazz-web", "aws_iam_role.lambda_role", "aws_elasticsearch_domain.elasticsearch_domain", "null_resource.ses_setup"]

  provisioner "local-exec" {
    command = "${var.configureJenkinsSSHUser_cmd} ${lookup(var.jenkinsservermap, "jenkins_ssh_login")} ${var.jenkinsattribsfile} ${var.jenkinsclientrbfile}"
  }
  provisioner "local-exec" {
    command = "${var.configureJenkinselb_cmd} ${lookup(var.jenkinsservermap, "jenkins_elb")} ${var.jenkinsattribsfile} ${lookup(var.jenkinsservermap, "jenkinsuser")} ${lookup(var.jenkinsservermap, "jenkinspasswd")}"
  }
  provisioner "local-exec" {
    command = "${var.configureJazzCore_cmd} ${var.envPrefix} ${var.cognito_pool_username}"
  }
  provisioner "local-exec" {
    command = "${var.configurescmelb_cmd} ${var.scmbb} ${lookup(var.scmmap, "elb")} ${var.jenkinsattribsfile} ${var.jenkinsjsonpropsfile} ${var.scmclient_cmd}"
  }
  provisioner "local-exec" {
	  command = "sed -i 's/\"jenkins_username\"/\"${lookup(var.jenkinsservermap, "jenkinsuser")}\"/g' ${var.jenkinsjsonpropsfile}"
  }
  provisioner "local-exec" {
    command = "${var.modifyPropertyFile_cmd} JENKINS_PASSWORD ${lookup(var.jenkinsservermap, "jenkinspasswd")} ${var.jenkinsjsonpropsfile}"
  }
  provisioner "local-exec" {
	  command = "sed -i 's/\"scm_username\"/\"${lookup(var.scmmap, "username")}\"/g' ${var.jenkinsjsonpropsfile}"
  }
  provisioner "local-exec" {
    command = "${var.modifyPropertyFile_cmd} PASSWORD ${lookup(var.scmmap, "passwd")} ${var.jenkinsjsonpropsfile}"
  }
  provisioner "local-exec" {
    command = "${var.modifyPropertyFile_cmd} ADMIN ${var.cognito_pool_username} ${var.jenkinsjsonpropsfile}"
  }
  provisioner "local-exec" {
    command = "${var.modifyPropertyFile_cmd} PASSWD ${var.cognito_pool_password} ${var.jenkinsjsonpropsfile}"
  }
  provisioner "local-exec" {
    command = "${var.modifyPropertyFile_cmd} ACCOUNTID ${var.jazz_accountid} ${var.jenkinsjsonpropsfile}"
  }
  provisioner "local-exec" {
    command = "${var.modifyPropertyFile_cmd} REGION ${var.region} ${var.jenkinsjsonpropsfile}"
  }
  // Modifying subnet replacement before copying cookbooks to Jenkins server.
  provisioner "local-exec" {
    command = "${var.configureSubnet_cmd} ${lookup(var.jenkinsservermap, "jenkins_security_group")} ${lookup(var.jenkinsservermap, "jenkins_subnet")} ${var.envPrefix} ${var.jenkinsjsonpropsfile}"
  }
}
