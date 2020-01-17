job "sockshopui" {
  datacenters = ["dc1"]

  type = "system"

  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

  update {
    stagger = "10s"
    max_parallel = 1
  }

  # - frontend #
  group "frontend" {

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      mode = "bridge"

      port "http" {
        static = 80
        to     = 80
      }
    }

    # - frontend app - #
    task "front-end" {
      driver = "docker"

      config {
        image = "selmison/nomad-frontend:latest"
        command = "/usr/local/bin/node"
        args = ["server.js", "--domain=service.consul"]
        port_map = {
          http = 8079
        }
      }

      service {
        name = "front-end"
        tags = ["app", "frontend", "front-end"]
        port = "http"
        connect {
          sidecar_service {
            proxy {
              upstreams { //Maging upstream services that a Consul Connect proxy routes to
                destination_name = "user"
                local_bind_port  = 28080
              }
              upstreams { //Maging upstream services that a Consul Connect proxy routes to
                destination_name = "catalogue"
                local_bind_port  = 28081
              }
              upstreams { //Maging upstream services that a Consul Connect proxy routes to
                destination_name = "carts"
                local_bind_port  = 28082
              }
              upstreams { //Maging upstream services that a Consul Connect proxy routes to
                destination_name = "orders"
                local_bind_port  = 28083
              }
              upstreams { //Maging upstream services that a Consul Connect proxy routes to
                destination_name = "payment"
                local_bind_port  = 28084
              }
            }
          }
        }
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 128 # 128MB
        network {
          mbits = 10
          port "http" {
            static = 80
          }
        }
      }
    } # - end frontend app - #
  } # - end frontend - #
}
