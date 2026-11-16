variable "image_tag" {
  type        = string
  description = "Docker image tag to deploy"
  default     = "latest"
}

job "nginx-app" {
  datacenters = ["dc1"]
  type        = "service"

  group "nginx" {
    count = 1

    shutdown_delay = "5s"

    # Rolling update configuration
    update {
      max_parallel      = 1
      min_healthy_time  = "10s"
      healthy_deadline  = "2m"
      auto_revert       = true
    }

    # Dynamic port allocation
    network {
      port "http" {
        to = 8080
      }
    }

    # Consul service registration and health check
    service {
      name     = "devops-intern-nginx"
      provider = "consul"
      port     = "http"

      check {
        name     = "nginx-http-health"
        type     = "http"
        path     = "/healthz"
        interval = "10s"
        timeout  = "2s"
      }
    }

    # Restart policy
    restart {
      attempts = 2
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    # Rescheduling policy
    reschedule {
      attempts       = 3
      interval       = "1h"
      delay          = "30s"
      delay_function = "exponential"
      max_delay      = "5m"
      unlimited      = false
    }

    task "nginx" {
      driver = "docker"

      config {
        image = "ghcr.io/marvdev-arch/devops-intern-final:${var.image_tag}"
        ports = ["http"]
      }

      resources {
        cpu    = 100
        memory = 64
      }
    }
  }
}