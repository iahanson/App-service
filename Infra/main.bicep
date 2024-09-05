targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

param appServicePlanName string = '' // Set in main.parameters.json
param appServicePlanId string = '' // Set in main.parameters.json ****************new-to test
param backendServiceName string = '' // Set in main.parameters.json
param resourceGroupName string = '' // Set in main.parameters.json

// param applicationInsightsDashboardName string = '' // Set in main.parameters.json
// param applicationInsightsName string = '' // Set in main.parameters.json
// param logAnalyticsName string = '' // Set in main.parameters.json

param searchServiceName string = '' // Set in main.parameters.json
param searchServiceResourceGroupName string = '' // Set in main.parameters.json
// param searchServiceLocation string = '' // Set in main.parameters.json
// The free tier does not support managed identity (required) or semantic search (optional)
@allowed([ 'free', 'basic', 'standard', 'standard2', 'standard3', 'storage_optimized_l1', 'storage_optimized_l2' ])
param searchServiceSkuName string // Set in main.parameters.json
param searchIndexName string // Set in main.parameters.json
param searchQueryLanguage string // Set in main.parameters.json
param searchQuerySpeller string // Set in main.parameters.json
param searchServiceSemanticRankerLevel string // Set in main.parameters.json
var actualSearchServiceSemanticRankerLevel = (searchServiceSkuName == 'free') ? 'disabled' : searchServiceSemanticRankerLevel

param storageAccountName string = '' // Set in main.parameters.json
param storageResourceGroupName string = '' // Set in main.parameters.json
// param storageResourceGroupLocation string = location
param storageContainerName string = 'content'
// param storageSkuName string // Set in main.parameters.json

// param userStorageAccountName string = ''
param userStorageContainerName string = 'user-content'
param documentIntelligence string = 'doc-intel-vs' // Set in main.parameters.json **************************************** added
//param userStorage string // Set in main.parameters.json************************* added

param appServiceSkuName string // Set in main.parameters.json

@allowed([ 'azure', 'openai', 'azure_custom' ])
param openAiHost string // Set in main.parameters.json
param isAzureOpenAiHost bool = startsWith(openAiHost, 'azure')
param deployAzureOpenAi bool = openAiHost == 'azure'
param azureOpenAiCustomUrl string = ''
param azureOpenAiApiVersion string = ''
@secure()
param azureOpenAiApiKey string = ''
param openAiServiceName string = ''
param openAiResourceGroupName string = ''

// param speechServiceResourceGroupName string = ''
// param speechServiceLocation string = ''
// param speechServiceName string = ''
// param speechServiceSkuName string // Set in main.parameters.json
param useGPT4V bool = false

@description('Location for the OpenAI resource group')
@allowed([ 'canadaeast', 'eastus', 'eastus2', 'francecentral', 'switzerlandnorth', 'uksouth', 'japaneast', 'northcentralus', 'australiaeast', 'swedencentral' ])
@metadata({
  azd: {
    type: 'location'
  }
})

@secure()
param openAiApiKey string //= ''
param openAiApiOrganization string = ''

param documentIntelligenceServiceName string = '' // Set in main.parameters.json
param documentIntelligenceResourceGroupName string = '' // Set in main.parameters.json

// Limited regions for new version:
// https://learn.microsoft.com/azure/ai-services/document-intelligence/concept-layout
@description('Location for the Document Intelligence resource group')
@allowed([ 'eastus', 'westus2', 'westeurope','uksouth' ])
@metadata({
  azd: {
    type: 'location'
  }
})

param chatGptModelName string //=''
param chatGptDeploymentName string = ''
param chatGptDeploymentVersion string = ''
param chatGptDeploymentCapacity int = 0
var chatGpt = {
  modelName: !empty(chatGptModelName) ? chatGptModelName : startsWith(openAiHost, 'azure') ? 'gpt-35-turbo' : 'gpt-3.5-turbo'
  deploymentName: !empty(chatGptDeploymentName) ? chatGptDeploymentName : 'chat'
  deploymentVersion: !empty(chatGptDeploymentVersion) ? chatGptDeploymentVersion : '0613'
  deploymentCapacity: chatGptDeploymentCapacity != 0 ? chatGptDeploymentCapacity : 10
}

