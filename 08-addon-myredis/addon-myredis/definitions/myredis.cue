import(
    "encoding/base64"
)

"myredis": {
    annotations: {}
    attributes: workload: definition: {
        apiVersion: "apps/v1"
        kind: "Deployment"
    }
    description: "My Redis component."
    labels: {}
    type: "component"
}

template: {
    output: {
        apiVersion: "v1"
        kind: "ConfigMap"
        metadata: {
            name: "redis-config"
            labels: app: context.name
        }
        data: {
            "redis.conf": """
              dir /data
              port 6379
              bind 0.0.0.0
              appendonly yes
              protected-mode no
              pidfile /data/redis-6379.pid
              requirepass
              """ + " "  + parameter.redisPassword
        }
    }
    outputs: {
        redis: {
        apiVersion: "apps/v1"
        kind: "Deployment"
        metadata: {
            name: "redis"
            labels: app: context.name
        }
        spec: {
            replicas: 1
            selector: matchLabels: app: context.name
            template: {
                metadata: labels: app: context.name
                spec: {
                    containers: [{
                        name: context.name
                        command: ["sh", "-c", "redis-server /usr/local/etc/redis/redis.conf"]
                        image: "quay.io/garycncf/redis:6.2.6"
                        ports: [{
                            containerPort: 6379
                        }]
                        volumeMounts: [{
                            name:      "data"
                            mountPath: "/data"
                        }, {
                            name:      "config"
                            mountPath: "/usr/local/etc/redis/redis.conf"
                            subPath:   "redis.conf"
                        }]
                    }]
                    volumes: [{
                        name: "data"
                        hostPath: path: parameter.hostPath
                    }, {
                        name: "config"
                        configMap: name: "redis-config"
                    }]
                }
            }
        }
    }
    web: {
        apiVersion: "v1"
        kind:       "Service"
        metadata: {
            name: context.name
            labels: app: context.name
        }
        spec: {
            ports: [{
                name: context.name
                port: 6379
                targetPort: 6379
            }]
            selector: app: context.name
            type: parameter.serviceType
      }
    }
    secret: {
        apiVersion: "v1"
        kind:       "Secret"
        metadata: {
            name: "myredis-secret"
        }
        type: "Opaque"
        data: {
            password: base64.Encode(null,parameter.redisPassword)
            ip: base64.Encode(null,context.name + "." + context.namespace + ".svc.cluster.local")
            port: base64.Encode(null,"6379")
        }
    }
    }
    parameter: {
              hostPath: *"/home/k8s/redis/data1" | string
              serviceType: *"ClusterIP" | "NodePort"
              redisPassword: *"123456" | string
            }
}
