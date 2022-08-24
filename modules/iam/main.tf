
resource "aws_iam_role" "role" {
  name               = var.name
  description        = var.description
  assume_role_policy = var.assume_role_policy
  tags               = merge({ "Name" = "${var.name}-iam-role" }, var.default_tags)
}

resource "aws_iam_role_policy" "policy" {
  name   = "${var.name}-policy"
  role   = aws_iam_role.role.id
  policy = var.policy
}

resource "aws_iam_instance_profile" "instance_profile" {
  count = var.is_instance_profile == 0 ? 0 : 1
  name  = "${var.name}-profile"
  role  = aws_iam_role.role.name
}