param embeddingModelName string = ''
param embeddingDeploymentName string = ''
param embeddingDeploymentVersion string = ''
param embeddingDeploymentCapacity int = 0
param embeddingDimensions int = 0
var embedding = {
  modelName: !empty(embeddingModelName) ? embeddingModelName : 'text-embedding-ada-002'
  deploymentName: !empty(embeddingDeploymentName) ? embeddingDeploymentName : 'embedding'
  deploymentVersion: !empty(embeddingDeploymentVersion) ? embeddingDeploymentVersion : '2'
  deploymentCapacity: embeddingDeploymentCapacity != 0 ? embeddingDeploymentCapacity : 30
  dimensions: embeddingDimensions != 0 ? embeddingDimensions : 1536
}

param gpt4vModelName string = 'gpt-4o'
param gpt4vDeploymentName string = 'gpt-4o'
// param gpt4vModelVersion string = '2024-05-13'
// param gpt4vDeploymentCapacity int = 10 

param tenantId string = tenant().tenantId
param authTenantId string = ''

// Used for the optional login and document level access control system
param useAuthentication bool = false
param enforceAccessControl bool = false
param enableGlobalDocuments bool = false
param enableUnauthenticatedAccess bool = false
param serverAppId string = ''
@secure()
param serverAppSecret string = ''
param clientAppId string = ''
@secure()
param clientAppSecret string = ''

// Used for optional CORS support for alternate frontends
param allowedOrigin string = '' // should start with https://, shouldn't end with a /


@description('Public network access value for all deployed resources')
@allowed([ 'Enabled', 'Disabled' ])
param publicNetworkAccess string = 'Enabled'


@description('Use speech recognition feature in browser')
param useSpeechInputBrowser bool = false
@description('Use speech synthesis in browser')
param useSpeechOutputBrowser bool = false
@description('Use Azure speech service for reading out text')
param useSpeechOutputAzure bool = false
@description('Show options to use vector embeddings for searching in the app UI')
param useVectors bool = false


@description('Enable user document upload feature')
param useUserUpload bool = false
param useLocalPdfParser bool = false
param useLocalHtmlParser bool = false

