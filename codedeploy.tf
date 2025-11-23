data "aws_lb" "app_lb" {
  name = "entrega-3-prod-alb"
}

data "aws_lb_listener" "prod" {
  load_balancer_arn = data.aws_lb.app_lb.arn
  port              = 80
}

data "aws_lb_listener" "test" {
  load_balancer_arn = data.aws_lb.app_lb.arn
  port              = 8080
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
        listener_arns = [data.aws_lb_listener.prod.arn]
      }

      test_traffic_route {
        listener_arns = [data.aws_lb_listener.test.arn]
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
