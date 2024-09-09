<b>Simple web service application</b>
The repo uses devcontainers, primarily for ease of access for the Azure CLI.  Devcontainers is not necessary, but in order to use the AZD you will need all the dependencies installed locally (i.e. node.js > 6.0)

<b>Deployment</b>

The Azure Web Service is deployed from the Infra folder
The easiest way to deploy the app service is through the Azure Developer CLI --> 
    1. sign in <azd auth login>
    2. set up an environment <azd env new> or choose from an existing env <azd env list>
      a. create a .env file in the new formed .azure folder.  This will hold all the environment variables you wish to set
    3. <azd provision> provisions the resource using the bicep files