var abbrs = loadJsonContent('abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

var tenantIdForAuth = !empty(authTenantId) ? authTenantId : tenantId
var authenticationIssuerUri = '${environment().authentication.loginEndpoint}${tenantIdForAuth}/v2.0'

// Organize resources in a resource group
resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// // Create an App Service Plan to group applications under the same payment plan and SKU
// module appServicePlan 'core/host/appserviceplan.bicep' = {
//   name: 'appserviceplan'
//   scope: resourceGroup
//   params: {
//     name: !empty(appServicePlanName) ? appServicePlanName : '${abbrs.webServerFarms}${resourceToken}'
//     location: location
//     tags: tags
//     sku: {
//       name: appServiceSkuName
//       capacity: 1
//     }
//     kind: 'linux'
//   }
// }

// The application frontend
module backend 'core/host/appservice.bicep' = {
  name: 'web'
  scope: resourceGroup
  params: {
    name: !empty(backendServiceName) ? backendServiceName : '${abbrs.webSitesAppService}backend-${resourceToken}'
    location: location
    tags: union(tags, { 'azd-service-name': 'backend' })
    appServicePlanId: appServicePlanId //appServicePlan.outputs.id
    runtimeName: 'python'
    runtimeVersion: '3.11'
    appCommandLine: 'python3 -m gunicorn main:app'
    scmDoBuildDuringDeployment: true
    managedIdentity: true
    //virtualNetworkSubnetId: isolation.outputs.appSubnetId
    publicNetworkAccess: publicNetworkAccess
    allowedOrigins: [ allowedOrigin ]
    clientAppId: clientAppId
    serverAppId: serverAppId
    enableUnauthenticatedAccess: enableUnauthenticatedAccess
    clientSecretSettingName: !empty(clientAppSecret) ? 'AZURE_CLIENT_APP_SECRET' : ''
    authenticationIssuerUri: authenticationIssuerUri
    use32BitWorkerProcess: appServiceSkuName == 'F1'
    alwaysOn: appServiceSkuName != 'F1'
    appSettings: {
      AZURE_STORAGE_ACCOUNT: storageAccountName //storage.outputs.name
      AZURE_STORAGE_CONTAINER: storageContainerName
      AZURE_SEARCH_INDEX: searchIndexName
      AZURE_SEARCH_SERVICE: searchServiceName //searchService.outputs.name
      AZURE_SEARCH_SEMANTIC_RANKER: actualSearchServiceSemanticRankerLevel
      //AZURE_VISION_ENDPOINT: useGPT4V ? computerVision.outputs.endpoint : ''
      AZURE_SEARCH_QUERY_LANGUAGE: searchQueryLanguage
      AZURE_SEARCH_QUERY_SPELLER: searchQuerySpeller
      //APPLICATIONINSIGHTS_CONNECTION_STRING: useApplicationInsights ? monitoring.outputs.applicationInsightsConnectionString : ''
      //AZURE_SPEECH_SERVICE_ID: useSpeechOutputAzure ? speech.outputs.id : ''
      //AZURE_SPEECH_SERVICE_LOCATION: useSpeechOutputAzure ? speech.outputs.location : ''
      USE_SPEECH_INPUT_BROWSER: useSpeechInputBrowser
      USE_SPEECH_OUTPUT_BROWSER: useSpeechOutputBrowser
      USE_SPEECH_OUTPUT_AZURE: useSpeechOutputAzure
      // Shared by all OpenAI deployments
      OPENAI_HOST: openAiHost
      AZURE_OPENAI_EMB_MODEL_NAME: embedding.modelName
      AZURE_OPENAI_EMB_DIMENSIONS: embedding.dimensions
      AZURE_OPENAI_CHATGPT_MODEL: chatGpt.modelName
      AZURE_OPENAI_GPT4V_MODEL: gpt4vModelName
      // Specific to Azure OpenAI
      AZURE_OPENAI_SERVICE: isAzureOpenAiHost && deployAzureOpenAi ? openAiServiceName : '' //openAi.outputs.name
      AZURE_OPENAI_CHATGPT_DEPLOYMENT: chatGpt.deploymentName
      AZURE_OPENAI_EMB_DEPLOYMENT: embedding.deploymentName
      AZURE_OPENAI_GPT4V_DEPLOYMENT: useGPT4V ? gpt4vDeploymentName : ''
      AZURE_OPENAI_API_VERSION: azureOpenAiApiVersion
      AZURE_OPENAI_API_KEY: azureOpenAiApiKey
      AZURE_OPENAI_CUSTOM_URL: azureOpenAiCustomUrl
      // Used only with non-Azure OpenAI deployments
      OPENAI_API_KEY: openAiApiKey
      OPENAI_ORGANIZATION: openAiApiOrganization
      // Optional login and document level access control system
      AZURE_USE_AUTHENTICATION: useAuthentication
      AZURE_ENFORCE_ACCESS_CONTROL: enforceAccessControl
      AZURE_ENABLE_GLOBAL_DOCUMENTS_ACCESS: enableGlobalDocuments
      AZURE_ENABLE_UNAUTHENTICATED_ACCESS: enableUnauthenticatedAccess
      AZURE_SERVER_APP_ID: serverAppId
      AZURE_SERVER_APP_SECRET: serverAppSecret
      AZURE_CLIENT_APP_ID: clientAppId
      AZURE_CLIENT_APP_SECRET: clientAppSecret
      AZURE_TENANT_ID: tenantId
      AZURE_AUTH_TENANT_ID: tenantIdForAuth
      AZURE_AUTHENTICATION_ISSUER_URI: authenticationIssuerUri
      // CORS support, for frontends on other hosts
      ALLOWED_ORIGIN: allowedOrigin
      USE_VECTORS: useVectors
      USE_GPT4V: useGPT4V
      USE_USER_UPLOAD: useUserUpload
      //AZURE_USERSTORAGE_ACCOUNT: useUserUpload ? userStorage : ''  //userStorage.outputs.name
      //AZURE_USERSTORAGE_CONTAINER: useUserUpload ? userStorageContainerName : ''
      AZURE_DOCUMENTINTELLIGENCE_SERVICE: documentIntelligence //documentIntelligence.outputs.name
      USE_LOCAL_PDF_PARSER: useLocalPdfParser
      USE_LOCAL_HTML_PARSER: useLocalHtmlParser
    }
  }
}


output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenantId
output AZURE_AUTH_TENANT_ID string = authTenantId
output AZURE_RESOURCE_GROUP string = resourceGroup.name

// Shared by all OpenAI deployments
output OPENAI_HOST string = openAiHost
output AZURE_OPENAI_EMB_MODEL_NAME string = embedding.modelName
output AZURE_OPENAI_CHATGPT_MODEL string = chatGpt.modelName
output AZURE_OPENAI_GPT4V_MODEL string = gpt4vModelName

// Specific to Azure OpenAI
output AZURE_OPENAI_SERVICE string = isAzureOpenAiHost && deployAzureOpenAi ? openAiServiceName : ''  //openAi.outputs.name
output AZURE_OPENAI_API_VERSION string = isAzureOpenAiHost ? azureOpenAiApiVersion : ''
output AZURE_OPENAI_RESOURCE_GROUP string = isAzureOpenAiHost ? openAiResourceGroupName : ''  //openAiResourceGroup.name 
output AZURE_OPENAI_CHATGPT_DEPLOYMENT string = isAzureOpenAiHost ? chatGpt.deploymentName : ''
output AZURE_OPENAI_EMB_DEPLOYMENT string = isAzureOpenAiHost ? embedding.deploymentName : ''
output AZURE_OPENAI_GPT4V_DEPLOYMENT string = isAzureOpenAiHost ? gpt4vDeploymentName : ''

//output AZURE_SPEECH_SERVICE_ID string = useSpeechOutputAzure ? speech.outputs.id : ''
//output AZURE_SPEECH_SERVICE_LOCATION string = useSpeechOutputAzure ? speech.outputs.location : ''

//output AZURE_VISION_ENDPOINT string = useGPT4V ? computerVision.outputs.endpoint : ''

output AZURE_DOCUMENTINTELLIGENCE_SERVICE string = documentIntelligenceServiceName //documentIntelligence.outputs.name
output AZURE_DOCUMENTINTELLIGENCE_RESOURCE_GROUP string = documentIntelligenceResourceGroupName //documentIntelligenceResourceGroup.name

output AZURE_SEARCH_INDEX string = searchIndexName
output AZURE_SEARCH_SERVICE string = searchServiceName //searchService.outputs.name
output AZURE_SEARCH_SERVICE_RESOURCE_GROUP string = searchServiceResourceGroupName //searchServiceResourceGroup.name
output AZURE_SEARCH_SEMANTIC_RANKER string = actualSearchServiceSemanticRankerLevel
//output AZURE_SEARCH_SERVICE_ASSIGNED_USERID string = searchService.outputs.principalId

output AZURE_STORAGE_ACCOUNT string = storageAccountName //storage.outputs.name
output AZURE_STORAGE_CONTAINER string = storageContainerName
output AZURE_STORAGE_RESOURCE_GROUP string = storageResourceGroupName //storageResourceGroup.name

output AZURE_USERSTORAGE_ACCOUNT string = useUserUpload ? storageAccountName : '' //userStorage.outputs.name 
output AZURE_USERSTORAGE_CONTAINER string = userStorageContainerName
output AZURE_USERSTORAGE_RESOURCE_GROUP string = storageResourceGroupName //storageResourceGroup.name

output AZURE_USE_AUTHENTICATION bool = useAuthentication

output BACKEND_URI string = backend.outputs.uri
