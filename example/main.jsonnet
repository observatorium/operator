local obs = (import 'github.com/observatorium/observatorium/configuration/components/observatorium.libsonnet');

local dex = (import 'github.com/observatorium/observatorium/configuration/components/dex.libsonnet')({
  local cfg = self,
  name: 'dex',
  namespace: 'dex',
  config+: {
    oauth2: {
      passwordConnector: 'local',
    },
    staticClients: [
      {
        id: 'test',
        name: 'test',
        secret: 'ZXhhbXBsZS1hcHAtc2VjcmV0',
        issuerCAPath: '/var/run/tls/test/service-ca.crt',
      },
    ],
    enablePasswordDB: true,
    staticPasswords: [
      {
        email: 'admin@example.com',
        // bcrypt hash of the string "password"
        hash: '$2a$10$2b2cU8CPhOTaGrs1HRQuAueS7JTT5ZHsHSzYiFPm1leZck7Mc8T4W',
        username: 'admin',
        userID: '08a8684b-db88-4b73-90a9-3cd1661f5466',
      },
    ],
  },
  version: 'v2.24.0',
  image: 'quay.io/dexidp/dex:v2.24.0',
  commonLabels+:: {
    'app.kubernetes.io/instance': 'e2e-test',
  },
});

{
  local cr = self,
  name:: 'observatorium-cr',
  apiVersion: 'core.observatorium.io/v1alpha1',
  kind: 'Observatorium',
  metadata: {
    name: obs.config.name,
    labels: obs.config.commonLabels {
      'app.kubernetes.io/name': cr.name,
    },
  },
  spec: {
    objectStorageConfig: {
      thanos: obs.thanos.config.objectStorageConfig,
      loki: obs.loki.config.objectStorageConfig,
    },
    hashrings: obs.thanos.config.hashrings,

    queryFrontend: {
      image: obs.thanos.config.image,
      version: obs.thanos.config.version,
      replicas: obs.thanos.queryFrontend.config.replicas,
    },
    store: {
      image: obs.thanos.config.image,
      version: obs.thanos.config.version,
      shards: obs.thanos.stores.config.shards,
      cache: {
        image: obs.thanos.storeCache.config.image,
        version: obs.thanos.storeCache.config.version,
        exporterImage: obs.thanos.storeCache.config.exporterImage,
        exporterVersion: obs.thanos.storeCache.config.exporterVersion,
        replicas: obs.thanos.storeCache.config.replicas,
        memoryLimitMb: obs.thanos.storeCache.config.memoryLimitMb,
      },
      volumeClaimTemplate: obs.thanos.stores.config.volumeClaimTemplate,
    },
    compact: {
      image: obs.thanos.config.image,
      version: obs.thanos.config.version,
      volumeClaimTemplate: obs.thanos.compact.config.volumeClaimTemplate,
      retentionResolutionRaw: obs.thanos.compact.config.retentionResolutionRaw,
      retentionResolution5m: obs.thanos.compact.config.retentionResolution5m,
      retentionResolution1h: obs.thanos.compact.config.retentionResolution1h,
      enableDownsampling: !obs.thanos.compact.config.disableDownsampling,
      replicas: obs.thanos.compact.config.replicas,
    },
    rule: {
      image: obs.thanos.config.image,
      version: obs.thanos.config.version,
      volumeClaimTemplate: obs.thanos.rule.config.volumeClaimTemplate,
      replicas: obs.thanos.rule.config.replicas,
    },
    receivers: {
      image: obs.thanos.config.image,
      version: obs.thanos.config.version,
      volumeClaimTemplate: obs.thanos.receivers.config.volumeClaimTemplate,
      replicas: obs.thanos.receivers.config.replicas,
    },
    thanosReceiveController: {
      image: obs.thanos.receiveController.config.image,
      version: obs.thanos.receiveController.config.version,
    },
    api: {
      image: obs.api.config.image,
      replicas: obs.api.config.replicas,
      version: obs.api.config.version,
      rbac: {
        roles: [{
          name: 'read-write',
          resources: [
            'logs',
            'metrics',
          ],
          tenants: [
            'test',
          ],
          permissions: [
            'read',
            'write',
          ],
        }],
        roleBindings: [{
          name: 'test',
          roles: [
            'read-write',
          ],
          subjects: [
            {
              name: dex.config.config.staticPasswords[0].email,
              kind: 'user',
            },
          ],
        }],
      },
      tenants: [{
        name: dex.config.config.staticClients[0].name,
        id: '1610b0c3-c509-4592-a256-a1871353dbfa',
        oidc: {
          clientID: dex.config.config.staticClients[0].id,
          clientSecret: dex.config.config.staticClients[0].secret,
          issuerURL: 'https://%s.%s.svc.cluster.local:%d/dex' % [
            dex.service.metadata.name,
            dex.service.metadata.namespace,
            dex.service.spec.ports[0].port,
          ],
          issuerCAPath: dex.config.config.staticClients[0].issuerCAPath,
          usernameClaim: 'email',
          configMapName: '%s-ca-tls' % [dex.config.config.staticClients[0].id],
          caKey: 'service-ca.crt',
        },
      }],
      tls: {
        secretName: obs.config.name + '-tls',
        certKey: 'cert.pem',
        keyKey: 'key.pem',
        configMapName: obs.config.name + '-tls',
        caKey: 'ca.pem',
      },
    },
    // TODO(kakkoyun): This should be removed.
    apiQuery: {
      image: obs.thanos.config.image,
      version: obs.thanos.config.version,
    },
    query: {
      image: obs.thanos.config.image,
      version: obs.thanos.config.version,
      replicas: obs.thanos.query.config.replicas,
    },
    loki: {
      image: obs.loki.config.image,
      replicas: obs.loki.config.replicas,
      version: obs.loki.config.version,
      volumeClaimTemplate: obs.loki.config.volumeClaimTemplate,
    },
    securityContext: {
      fsGroup: 65534,
      runAsUser: 65534,
    },
  },
}
