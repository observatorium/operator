local cr = import 'generic-operator/config';
local thanos = (import 'github.com/observatorium/observatorium/configuration/components/thanos.libsonnet');
local loki = (import 'github.com/observatorium/observatorium/configuration/components/loki.libsonnet');
local api = (import 'github.com/observatorium/api/jsonnet/lib/observatorium-api.libsonnet');
local obs = (import 'github.com/observatorium/observatorium/configuration/components/observatorium.libsonnet');

local operatorObs = obs {

  thanos+:: thanos({
    name: cr.metadata.name,
    namespace: cr.metadata.namespace,
    image: if std.objectHas(cr.spec.thanos, 'image') then cr.spec.thanos.image else obs.thanos.config.image,
    version: if std.objectHas(cr.spec.thanos, 'version') then cr.spec.thanos.version else obs.thanos.config.version,
    objectStorageConfig: cr.spec.objectStorageConfig.thanos,
    hashrings: cr.spec.hashrings,
    compact+:: {
      logLevel: 'info',
      disableDownsampling: if std.objectHas(cr.spec.thanos, 'compact') && std.objectHas(cr.spec.thanos.compact, 'enableDownsampling') then !cr.spec.thanos.compact.enableDownsampling else obs.thanos.compact.config.disableDownsampling,
      securityContext: if std.objectHas(cr.spec, 'securityContext') then cr.spec.securityContext else obs.thanos.compact.config.securityContext,
    } + if std.objectHas(cr.spec.thanos, 'compact') then cr.spec.thanos.compact else {},

    receiveController+:: {
      hashrings: cr.spec.hashrings,
      securityContext: if std.objectHas(cr.spec, 'securityContext') then cr.spec.securityContext else obs.thanos.receiveController.config.securityContext,
    } + if std.objectHas(cr.spec.thanos, 'receiveController') then cr.spec.thanos.receiveController else {},

    receivers+:: {
      securityContext: if std.objectHas(cr.spec, 'securityContext') then cr.spec.securityContext else obs.thanos.receivers.config.securityContext,
    } + if std.objectHas(cr.spec.thanos, 'receivers') then cr.spec.thanos.receivers else {},

    rule+:: {
      securityContext: if std.objectHas(cr.spec, 'securityContext') then cr.spec.securityContext else obs.thanos.rule.config.securityContext,
      alertmanagersURLs: if std.objectHas(cr.spec.thanos, 'rule') && std.objectHas(cr.spec.thanos.rule, 'alertmanagerURLs') then cr.spec.thanos.rule.alertmanagerURLs else obs.thanos.rule.config.alertmanagersURLs,
    } + if std.objectHas(cr.spec.thanos, 'rule') then cr.spec.thanos.rule else {},

    stores+:: {
      securityContext: if std.objectHas(cr.spec, 'securityContext') then cr.spec.securityContext else obs.thanos.stores.config.securityContext,
    } + if std.objectHas(cr.spec.thanos, 'store') then cr.spec.thanos.store else {},

    storeCache+:: (if std.objectHas(cr.spec.thanos, 'store') && std.objectHas(cr.spec.thanos.store, 'cache') then cr.spec.thanos.store.cache else {}) + {
      memoryLimitMb: if std.objectHas(cr.spec.thanos.store, 'cache') && std.objectHas(cr.spec.thanos.store.cache, 'memoryLimitMb') then cr.spec.thanos.store.cache.memoryLimitMb else obs.thanos.storeCache.config.memoryLimitMb,
      securityContext: if std.objectHas(cr.spec, 'securityContext') then cr.spec.securityContext else obs.thanos.storeCache.config.securityContext,
      resources+: (
        if std.objectHas(cr.spec.thanos.store.cache, 'resources') then {
          memcached: cr.spec.thanos.store.cache.resources,
        } else {}
      ) + (
        if std.objectHas(cr.spec.thanos.store.cache, 'exporterResources') then {
          exporter: cr.spec.thanos.store.cache.exporterResources,
        } else {}
      ),
    },

    query+:: {
      securityContext: if std.objectHas(cr.spec, 'securityContext') then cr.spec.securityContext else obs.thanos.query.config.securityContext,
    } + if std.objectHas(cr.spec.thanos, 'query') then cr.spec.thanos.query else {},

    queryFrontend+:: {
      securityContext: if std.objectHas(cr.spec, 'securityContext') then cr.spec.securityContext else obs.thanos.queryFrontend.config.securityContext,
    } + if std.objectHas(cr.spec.thanos, 'queryFrontend') then cr.spec.thanos.queryFrontend else {},

    queryFrontendCache+:: {
      securityContext: if std.objectHas(cr.spec, 'securityContext') then cr.spec.securityContext else obs.thanos.queryFrontendCache.config.securityContext,
    },
  }),

  loki:: if std.objectHas(cr.spec, 'loki') then loki(obs.loki.config {
    local cfg = self,
    name: cr.metadata.name + '-' + cfg.commonLabels['app.kubernetes.io/name'],
    namespace: cr.metadata.namespace,
    image: if std.objectHas(cr.spec.loki, 'image') then cr.spec.loki.image else obs.loki.config.image,
    replicas: if std.objectHas(cr.spec.loki, 'replicas') then cr.spec.loki.replicas else obs.loki.config.replicas,
    version: if std.objectHas(cr.spec.loki, 'version') then cr.spec.loki.version else obs.loki.config.version,
    objectStorageConfig: if cr.spec.objectStorageConfig.loki != null then cr.spec.objectStorageConfig.loki else obs.loki.config.objectStorageConfig,
  }) else {},

  gubernator:: {},

  api:: api(obs.api.config + (
    if std.objectHas(cr.spec, 'api') then cr.spec.api else {}
  ) + {
    local cfg = self,
    name: cr.metadata.name + '-' + cfg.commonLabels['app.kubernetes.io/name'],
    namespace: cr.metadata.namespace,
    tenants: if std.objectHas(cr.spec, 'api') && std.objectHas(cr.spec.api, 'tenants') then { tenants: cr.spec.api.tenants } else obs.api.config.tenants,
    rateLimiter: {},
    metrics: {
      readEndpoint: 'http://%s.%s.svc.cluster.local:%d' % [
        operatorObs.thanos.queryFrontend.service.metadata.name,
        operatorObs.thanos.queryFrontend.service.metadata.namespace,
        operatorObs.thanos.queryFrontend.service.spec.ports[0].port,
      ],
      writeEndpoint: 'http://%s.%s.svc.cluster.local:%d' % [
        operatorObs.thanos.receiversService.metadata.name,
        operatorObs.thanos.receiversService.metadata.namespace,
        operatorObs.thanos.receiversService.spec.ports[2].port,
      ],
    },
    logs: if std.objectHas(cr.spec, 'loki') then {
      readEndpoint: 'http://%s.%s.svc.cluster.local:%d' % [
        operatorObs.loki.manifests['query-frontend-http-service'].metadata.name,
        operatorObs.loki.manifests['query-frontend-http-service'].metadata.namespace,
        operatorObs.loki.manifests['query-frontend-http-service'].spec.ports[0].port,
      ],
      tailEndpoint: 'http://%s.%s.svc.cluster.local:%d' % [
        operatorObs.loki.manifests['querier-http-service'].metadata.name,
        operatorObs.loki.manifests['querier-http-service'].metadata.namespace,
        operatorObs.loki.manifests['querier-http-service'].spec.ports[0].port,
      ],
      writeEndpoint: 'http://%s.%s.svc.cluster.local:%d' % [
        operatorObs.loki.manifests['distributor-http-service'].metadata.name,
        operatorObs.loki.manifests['distributor-http-service'].metadata.namespace,
        operatorObs.loki.manifests['distributor-http-service'].spec.ports[0].port,
      ],
    } else {},
  }),
};

