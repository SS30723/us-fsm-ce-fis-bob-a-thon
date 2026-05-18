# OpenShift Basics with a Custom MCP Server

In this lab we will explore interaction with Red Hat OpenShift container platform using a custom MCP server.

## Features

- **Cluster Management** - Get cluster info, list projects/namespaces
- **Pod Operations** - List pods, view logs, describe pods, execute commands
- **Deployment Management** - Deploy apps, scale deployments, rollout status, rollback
- **Route Management** - Create TLS routes, list routes for external access
- **Build Operations** - Trigger builds (S2I), view build logs, list builds
- **Monitoring** - Node metrics, pod metrics, resource quotas, events

## Prerequisites

- OpenShift CLI (`oc`) installed
- Access to an OpenShift cluster
- Python 3.8+ and UV

---

## Custom OpenShift MCP Server Configuration

Lets start by getting our OpenShift MCP server up and running:

1. Lets create the python environment

    ```bash
    cd labs/handoff-labs/openshift-with-bob/basics-with-ocp-mcp/openshift-mcp
    ```

1. Using `uv`, create and activate a virtual environment (run these command individually):

    ```bash
    # Create virtual environment
    uv venv

    # Activate it (macOS/Linux)
    source .venv/bin/activate

    # Activate it (Windows)
    .venv\Scripts\activate
    ```

1. Install the project dependencies

    ```bash
    uv pip install -r requirements.txt
    ```

1. Login to your OpenShift cluster.

    ```bash
    oc login https://api.your-cluster.com:6443 --token=YOUR_TOKEN
    ```

1. Open Bob Settings (click the gear icon in the Bob panel) and navigate to the MCP Servers section

1. Click "Open", next to the `Project MCPs` section and add our custom MCP server. You can use one of the following two options.

    > **Note:** Be sure to update the OPENSHIFT_API_URL with your OpenShift API URL.

    Option 1: Using existing `oc login` session (Recommended):

    ```json
    {
      "mcpServers": {
          "openshift": {
              "command": "uv",
              "args": [
                  "run",
                  "python",
                  "openshift_mcp_server.py"
              ],
              "env": {
                  "OPENSHIFT_API_URL": "OCP_URL:6443"
              },
              "cwd": "${workspaceFolder}/labs/handoff-labs/openshift-with-bob/basics-with-ocp-mcp/openshift-mcp"
          }
      }
    }
    ```

    Option 2: Using token authentication:

    ```json
    {
      "mcpServers": {
          "openshift": {
              "command": "uv",
              "args": [
                  "run",
                  "python",
                  "openshift_mcp_server.py"
              ],
              "env": {
                  "OPENSHIFT_API_URL": "OCP_URL:6443",
                  "OPENSHIFT_TOKEN": "your-token-here"
              },
              "cwd": "${workspaceFolder}/labs/handoff-labs/openshift-with-bob/basics-with-ocp-mcp/openshift-mcp"
          }
      }
    }
    ```

1. **Verify Server Status**

    - Check that the MCP server shows a green indicator light
    - Click on the `openshift` server in Bob's MCP servers list and click the **Restart server** icon.

   > **Note:** If you see import errors for `fastmcp` or `starlette` in your editor, this is normal. The server uses the virtual environment where these packages are installed, so as long as the MCP server indicator light is green, everything is working correctly.

1. Now lets try to use our MCP server through Bob. Switch Bob to `Advanced` mode and ask any of the following questions:

    ```text
    List all the projects in my openshift cluser
    ```

## OpenShift Interactions

Now that our MCP server is up and running, let's try to use it to interact with OpenShift.

1. Lets start by deploying a sample application. Switch Bob to `Advanced` mode and prompt Bob with the following:

    ```text
    Deploy the openshift/hello-openshift application to my cluster
    ```

1. Depending on your access rights in the cluster, or if you have multiple projects in your cluster, Bob may ask you some follow up questions.

1. In order to access our sample application, we have to expose it using a route. Lets ask Bob to do this for us:

    ```text
    Create a TLS route for my `hello-openshift` application
    ```

1. Bob will create the route and return the access URL. (feel free to open it in a browser to confirm the application is deployed).

1. Finally, we can use Bob and our MCP server to monitor our application. Lets get the logs, events, and any quotas... Bob will provide insights into how these are impacting our application.

    ```text
    Get the logs for my `hello-openshift` application
    ```

    ```text
    Get the logs and the events for my `hello-openshift` application. Are there any issues with my application that I should be concerned about ?
    ```

    ```text
    Do I have any resource quotas in the project where my application is deployed ?
    ```

---

## Summary

In this simple lab, you have seen how Bob can be used to guide you through the process of deploying an application, exposing it, and monitoring it. These tools can be used to automate the process of deploying and managing applications in OpenShift. We can also use the MCP tools to monitor the application and get insights into its performance and resource usage.

### Cleanup

When you're done with this lab and want to clean up:

1. Remove MCP Server Configuration

    - Open `.bob/mcp.json` and remove the `openshift` server entry:

1. [Optionally] Remove the virtual environment if you want to free up disk space:

    ```bash
    # From the lab directory
    rm -rf .venv
    ```

### Reference - Custom OpenShift MCP Tools

We are using a custom built MCP server to interact with OpenShift. This is custom built using the MCP python package and exposes the following tools:

- Cluster Operations
  - `get_cluster_info` - Get cluster information and version
  - `list_projects` - List all projects/namespaces
  - `get_project_status` - Get comprehensive project status
- Pod Management
  - `list_pods` - List pods in a project
  - `get_pod_logs` - Get pod logs (current or previous)
  - `describe_pod` - Get detailed pod information
  - `get_pod_metrics` - Get pod resource usage
- Deployment Operations
  - `deploy_application` - Deploy a containerized application
  - `scale_deployment` - Scale deployment replicas
  - `get_deployment_status` - Get deployment status
  - `rollout_status` - Check rollout status
  - `rollback_deployment` - Rollback to previous version
- Route Management
  - `create_route` - Create external route with TLS
  - `get_routes` - List all routes in a project
- Build Operations
  - `trigger_build` - Trigger a build (Source-to-Image)
  - `get_build_logs` - Get build logs
  - `list_builds` - List all builds
- Monitoring
  - `get_node_info` - Get cluster node information
  - `get_node_metrics` - Get node resource usage
  - `get_resource_quota` - Get project resource quotas
  - `get_events` - Get recent events for troubleshooting
