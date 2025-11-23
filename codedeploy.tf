data "aws_subnet" "example" {
  id = "subnet-099061aa370c6df86"
}

resource "aws_lb" "app_lb" {
  name               = "ALB-entrega4"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-03ea60ad1eed89e39"]
  subnets            = [
    "subnet-099061aa370c6df86",
    "subnet-0bf7b5d564333add7",
    "subnet-091b277a72291b093",
    "subnet-00ac6eab2259da0cc",
    "subnet-0adb3a992e90cd8b6",
    "subnet-0ee0cf6de88cc0e0f"
  ]

  enable_deletion_protection = false
}

resource "aws_lb_listener" "prod" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blue.arn
  }
}

resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "8080"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.green.arn
  }
}

resource "aws_lb_target_group" "blue" {
  name        = "entrega4-blue-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = data.aws_subnet.example.vpc_id
  target_type = "ip"
}

resource "aws_lb_target_group" "green" {
  name        = "entrega4-green-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = data.aws_subnet.example.vpc_id
  target_type = "ip"
}

resource "aws_codedeploy_app" "app" {
  name             = "entrega4-app"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "app_deployment_group" {
  app_name               = aws_codedeploy_app.app.name
  deployment_group_name  = "entrega4-deployment-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSAllAtOnce"

  ecs_service {
    cluster_name = aws_ecs_cluster.app_cluster.name
    service_name = aws_ecs_service.app_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.prod.arn]
      }

      test_traffic_route {
        listener_arns = [aws_lb_listener.test.arn]
      }

      target_group {
        name = aws_lb_target_group.blue.name
      }

      target_group {
        name = aws_lb_target_group.green.name
      }
    }
  }

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }
}
