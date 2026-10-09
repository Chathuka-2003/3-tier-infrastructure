# three-tier-demo

Small Spring Boot 3 / Java 21 app that exercises all three tiers:

| Endpoint | What it proves |
|---|---|
| `GET /api/hello` | ALB -> ECS works. `instance` changes when you have several tasks |
| `POST /api/notes` | App can WRITE to MySQL |
| `GET /api/notes` | App can READ from MySQL (data survives task restarts) |
| `GET /actuator/health` | ALB health check; reports DOWN if MySQL is unreachable |

## Run locally (optional)
```bash
docker run -d --name demo-mysql -e MYSQL_ALLOW_EMPTY_PASSWORD=yes -e MYSQL_DATABASE=appdb -p 3306:3306 mysql:8.4
docker build -t three-tier-demo:local .
docker run --rm -p 8080:8080 --network host three-tier-demo:local
curl localhost:8080/api/hello
```

## Deploy to the AWS stack
See the steps in the chat / PART2.md: build with `--platform linux/amd64`, push to ECR,
set `container_image`, `container_port = 8080`, `health_check_path = "/actuator/health"`.
