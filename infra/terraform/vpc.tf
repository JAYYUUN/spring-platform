#EKS용 VPC + Public/Private Subnet
resource "aws_vpc" "this" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true // 해당 VPC 위에 올라가는 자원에는 자동으로 DNS 주소 할당됨.
  tags                 = merge(local.tags, { Name = "${var.project}-vpc" })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project}-igw" })
}

# AZ 2개 사용
data "aws_availability_zones" "az" {} #리전에 실제로 사용 가능한 AZ 목록을 가져와라

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet("10.0.0.0/16", 8, count.index)         # 10.0.0.0/24, 10.0.1.0/24
  availability_zone       = data.aws_availability_zones.az.names[count.index] # 0 = ap-northeast-2a, 1 = ap-northeast-2c
  map_public_ip_on_launch = true                                              # 이 Subnet에 생성되는 EC2/ENI에 공인 IP를 자동 할당
  tags = merge(local.tags, {
    Name                     = "${var.project}-public-${count.index}"
    "kubernetes.io/role/elb" = "1" # EKS가 “외부용 LoadBalancer”를 만들 때 이 서브넷을 사용하도록 알려주는 태그
  })
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, 10 + count.index)    # 10.0.10.0/24, 10.0.11.0/24
  availability_zone = data.aws_availability_zones.az.names[count.index] # 0 = ap-northeast-2a, 1 = ap-northeast-2c
  tags = merge(local.tags, {
    Name                              = "${var.project}-private-${count.index}"
    "kubernetes.io/role/internal-elb" = "1" # EKS가 “내부용 LoadBalancer”를 만들 때 이 서브넷을 사용하도록 알려주는 태그
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project}-rt-public" })
}

resource "aws_route" "public_inet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# NAT (private에서 인터넷 나가게)
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(local.tags, { Name = "${var.project}-nat-eip" })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = merge(local.tags, { Name = "${var.project}-nat" })
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${var.project}-rt-private" })
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
