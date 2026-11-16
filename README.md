# 17. Complete Deployment Guide — Follow Along

This section explains how another developer can clone this repository and reproduce the deployment on their own computer.

The instructions use Windows 11, Ubuntu WSL2 and Docker Desktop. Linux users can run the Linux commands directly in their terminal.

## Step 1: Install the Prerequisites

Install the following tools:

| Tool | Purpose |
|---|---|
| Git | Clone and manage the repository |
| Visual Studio Code | Open and edit project files |
| Ubuntu WSL2 | Run Linux commands |
| Docker Desktop | Build and run containers |
| HashiCorp Nomad | Deploy and manage the application |
| HashiCorp Consul | Service registration and discovery |

Useful official installation resources:

- Git: https://git-scm.com/downloads
- Visual Studio Code: https://code.visualstudio.com/
- Docker Desktop: https://www.docker.com/products/docker-desktop/
- Ubuntu WSL: https://learn.microsoft.com/en-us/windows/wsl/install
- Nomad: https://developer.hashicorp.com/nomad/install
- Consul: https://developer.hashicorp.com/consul/install

After installing Docker Desktop, enable Ubuntu under **Settings → Resources → WSL Integration**.

Open Ubuntu and verify:

```bash
git --version
docker --version
```

Check that Docker is working:

```bash
docker ps
```

If Docker is unavailable, confirm Docker Desktop is running and Ubuntu WSL integration is enabled.

## Step 2: Clone the GitHub Repository

Open Ubuntu and run:

```bash
git clone https://github.com/MarvDev-Arch/devops-intern-final.git
```

Enter the project directory:

```bash
cd devops-intern-final
```

Open the project in Visual Studio Code:

```bash
code .
```

You should see the project folders:

```text
app/
scripts/
.github/
nomad/
monitoring/
docs/
README.md
```

## Step 3: Run the Linux Scripts

Make the scripts executable:

```bash
chmod +x scripts/*.sh
```

Run the system information script:

```bash
./scripts/sysinfo.sh
```

This displays information about the Linux system, current user, disk, memory and Docker availability.

Run the application health-check script:

```bash
./scripts/healthcheck.sh http://localhost:8080/healthz
```

The health-check command will succeed when an application is responding at the supplied URL.

## Step 4: Build the Docker Image

From the project root, build the application image:

```bash
docker build --build-arg BUILD_SHA=local-build -t devops-intern-final:v1 ./app
```

Check that the image was created:

```bash
docker images devops-intern-final
```

Verify the container runs as a non-root user:

```bash
docker run --rm devops-intern-final:v1 whoami
```

Expected output:

```text
appuser
```

## Step 5: Run the Application with Docker

Start the container:

```bash
docker run -d --name devops-app -p 8080:8080 devops-intern-final:v1
```

Check the container:

```bash
docker ps
```

Test the application:

```bash
curl http://localhost:8080/
```

Test the health endpoint:

```bash
curl http://localhost:8080/healthz
```

Expected health response:

```text
healthy
```

Open the application in your browser:

```text
http://localhost:8080
```

The NGINX application should display its homepage.

If port 8080 is already in use, use another host port:

```bash
docker run -d --name devops-app -p 8081:8080 devops-intern-final:v1
```

Then access:

```text
http://localhost:8081
```

## Step 6: Pull the Published Image from GHCR

Instead of building the image locally, you can pull the image published by GitHub Actions.

```bash
docker pull ghcr.io/marvdev-arch/devops-intern-final:latest
```

Run the published image:

```bash
docker run -d --name ghcr-app -p 8082:8080 ghcr.io/marvdev-arch/devops-intern-final:latest
```

Test it:

```bash
curl http://localhost:8082/healthz
```

Expected response:

```text
healthy
```

If the package is private, authenticate to GHCR using a GitHub token with the required package read permission before pulling.

## Step 7: Start Nomad

Nomad is used to schedule and manage the containerized application.

Install Nomad using the official installation instructions.

Open a new Ubuntu terminal and start the development agent:

```bash
nomad agent -dev
```

Keep this terminal open.

Open another Ubuntu terminal and navigate to the project:

```bash
cd /mnt/c/Users/Dell/Desktop/devops-intern-final
```

If you cloned the repository somewhere else, use that location instead.

Verify the Nomad agent:

```bash
nomad node status
```

The node should show a ready status.

## Step 8: Start Consul

Consul provides service registration and discovery for the Nomad application.

In another Ubuntu terminal, start Consul:

```bash
consul agent -dev
```

Keep this terminal open.

Check the Consul cluster:

```bash
consul members
```

The local Consul agent should appear as alive.

**Important:** These development-mode commands are for local assessment and testing. Do not use development mode for production deployments.

## Step 9: Validate the Nomad Job

Return to the project terminal:

```bash
cd /mnt/c/Users/Dell/Desktop/devops-intern-final
```

Validate the job file:

```bash
nomad job validate nomad/nginx-app.nomad.hcl
```

Preview the deployment:

```bash
nomad job plan nomad/nginx-app.nomad.hcl
```

If the job is valid and the required services are available, proceed with deployment.