{
  manifests: std.mapWithKey(function(k, v) v {
    metadata+: {
      ownerReferences: [{
        apiVersion: cr.apiVersion,
        kind: cr.kind,
        name: cr.metadata.name,
        uid: cr.metadata.uid,
        blockOwnerdeletion: true,
        controller: true,
      }],
    },
    spec+: (
      if (std.objectHas(obs.config, 'nodeSelector') && (v.kind == 'StatefulSet' || v.kind == 'Deployment')) then {
        template+: {
          spec+: {
            nodeSelector: obs.config.nodeSelector,
          },
        },
      } else {}
    ) + (
      if (std.objectHas(obs.config, 'affinity') && (v.kind == 'StatefulSet' || v.kind == 'Deployment')) then {
        template+: {
          spec+: {
            affinity: obs.config.affinity,
          },
        },
      } else {}
    ) + (
      if (std.objectHas(obs.config, 'tolerations') && (v.kind == 'StatefulSet' || v.kind == 'Deployment')) then {
        template+: {
          spec+: {
            tolerations: obs.config.tolerations,
          },
        },
      } else {}
    ) + (
      if (std.objectHas(cr.spec.thanos.rule, 'reloaderResources') && (v.kind == 'StatefulSet') && v.metadata.name == obs.config.name + '-thanos-rule') then {
        template+: {
          spec+: {
            containers: [
              if c.name == 'configmap-reloader' then c {
                resources: cr.spec.thanos.rule.reloaderResources,
              } else c
              for c in super.containers
            ],
          },
        },
      } else {}
    ),
  }, operatorObs.manifests),
}
