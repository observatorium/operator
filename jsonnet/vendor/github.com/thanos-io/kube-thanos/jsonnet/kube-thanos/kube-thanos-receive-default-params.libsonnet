// These are the defaults for this components configuration.
// When calling the function to generate the component's manifest,
// you can pass an object structured like the default to overwrite default values.
{
  local defaults = self,
  name: 'thanos-receive',
  namespace: error 'must provide namespace',
  version: error 'must provide version',
  image: error 'must provide image',
  replicas: error 'must provide replicas',
  replicationFactor: error 'must provide replication factor',
  objectStorageConfig: error 'must provide objectStorageConfig',
  podDisruptionBudgetMaxUnavailable: (std.floor(defaults.replicationFactor / 2)),
  hashringConfigMapName: '',
  volumeClaimTemplate: {},
  retention: '15d',
  logLevel: 'info',
  resources: {},
  serviceMonitor: false,
  ports: {
    grpc: 10901,
    http: 10902,
    'remote-write': 19291,
  },
  tracing: {},

  commonLabels:: {
    'app.kubernetes.io/name': 'thanos-receive',
    'app.kubernetes.io/instance': defaults.name,
    'app.kubernetes.io/version': defaults.version,
    'app.kubernetes.io/component': 'database-write-hashring',
  },

  podLabelSelector:: {
    [labelName]: defaults.commonLabels[labelName]
    for labelName in std.objectFields(defaults.commonLabels)
    if !std.setMember(labelName, ['app.kubernetes.io/version'])
  },
}
