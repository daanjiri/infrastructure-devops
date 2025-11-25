resource "aws_ecs_cluster" "app_cluster" {
  name = "entrega4-cluster"
}

resource "aws_ecs_task_definition" "app_task" {
  family                   = "entrega4-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "entrega4"
      image = "${aws_ecr_repository.app_repo.repository_url}:latest"  # Placeholder, will be updated by CodeDeploy
      essential = true
      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DB_HOST"
          value = "enunciado1-db.ciskeiit5yp6.us-east-1.rds.amazonaws.com"
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = "postgres"
        },
        {
          name  = "DB_USER"
          value = "postgres"
        },
        {
          name  = "DB_PASSWORD"
          value = "Gj180692!*"
        },
        {
          name  = "JWT_SECRET_KEY"
          value = "reach"
        },
        {
          name  = "PGSSLMODE"
          value = "require"
        },
        {
          name  = "NEW_RELIC_LICENSE_KEY"
          value = "058f8709f69d26a6bfffab00867b1cb2FFFFNRAL"
        },
        {
          name  = "NEW_RELIC_APP_NAME"
          value = "entrega4-service"
        },
        {
          name  = "NEW_RELIC_DISTRIBUTED_TRACING_ENABLED"
          value = "true"
        },
        {
          name  = "NEW_RELIC_LOG"
          value = "stdout"
        },
        {
          name  = "NEW_RELIC_LOG_LEVEL"
          value = "info"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/entrega4"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
      healthCheck = {
        command = ["CMD-SHELL", "curl -f http://localhost:8000/ || exit 1"]
        interval = 30
        timeout  = 5
        retries  = 3
        startPeriod = 60
      }
    }
  ])
}

resource "aws_ecs_service" "app_service" {
  name            = "entrega4-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.blue.arn
    container_name   = "entrega4"
    container_port   = 8000
  }

  network_configuration {
    subnets          = [
      "subnet-099061aa370c6df86",
      "subnet-0bf7b5d564333add7",
      "subnet-091b277a72291b093",
      "subnet-00ac6eab2259da0cc",
      "subnet-0adb3a992e90cd8b6",
      "subnet-0ee0cf6de88cc0e0f"
    ]
    security_groups  = ["sg-03ea60ad1eed89e39"]
    assign_public_ip = true
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition, load_balancer]
  }

  depends_on = [aws_lb_listener.prod, aws_lb_listener.test]
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/entrega4"
  retention_in_days = 30
}
