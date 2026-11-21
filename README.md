CI

Complete Deployment Guide - Follow Along

This guide explains how another developer can clone this repository and reproduce the deployment on their own computer.

The instructions use Windows 11, Ubuntu WSL2 and Docker Desktop. Linux users can run the Linux commands directly in their terminal.

Release: v1.0.0

Quick Start
bash
git clone https://github.com/MarvDev-Arch/-devops-intern-final.git devops-intern-final
cd devops-intern-final
docker build -t devops-intern-app ./app
docker run -d --name web -p 8080:8080 devops-intern-app
curl -i http://localhost:8080/
curl -i http://localhost:8080/healthz
curl -i http://localhost:8080/does-not-exist

Expected results:

Path	Expected status
/	200 OK
/healthz	200 OK with body healthy
/does-not-exist	404 Not Found (correct behavior for an unknown path)

Clean up when finished:

bash
docker rm -f web

The full walkthrough with Nomad, Consul and the monitoring stack starts at Step 1.

Evidence

Screenshots are stored in the repository under docs/screenshots/, so the results can be reviewed without a running server.

Local container test (200 / 200 / 404, healthy)

Local Docker test

CI pipeline (GitHub Actions, green run)

GitHub Actions green run

Nomad deployment (healthy allocation)

Nomad allocation in the web UI

Nomad job status in the terminal

Logs in Grafana Explore (Loki query results)

Grafana Explore showing Loki query results

Step 1: Install the Prerequisites

Install the following tools:

Tool	Purpose
Git	Clone and manage the repository
Visual Studio Code	Open and edit project files
Ubuntu WSL2	Run Linux commands
Docker Desktop	Build and run containers
HashiCorp Nomad	Deploy and manage the application
HashiCorp Consul	Service registration and discovery

Useful official installation resources:

Git: https://git-scm.com/downloads
Visual Studio Code: https://code.visualstudio.com/
Docker Desktop: https://www.docker.com/products/docker-desktop/
Ubuntu WSL: https://learn.microsoft.com/en-us/windows/wsl/install
Nomad: https://developer.hashicorp.com/nomad/install
Consul: https://developer.hashicorp.com/consul/install

After installing Docker Desktop, enable Ubuntu under Settings -> Resources -> WSL Integration.

Open Ubuntu and verify:

bash
git --version
docker --version

Check that Docker is working:

bash
docker ps

If Docker is unavailable, confirm Docker Desktop is running and Ubuntu WSL integration is enabled.

Step 2: Clone the GitHub Repository

Open Ubuntu and run:

bash
git clone https://github.com/MarvDev-Arch/-devops-intern-final.git devops-intern-final

The repository name starts with a hyphen, so the command above clones it into a folder named devops-intern-final.

Enter the project directory:

bash
cd devops-intern-final

Open the project in Visual Studio Code:

bash
code .

You should see the project folders:

text
app/
scripts/
.github/
nomad/
monitoring/
docs/
README.md
Step 3: Run the Linux Scripts

Make the scripts executable:

