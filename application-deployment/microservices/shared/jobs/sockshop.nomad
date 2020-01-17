job "sockshop" {
  datacenters = ["dc1"]

  constraint {
    attribute = "${attr.kernel.name}"
    value = "linux"
  }

  update {
    stagger = "10s"
    max_parallel = 1
  }

  # - user - #
  group "user" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      mode = "bridge"
    }

    service {
      name = "user"
      tags = ["app", "user"]
      port = "80"

      connect { // To start an Envoy proxy sidecar for allowing incoming connections via Consul Connect.
        sidecar_service {}
      }
    }   

    # - app - #
    task "user" {
      driver = "docker"

      env {
	      HATEAOS = "user.service.consul"
      }

      config {
        image = "weaveworksdemos/user:master-5e88df65"
      }

      vault {
        policies = ["sockshop-read"]
      }

      template {
        data = <<EOH
        MONGO_PASS="{{with secret "secret/sockshop/databases/userdb" }}{{.Data.pwd}}{{end}}"
        EOH
        destination = "secrets/user_db.env"
        env = true
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 256 # 256MB
      }
    } # - end app - #

    # - db - #
    task "user-db" {
      driver = "docker"

      config {
        image = "weaveworksdemos/user-db:master-5e88df65"
      }

      vault {
        policies = ["sockshop-read"]
      }

      template {
        data = <<EOH
        MONGO_PASS="{{with secret "secret/sockshop/databases/userdb" }}{{.Data.pwd}}{{end}}"
        EOH
        destination = "secrets/user_db.env"
        env = true
      }

      service {
        name = "user-db"
        tags = ["db", "user", "user-db"]
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 96 # 96MB
      }
    } # - end db - #
  } # - end user - #

  # - catalogue - #
  group "catalogue" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      mode = "bridge"
    }

    service {
      name = "catalogue"
      tags = ["app", "catalogue"]
      port = "80"
      connect { // To start an Envoy proxy sidecar for allowing incoming connections via Consul Connect.
        sidecar_service {}
      }
    }    

    # - app - #
    task "catalogue" {
      driver = "docker"

      config {
        image = "weaveworksdemos/catalogue:0.3.5"
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 128 # 32MB
      }
    } # - end app - #

    # - db - #
    task "cataloguedb" {
      driver = "docker"

      config {
        image = "weaveworksdemos/catalogue-db:0.3.5"
      }

      vault {
	      policies = ["sockshop-read"]
      }

      template {
        data = <<EOH
	      MYSQL_ROOT_PASSWORD="{{with secret "secret/sockshop/databases/cataloguedb" }}{{.Data.pwd}}{{end}}"
        EOH
	      destination = "secrets/mysql_root_pwd.env"
        env = true
      }

      env {
        MYSQL_DATABASE = "socksdb"
        MYSQL_ALLOW_EMPTY_PASSWORD = "false"
      }

      service {
        name = "catalogue-db"
        tags = ["db", "catalogue", "catalogue-db"]
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 256 # 256MB
      }

    } # - end db - #
  } # - end catalogue - #

  # - carts - #
  group "carts" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      mode = "bridge"
    }

    service {
      name = "carts"
      tags = ["app", "carts"]
      port = "80"
      connect { // To start an Envoy proxy sidecar for allowing incoming connections via Consul Connect.
        sidecar_service {}
      }
    }    

    # - app - #
    task "carts" {
      driver = "docker"

      env {
	      db = "carts-db.service.consul"
      }

      config {
        image = "weaveworksdemos/carts:0.4.8"
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 1024 # 1024MB
      }
    } # - end app - #

    # - db - #
    task "cartdb" {
      driver = "docker"

      config {
        image = "mongo:3.4.3"
      }

      service {
        name = "carts-db"
        tags = ["db", "carts", "carts-db"]
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 128 # 128MB
      }
    } # - end db - #
  } # - end carts - #

  # - orders - #
  group "orders" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      mode = "bridge"
    }

    service {
      name = "orders"
      tags = ["app", "orders"]
      port = "80"
      connect { // To start an Envoy proxy sidecar for allowing incoming connections via Consul Connect.
        sidecar_service {}
      }
    }

    # - app - #
    task "orders" {
      driver = "docker"

      env {
        db = "orders-db.service.consul"
	      domain = "service.consul"
      }

      config {
        image = "weaveworksdemos/orders:0.4.7"
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 1024 # 1024MB
      }
    } # - end app - #

    # - db - #
    task "ordersdb" {
      driver = "docker"

      config {
        image = "mongo:3.4.3"
      }

      service {
        name = "orders-db"
        tags = ["db", "orders", "orders-db"]      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 64 # 64MB
      }
    } # - end db - #
  } # - end orders - #

  # - payment - #
  group "payment" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      mode = "bridge"
    }

    service {
      name = "payment"
      tags = ["app", "payment"]
      port = "80"
      connect { // To start an Envoy proxy sidecar for allowing incoming connections via Consul Connect.
        sidecar_service {}
      }
    }

    # - app - #
    task "payment" {
      driver = "docker"

      config {
        image = "weaveworksdemos/payment:0.4.3"
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 16 # 16MB
      }
    } # - end app - #
  } # - end payment - #

  # - backoffice - #
  group "backoffice" {
    count = 1

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    network {
      mode = "bridge"
    }

    service {
      name = "shipping"
      tags = ["app", "shipping"]
      port = "80"
      connect { // To start an Envoy proxy sidecar for allowing incoming connections via Consul Connect.
        sidecar_service {}
      }
    }

    # - rabbitmq - #
    task "rabbitmq" {
      driver = "docker"

      config {
        image = "rabbitmq:3.6.8"
      }

      service {
        name = "rabbitmq"
        tags = ["message-broker", "rabbitmq"]
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 160 # 160MB
      }
    } # - end rabbitmq - #

    # - shipping - #
    task "shipping" {
      driver = "docker"

      env {
	      spring_rabbitmq_host = "${NOMAD_IP_http}"
      }

      config {
        image = "weaveworksdemos/shipping:0.4.8"
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 1024 # 1024MB
      }
    } # - end shipping - #

    # - app - #
    task "queue-master" {
      driver = "java"

      config {
        jar_path = "local/queue-master.jar"
        jvm_options = ["-Xms512m", "-Xmx512m"]
        args = ["--port=8099", "--spring.rabbitmq.host=${attr.unique.network.ip-address}"]
      }

      artifact {
        source = "https://s3.amazonaws.com/nomad-consul-microservices-demo/queue-master.jar"
      }


      service {
        name = "queue-master"
        tags = ["app", "queue-master"]
      }

      resources {
        cpu = 100 # 100 Mhz
        memory = 1024 # 1024MB
      }
    } # - end queue-master - #

  } # - end backoffice - #
}