## Step 10: Deploy the Application with Nomad

Submit the job:

```bash
nomad job run nomad/nginx-app.nomad.hcl
```

Check its status:

```bash
nomad job status nginx-app
```

You should see the job running.

Check the allocation:

```bash
nomad job allocs nginx-app
```

Copy the allocation ID shown in the output, then inspect it:

```bash
nomad alloc status <ALLOCATION_ID>
```

Replace `<ALLOCATION_ID>` with the actual allocation ID.

Look for the host port mapped to container port 8080.

For example, if Nomad assigns port 20791, test:

```bash
curl http://localhost:20791/
```

Check the health endpoint:

```bash
curl http://localhost:20791/healthz
```

The expected health response is:

```text
healthy
```

**Important:** Nomad dynamically allocates the host port. Do not assume it will always be 20791. Always check the allocation details.

## Step 11: Start the Monitoring Stack

The monitoring stack contains Loki, Promtail and Grafana.

From the project root, run:

```bash
docker compose -f monitoring/docker-compose.yaml up -d
```

Check the running containers:

```bash
docker ps
```

You should see the monitoring services:

```text
loki
promtail
grafana
```

Check Loki:

```bash
curl http://localhost:3100/ready
```

Check Promtail logs:

```bash
docker logs promtail --tail 30
```

Check Grafana:

```text
http://localhost:3000
```

The default local Grafana login is:

```text
Username: admin
Password: admin
```

Change the default password when prompted or before using Grafana beyond local testing.

## Step 12: Connect Grafana to Loki

1. Open Grafana at `http://localhost:3000`.
2. Navigate to Connections.
3. Open Data Sources.
4. Select Add data source.
5. Choose Loki.
6. Enter the Loki URL:

```text
http://loki:3100
```

7. Select Save & Test.

A successful connection confirms that Grafana can reach Loki through the Docker Compose network.

## Step 13: Generate Application Logs

Find the host port assigned to the Nomad application:

```bash
nomad job allocs nginx-app
```

Use that port to generate requests.

For example:

```bash
curl http://localhost:20791/
```

Generate a successful health-check request:

```bash
curl http://localhost:20791/healthz
```

Generate a 404 request:

```bash
curl http://localhost:20791/page-not-found
```

Replace `20791` with the actual allocated port.

## Step 14: Query Logs in Grafana Explore

Open Grafana:

```text
http://localhost:3000
```

Navigate to **Explore**, select Loki as the data source, and inspect the labels available in the label browser.

If Promtail has successfully ingested logs and the `job` label is configured, try:

```logql
{job="nginx"}
```

To inspect containers with NGINX in their container label:

```logql
{container=~".*nginx.*"}
```

To filter access logs for non-200 responses, use the query below if the NGINX access-log format matches the pattern:

```logql
{job="nginx"} | pattern `<remote> - <user> [<time>] "<method> <path> <protocol>" <status> <size> <referer> "<agent>"` | status != "200"
```

If no logs appear, check the Promtail configuration, Docker log access, available labels and Promtail logs before assuming ingestion is working.

Capture a screenshot of the successful Grafana Explore query and save it inside:

```text
docs/screenshots/
```

## Step 15: Stop the Services

Stop the monitoring stack:

```bash
docker compose -f monitoring/docker-compose.yaml down
```

Stop the Nomad job:

```bash
nomad job stop nginx-app
```

Stop any standalone Docker container you started:

```bash
docker stop devops-app
docker rm devops-app
```

Stop the Nomad and Consul development agents using `Ctrl + C` in their respective terminals.

## Step 16: Verify the GitHub Actions Pipeline

After making changes to the project:

```bash
git status
```

Create a feature branch:

```bash
git checkout -b feature/my-update
```

Stage and commit your changes:

```bash
git add .
git commit -m "feat: update deployment configuration"
```

Push the branch:

```bash
git push -u origin feature/my-update
```

Open the repository on GitHub and create a pull request targeting `main`.

GitHub Actions should automatically run the configured checks.

After the pull request is reviewed and merged, the main-branch workflow publishes the Docker image to GHCR.

## Step 17: Final Release

After all assessment requirements have been completed and merged into main:

```bash
git checkout main
git pull origin main
```

Create the release tag:

```bash
git tag -a v1.0.0 -m "DevOps Intern Final Assessment v1.0.0"
```

Push the tag:

```bash
git push origin v1.0.0
```

Verify the tag:

```bash
git tag
```

The final release should show:

```text
v1.0.0
```

---

# Deployment Summary

At the end of this guide, another developer should be able to:

1. Clone the GitHub repository.
2. Run the Linux administration scripts.
3. Build and run the NGINX Docker image.
4. Pull the published image from GHCR.
5. Start Nomad and Consul.
6. Validate and deploy the Nomad job.
7. Start Loki, Promtail and Grafana.
8. Connect Grafana to Loki.
9. Generate application requests and investigate collected logs.
10. Follow the GitHub feature-branch, pull-request and release workflow.

**Note:** Commands that use local ports or allocation IDs must be adjusted to match the values assigned on the developer's machine. Successful log visualization also depends on Promtail correctly discovering and ingesting the application logs.
