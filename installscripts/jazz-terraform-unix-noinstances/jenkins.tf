/* This terraform file holds details about configuring jenkins server itself.
   This file has 2 mutually exclusive resources - configureJenkinsInstance and configureJenkinsDocker for jenkins instance and docker respectively
*/

resource "null_resource" "configureJenkinsInstance" {
  count = "${var.scenario1}"
  depends_on = ["null_resource.configureProvisioners", "aws_elasticsearch_domain.elasticsearch_domain"]

  connection {
    host = "${lookup(var.jenkinsservermap, "jenkins_public_ip")}"
    user = "${lookup(var.jenkinsservermap, "jenkins_ssh_login")}"
    port = "${lookup(var.jenkinsservermap, "jenkins_ssh_port")}"
    type = "ssh"
    private_key = "${file("${lookup(var.jenkinsservermap, "jenkins_ssh_key")}")}"
  }

  provisioner "file" {
    source      = "${var.cookbooksDir}/"
    destination = "~/cookbooks"
  }
  provisioner "file" {
    source      = "${var.chefconfigDir}/"
    destination = "~/chefconfig"
  }
  provisioner "remote-exec" {
    inline = [
           "sudo sh ~/cookbooks/installChef.sh",
           "sudo curl -L https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 -o /usr/local/bin/jq",
           "sudo chmod 755 /usr/local/bin/jq",
           "cat ~/cookbooks/jenkins/files/plugins/plugins0* > plugins.tar",
           "sudo chmod 777 plugins.tar",
           "sudo tar -xf plugins.tar -C /var/lib/jenkins/",
           "sudo curl -O https://bootstrap.pypa.io/get-pip.py&& sudo python get-pip.py",
           "sudo chmod -R o+w /usr/lib/python2.7/* /usr/bin/",
           "sudo chef-client --local-mode -c ~/chefconfig/jenkins_client.rb -j ~/chefconfig/node-jenkinsserver-packages.json"
     ]
  }
}

//
resource "null_resource" "configureJenkinsDocker" {
  count = "${var.scenario2or3}"
  depends_on = ["null_resource.configureProvisioners", "aws_elasticsearch_domain.elasticsearch_domain"]

  provisioner "local-exec" {
    command = "bash ${var.launchJenkinsCE_cmd}"
  }

}

resource "null_resource" "postJenkinsConfiguration" {

  depends_on = ["null_resource.configureJenkinsInstance", "null_resource.configureJenkinsDocker", "aws_elasticsearch_domain.elasticsearch_domain"]

  provisioner "local-exec" {
    command = "${var.modifyCodebase_cmd}  ${lookup(var.jenkinsservermap, "jenkins_security_group")} ${lookup(var.jenkinsservermap, "jenkins_subnet")} ${aws_iam_role.lambda_role.arn} ${var.region} ${var.envPrefix} ${var.cognito_pool_username}"
  }
  // Injecting bootstrap variables into Jazz-core Jenkinsfiles*
  provisioner "local-exec" {
    command = "${var.injectingBootstrapToJenkinsfiles_cmd} ${lookup(var.scmmap, "elb")} ${lookup(var.scmmap, "type")}"
  }

}
