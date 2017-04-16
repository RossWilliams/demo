module "vpc" {
  source = "./modules/vpc"
  depends_id = ""

  azs = "${ var.aws_azs }"
  cidr = "${ var.vpc_cidr }"
  kubelet_version = "${ var.kubelet_version }"
  name = "${ var.name }"
  region = "${ var.aws_region }"
}

module "security" {
  source = "./modules/security"

  allow_ssh_cidr = "${ var.allow_ssh_cidr }"
  vpc_cidr = "${ var.vpc_cidr }"
  name = "${ var.name }"
  vpc_id = "${ module.vpc.id }"
}


module "iam" {
  source = "./modules/iam"
  # depends_id = "${ module.s3.depends_id }"
  # s3_bucket = "${ module.s3.bucket }"
  name = "${ var.name }"
}


module "route53" {
  source = "./modules/route53"

  etcd_ips = "${ var.etcd_ips }"
  internal_tld = "${ var.internal_tld }"
  name = "${ var.name }"
  vpc_id = "${ module.vpc.id }"
}

module "etcd" {
  source = "./modules/etcd"
  depends_id = "${ module.route53.depends_id }"
  instance_profile_name = "${ module.iam.instance_profile_name_master }"

  ami_id = "${ var.aws_image_ami }"
  cluster_domain = "${ var.cluster_domain }"
  kubelet_aci = "${ var.kubelet_aci }"
  kubelet_version = "${ var.kubelet_version }"
  dns_service_ip = "${ var.dns_service_ip }"
  etcd_ips = "${ var.etcd_ips }"
  etcd_security_group_id = "${ module.security.etcd_id }"
  external_elb_security_group_id = "${ module.security.external_elb_id }"
  instance_type = "${ var.aws_master_vm_size }"
  internal_tld = "${ var.internal_tld }"
  key_name = "${ var.aws_key_name }"
  name = "${ var.name }"
  pod_cidr = "${ var.pod_cidr }"
  region = "${ var.aws_region }"
  service_cidr = "${ var.service_cidr }"
  subnet_ids_private = "${ module.vpc.subnet_ids_private }"
  subnet_ids_public = "${ module.vpc.subnet_ids_public }"
  vpc_id = "${ module.vpc.id }"
  ca = "${file("${ var.data_dir }/.cfssl/ca.pem")}"
  k8s_etcd = "${file("${ var.data_dir }/.cfssl/k8s_etcd.pem")}"
  k8s_etcd_key = "${file("${ var.data_dir }/.cfssl/k8s-etcd-key.pem")}"
  k8s_apiserver = "${file("${ var.data_dir }/.cfssl/k8s-apiserver.pem")}"
  k8s_apiserver_key = "${file("${ var.data_dir }/.cfssl/k8s_apiserver_key.pem")}"
}

module "bastion" {
  source = "./modules/bastion"
  depends_id = "${ module.etcd.depends_id }"

  ami_id = "${ var.aws_image_ami }"
  instance_type = "${ var.aws_bastion_vm_size }"
  internal_tld = "${ var.internal_tld }"
  key_name = "${ var.aws_key_name }"
  name = "${ var.name }"
  security_group_id = "${ module.security.bastion_id }"
  subnet_ids = "${ module.vpc.subnet_ids_public }"
  vpc_id = "${ module.vpc.id }"
}

module "worker" {
  source = "./modules/worker"
  depends_id = "${ module.route53.depends_id }"
  instance_profile_name = "${ module.iam.instance_profile_name_worker }"

  ami_id = "${ var.aws_image_ami }"
  capacity = {
    desired = 3
    max = 5
    min = 3
  }
  cluster_domain = "${ var.cluster_domain }"
  kubelet_aci = "${ var.kubelet_aci }"
  kubelet_version = "${ var.kubelet_version }"
  dns_service_ip = "${ var.dns_service_ip }"
  instance_type = "${ var.aws_worker_vm_size }"
  internal_tld = "${ var.internal_tld }"
  key_name = "${ var.aws_key_name }"
  name = "${ var.name }"
  region = "${ var.aws_region }"
  security_group_id = "${ module.security.worker_id }"
  subnet_ids = "${ module.vpc.subnet_ids_private }"
  ca = "${file("${ var.data_dir }/.cfssl/ca.pem")}"
  k8s_worker = "${file("${ var.data_dir }/.cfssl/k8s-worker.pem")}"
  k8s_worker_key = "${file("${ var.data_dir }/.cfssl/k8s-worker-key.pem")}"

  volume_size = {
    ebs = 250
    root = 52
  }
  vpc_id = "${ module.vpc.id }"
  worker_name = "general"
}

module "kubeconfig" {
  source = "./modules/kubeconfig"

  admin_key_pem = "${ var.data_dir }/.cfssl/k8s-admin-key.pem"
  admin_pem = "${ var.data_dir }/.cfssl/k8s-admin.pem"
  ca_pem = "${ var.data_dir }/.cfssl/ca.pem"
  data_dir = "${ var.data_dir }"
  master_elb = "${ module.etcd.external_elb }"
  name = "${ var.name }"
}