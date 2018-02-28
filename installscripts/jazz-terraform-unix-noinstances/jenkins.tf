/* This terraform file holds details about configuring jenkins server itself.
*/

resource "null_resource" "configureJenkinsServer" {

  depends_on = ["null_resource.configureProvisioners", "aws_elasticsearch_domain.elasticsearch_domain"]

  connection {
    host = "${lookup(var.jenkinsservermap, "jenkins_public_ip")}"
    user = "${lookup(var.jenkinsservermap, "jenkins_ssh_login")}"
    port = "${lookup(var.jenkinsservermap, "jenkins_ssh_port")}"
    type = "ssh"
    private_key = "${file("${lookup(var.jenkinsservermap, "jenkins_ssh_key")}")}"
  }

  provisioner "remote-exec" {
    inline = [
       "sudo chef-client --local-mode -c ~/chefconfig/jenkins_client.rb --override-runlist blankJenkins::configureblankjenkins"
     ]
  }
  provisioner "local-exec" {
    command = "${var.modifyCodebase_cmd}  ${lookup(var.jenkinsservermap, "jenkins_security_group")} ${lookup(var.jenkinsservermap, "jenkins_subnet")} ${aws_iam_role.lambda_role.arn} ${var.region} ${var.envPrefix} ${var.cognito_pool_username}"
  }
  // Injecting bootstrap variables into Jazz-core Jenkinsfiles*
  provisioner "local-exec" {
    command = "${var.injectingBootstrapToJenkinsfiles_cmd} ${lookup(var.scmmap, "elb")} ${lookup(var.scmmap, "type")}"
  }
}
