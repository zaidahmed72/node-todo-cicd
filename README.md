# Jenkins CI/CD Pipeline

This project upgrades the Node.js demo in [`node-todo-cicd`](https://github.com/zaidahmed72/node-todo-cicd) with a Jenkins pipeline that checks out its own source, installs locked dependencies, runs the existing test suite, builds a SHA-tagged Docker image and smoke-checks the running app. GitHub push events trigger the pipeline. Image publishing and production deployment are opt-in, protected branch stages.

## Jenkins setup

Use Jenkins LTS with Pipeline, Git, GitHub, Credentials Binding and Workspace Cleanup plugins. The agent needs Node.js 20+, Docker Engine/Compose, `curl` and `awk`. Keep the Jenkins controller private and protect production agents.

1. Create a Pipeline job sourced from the repository, or a Multibranch Pipeline that scans `master`.
2. Enable **GitHub hook trigger for GITScm polling** for a single Pipeline job, or configure branch source webhooks for a Multibranch job.
3. Add a GitHub webhook to the trusted Jenkins endpoint using the push event. Use HTTPS and a strong webhook secret.
4. To publish images, add a Jenkins username/password credential named `registry-credentials`. Set `IMAGE_REPOSITORY` (for example `ghcr.io/zaidahmed72/node-todo-cicd`) and enable `PUBLISH_IMAGE` on the default branch.
5. To deploy, add a protected `production` agent and define `DEPLOY_COMMAND` as a secured folder/job environment value. Enable both publish and deploy parameters. The command receives the immutable image reference as `IMAGE`.

Pull requests run validation and a container smoke check but do not receive registry credentials or deployment access. Never store secrets in the repository or print them in build logs.

## Local container

```sh
docker compose up --build
```

Open `http://localhost:8000/todo`. Stop with `docker compose down`.
