resource "aws_iam_role" "eks_role" {
  name = "eks-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "eks-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonEKSCNIPolicy"
}

resource "aws_eks_cluster" "cluster" {
  name     = "eks-cluster"
  role_arn  = aws_iam_role.eks_role.arn
  version   = "1.21"

  vpc_config {
    subnet_ids = aws_subnet.private.*.id
  }

  tags = {
    Name = "eks-cluster"
  }
}

resource "aws_iam_role" "node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "eks-node-role"
  }
}

resource "aws_iam_role_policy_attachment" "node_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn  = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "node_group" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = aws_subnet.private.*.id

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t3.micro"]

  tags = {
    Name = "eks-node-group"
  }
}

