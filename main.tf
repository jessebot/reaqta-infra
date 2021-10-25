# vpc - virtual private cloud - for eks specifically
module "vpc"{
  source = "terraform-aws-modules/vpc/aws"

  name = "interview-assignment"
  cidr = "10.0.0.0/16"

  azs             = ["eu-central-1b", "eu-central-1a"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# Creating IAM role for Kubernetes clusters to make calls to other AWS services on your behalf to manage the resources that you use with the service.
resource "aws_iam_role" "iam-role-eks-cluster" {
  name = "terraformekscluster"
  assume_role_policy = <<POLICY
{
 "Version": "2012-10-17",
 "Statement": [
   {
   "Effect": "Allow",
   "Principal": {
    "Service": "eks.amazonaws.com"
   },
   "Action": "sts:AssumeRole"
   }
  ]
 }
POLICY
}

# Attaching the EKS-Cluster policies to the terraformekscluster role.
resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.iam-role-eks-cluster.name}"
}


# Security group for network traffic to and from AWS EKS Cluster.
resource "aws_security_group" "eks-cluster" {
  name        = "SG-eks-cluster"
  vpc_id      = module.vpc.vpc_id
  depends_on = [module.vpc]

  # Egress allows Outbound traffic from the EKS cluster to the  Internet
  egress {                   # Outbound Rule
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Ingress allows Inbound traffic to EKS cluster from the  Internet
  ingress {                  # Inbound Rule
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# Creating the EKS cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "terraform-EKScluster-reaqta-interview"
  role_arn =  "${aws_iam_role.iam-role-eks-cluster.arn}"
  version  = "1.19"

  # Adding VPC Configuration
  vpc_config {             # Configure EKS with vpc and network settings
   security_group_ids = ["${aws_security_group.eks-cluster.id}"]
   subnet_ids         = module.vpc.private_subnets
    }

  depends_on = [aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy]
}

# Creating IAM role for EKS nodes to work with other AWS Services.
resource "aws_iam_role" "eks_nodes" {
  name = "eks-node-group"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Attaching the different Policies to Node Members.
# standard worker
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

# container network interface
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

# EC2 (virtual machines) container registry - read only
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# Create EKS cluster node group
resource "aws_eks_node_group" "node" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "node_group1"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = module.vpc.public_subnets

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
  ]
}