bash
chmod +x scripts/*.sh

Run the system information script:

bash
./scripts/sysinfo.sh

This displays information about the Linux system, current user, disk, memory and Docker availability.

Run the application health-check script (the application from Step 5 must be running first):

bash
./scripts/healthcheck.sh http://localhost:8080/healthz

The health-check command succeeds when an application is responding at the supplied URL.

Step 4: Build the Docker Image

From the project root, build the application image:

bash
docker build --build-arg BUILD_SHA=local-build -t devops-intern-final:v1 ./app

Check that the image was created:

bash
docker images devops-intern-final

Verify the container runs as a non-root user:

bash
docker run --rm devops-intern-final:v1 whoami

Expected output:

text
appuser
Step 5: Run the Application with Docker

NGINX listens on port 8080 inside the container (it runs as a non-root user), so always map the host port to container port 8080.

Start the container:

bash
docker run -d --name devops-app -p 8080:8080 devops-intern-final:v1

Check the container. After about 30 seconds the status should be (healthy):

bash
docker ps

Test the application:

bash
curl http://localhost:8080/

Test the health endpoint:

bash
curl http://localhost:8080/healthz

Expected health response:

text
healthy

Test an unknown path. A 404 here is the correct behavior:

bash
curl -i http://localhost:8080/does-not-exist

Open the application in your browser:

text
http://localhost:8080

The NGINX application should display its homepage.

If port 8080 is already in use, use another host port:

bash
docker run -d --name devops-app -p 8081:8080 devops-intern-final:v1

Then access:

text
http://localhost:8081
Step 6: Pull the Published Image from GHCR

Instead of building the image locally, you can pull the image published by GitHub Actions.

bash
docker pull ghcr.io/marvdev-arch/devops-intern-final:latest

Run the published image:

bash
docker run -d --name ghcr-app -p 8082:8080 ghcr.io/marvdev-arch/devops-intern-final:latest

Test it:

bash
curl http://localhost:8082/healthz

Expected response:

text
healthy

If the package is private, authenticate to GHCR using a GitHub token with the required package read permission before pulling.

Step 7: Start Nomad

Nomad is used to schedule and manage the containerized application.

Install Nomad using the official installation instructions.

Run Nomad inside Ubuntu WSL2. The Nomad Docker driver does not work on native Windows when Docker Desktop is using Linux containers.

Open a new Ubuntu terminal and start the development agent:

bash
sudo nomad agent -dev -bind 0.0.0.0

Keep this terminal open and do not type in it. In the log, confirm the Docker driver is reported as healthy.

Open another Ubuntu terminal and go to the project:

bash
cd /mnt/c/Users/Dell/Desktop/devops-intern-final
export NOMAD_ADDR=http://127.0.0.1:4646

If you cloned the repository somewhere else, use that location instead.

Verify the Nomad agent:

bash
nomad node status

The node should show a ready status. The Nomad web UI is available at http://localhost:4646.

Step 8: Start Consul

Consul provides service registration and discovery for the Nomad application. The Nomad job has a Consul version constraint, so without Consul the allocation is not placed.

In another Ubuntu terminal, start Consul:

bash
consul agent -dev

Keep this terminal open.

Check the Consul cluster:

bash
consul members

The local Consul agent should appear as alive. Nomad re-checks for Consul about every 15 seconds, so wait about 30 seconds before deploying.

Important: These development-mode commands are for local assessment and testing. Do not use development mode for production deployments.

Step 9: Validate the Nomad Job

Return to the project terminal:

bash
cd /mnt/c/Users/Dell/Desktop/devops-intern-final
export NOMAD_ADDR=http://127.0.0.1:4646

Validate the job file:

bash
nomad job validate nomad/nginx-app.nomad.hcl

Preview the deployment:

bash
nomad job plan nomad/nginx-app.nomad.hcl

If the job is valid and the required services are available, proceed with deployment.

Step 10: Deploy the Application with Nomad

The job pulls ghcr.io/marvdev-arch/devops-intern-final:<image_tag>. The default tag is latest, and Nomad always pulls a latest image from the registry.

Option A - use the published image (the GHCR package must be public or you must be authenticated):

bash
nomad job run nomad/nginx-app.nomad.hcl

Option B - use your locally built image. Tag it with a non-latest tag and pass the tag to the job:

bash
docker tag devops-intern-app ghcr.io/marvdev-arch/devops-intern-final:local
nomad job run -var="image_tag=local" nomad/nginx-app.nomad.hcl

Check its status (wait about 25 seconds first):

bash
nomad job status nginx-app

A successful deployment shows the allocation as running and the deployment as successful with Healthy 1 and Unhealthy 0.

Check the allocation:

bash
nomad job allocs nginx-app

Copy the allocation ID shown in the output, then inspect it:

bash
nomad alloc status <ALLOCATION_ID>

Replace <ALLOCATION_ID> with the actual allocation ID.

Look for the host port mapped to container port 8080.

For example, if Nomad assigns port 20791, test:

bash
curl http://localhost:20791/

Check the health endpoint:

bash
curl http://localhost:20791/healthz

The expected health response is:

text
healthy

Important: Nomad dynamically allocates the host port. Do not assume it will always be 20791. Always check the allocation details.

Step 11: Start the Monitoring Stack

The monitoring stack contains Loki, Promtail and Grafana.

If a standalone container named grafana already exists, remove it first so the names do not clash:

bash
docker rm -f grafana

From the project root, run:

bash
docker compose -f monitoring/docker-compose.yaml up -d

Check the running containers:

bash
docker ps

You should see the monitoring services:

text
loki
promtail
grafana

Check Loki:

bash
curl http://localhost:3100/ready

Check Promtail logs:

bash
docker logs promtail --tail 30

Check Grafana:

text
http://localhost:3000

The default local Grafana login is:

text
Username: admin
Password: admin

Change the default password when prompted or before using Grafana beyond local testing.

Start the application container after Promtail is running so its logs are picked up.

Step 12: Connect Grafana to Loki
Open Grafana at http://localhost:3000.
Navigate to Connections.
Open Data Sources.
Select Add data source.
Choose Loki.
Enter the Loki URL:
text
http://loki:3100
Select Save & Test.

A successful connection confirms that Grafana can reach Loki through the Docker Compose network.

Step 13: Generate Application Logs

For the standalone Docker container from Step 5, generate GET requests:

bash
for i in $(seq 1 15); do curl -s -o /dev/null http://localhost:8080/; curl -s -o /dev/null http://localhost:8080/does-not-exist; done
docker logs devops-app --tail 5

The log should show GET / ... 200 and GET /does-not-exist ... 404 lines. The /healthz endpoint is intentionally excluded from the access log.

For the Nomad application, find the host port assigned to it:

bash
nomad job allocs nginx-app
nomad alloc status <ALLOCATION_ID>

Then generate requests:

bash
curl http://localhost:20791/
curl http://localhost:20791/healthz
curl http://localhost:20791/page-not-found

Replace 20791 with the actual allocated port.

Step 14: Query Logs in Grafana Explore

Open Grafana:

text
http://localhost:3000

Navigate to Explore, select Loki as the data source, set the time range to Last 15 minutes, and inspect the labels available in the label browser.

For the standalone container named web, the labels are container_name=web, job=nginx and service_name=/web:

logql
{service_name="/web"}

To show only access-log lines:

logql
{service_name="/web"} |= "GET"

To inspect logs by job label:

logql
{job="nginx"}

To filter access logs for non-200 responses, use the query below if the NGINX access-log format matches the pattern:

logql
{job="nginx"} | pattern `<remote> - <user> [<time>] "<method> <path> <protocol>" <status> <size> <referer> "<agent>"` | status != "200"

If no logs appear, check the Promtail configuration, Docker log access, available labels and Promtail logs before assuming ingestion is working.

The screenshot of a successful Explore query is stored in docs/screenshots/grafana-loki.png.

Step 15: Stop the Services

Stop the monitoring stack:

bash
docker compose -f monitoring/docker-compose.yaml down

Stop and remove the Nomad job:

bash
nomad job stop -purge nginx-app

Stop any standalone Docker containers you started:

bash
docker rm -f web devops-app ghcr-app

Stop the Nomad and Consul development agents using Ctrl + C in their respective terminals.

Step 16: Verify the GitHub Actions Pipeline

After making changes to the project:

bash
git status

Create a feature branch:

bash
git checkout -b feature/my-update

Stage and commit your changes:

bash
git add .
git commit -m "feat: update deployment configuration"

Push the branch:

bash
git push -u origin feature/my-update

Open the repository on GitHub and create a pull request targeting main.

GitHub Actions should automatically run the configured checks: ShellCheck and Hadolint, Build Docker Image, Test Docker Application, and Publish Image to GHCR.

After the pull request is reviewed and merged, the main-branch workflow publishes the Docker image to GHCR.

Step 17: Final Release

After all assessment requirements have been completed and merged into main:

bash
git checkout main
git pull origin main

Create the release tag:

bash
git tag -a v1.0.0 -m "DevOps Intern Final Assessment v1.0.0"

Push the tag:

bash
git push origin v1.0.0

Verify the tag:

bash
git tag

The final release should show:

text
v1.0.0
Troubleshooting
Problem	Cause and fix
curl: (52) Empty reply from server on port 8080	NGINX listens on 8080 inside the container. Map the port with -p 8080:8080, not -p 8080:80.
docker ps shows (health: starting)	Wait about 30 seconds and run docker ps again until it shows (healthy).
Container name already in use	Remove the old container with docker rm -f <name> and run it again.
fatal: repository not found or a wrong folder name when cloning	The repository name starts with a hyphen. Use the full URL https://github.com/MarvDev-Arch/-devops-intern-final.git and clone into a named folder as shown in Step 2.
Nomad Docker driver is unhealthy ("Docker is configured with Linux containers; switch to Windows Containers")	Native Windows Nomad cannot run Linux containers. Run Nomad inside Ubuntu WSL2 with Docker Desktop WSL integration enabled.
sudo: Sudo is disabled on this machine	The command was run in PowerShell. Run wsl first and use the Ubuntu prompt for Linux commands.
Nomad API connection refused on port 4646	The agent is not running or was stopped. Start nomad agent -dev in its own terminal and leave it running.
Nomad job shows 0 placed and a Consul constraint message	The job needs a Consul agent. Start consul agent -dev, wait about 30 seconds, then run nomad job status nginx-app.
Nomad cannot pull the image from GHCR	A latest tag always pulls from the registry, and a private package needs authentication. Tag a local image and run the job with -var="image_tag=local" (Step 10, Option B).
docker compose up fails because the name grafana is in use	Run docker rm -f grafana and start the stack again.
Grafana Explore shows only the NGINX startup lines	Generate GET requests with curl, set the time range to Last 15 minutes, and rerun the query. Make sure the container was started after Promtail.
Grafana cannot connect to Loki	Use http://loki:3100 as the data source URL, not localhost.
Push rejected ("fetch first")	Run git pull --rebase, then push again.
Known Limitations
Nomad and Consul run as single-node development agents with no TLS and no ACLs. They are for local assessment only.
Grafana, Loki and Promtail run locally with default credentials, no persistence and no authentication hardening.
The Nomad host port is allocated dynamically, so commands that use a port must be adjusted to the value shown in the allocation.
The Nomad job requires a local Consul agent and pulls its image from GHCR, so a private package or a missing Consul agent prevents placement.
The Nomad Docker driver does not work on native Windows with Linux containers, so Nomad must run inside WSL2 or on Linux.
Log ingestion depends on Promtail discovering the application container, so the application must be started after the monitoring stack.
No server is left running after the review. The evidence for the CI run, the Nomad deployment and the Grafana query is the set of screenshots in docs/screenshots/.
Deployment Summary

At the end of this guide, another developer should be able to:

Clone the GitHub repository.
Run the Linux administration scripts.
Build and run the NGINX Docker image.
Pull the published image from GHCR.
Start Nomad and Consul.
Validate and deploy the Nomad job.
Start Loki, Promtail and Grafana.
Connect Grafana to Loki.
Generate application requests and investigate collected logs.
Follow the GitHub feature-branch, pull-request and release workflow.

Note: Commands that use local ports or allocation IDs must be adjusted to match the values assigned on the developer's machine. Successful log visualization also depends on Promtail correctly discovering and ingesting the application logs.
