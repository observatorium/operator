local cr = import 'generic-operator/config';
local loki = import 'github.com/observatorium/deployments/components/loki.libsonnet';
local memcached = import 'github.com/observatorium/deployments/components/memcached.libsonnet';
local api = import 'github.com/observatorium/observatorium/jsonnet/lib/observatorium-api.libsonnet';
local receiveController = import 'github.com/observatorium/thanos-receive-controller/jsonnet/lib/thanos-receive-controller.libsonnet';
local thanos = import 'github.com/thanos-io/kube-thanos/jsonnet/kube-thanos/thanos.libsonnet';
local obs = (import 'github.com/observatorium/deployments/environments/base/observatorium.jsonnet');

local operatorObs = obs {
  thanos+:: {
    compact+:: thanos.compact(obs.thanos.compact.config {
      image: if std.objectHas(cr.spec.compact, 'image') then cr.spec.compact.image else obs.thanos.compact.config.image,
      version: if std.objectHas(cr.spec.compact, 'version') then cr.spec.compact.version else obs.thanos.compact.config.version,
      replicas: if std.objectHas(cr.spec.compact, 'replicas') then cr.spec.compact.replicas else obs.thanos.compact.config.replicas,
      objectStorageConfig: cr.spec.objectStorageConfig.thanos,
      logLevel: 'info',
    }),

    thanosReceiveController:: receiveController(obs.thanos.receiveController.config {
      image: if std.objectHas(cr.spec, 'thanosReceiveController') && std.objectHas(cr.spec.thanosReceiveController, 'image') then cr.spec.thanosReceiveController.image else obs.thanos.receiveController.config.image,
      version: if std.objectHas(cr.spec, 'thanosReceiveController') && std.objectHas(cr.spec.thanosReceiveController, 'version') then cr.spec.thanosReceiveController.version else obs.thanos.receiveController.config.version,
      hashrings: cr.spec.hashrings,
    }),

    receivers:: thanos.receiveHashrings(obs.thanos.receivers.config {
      hashrings: cr.spec.hashrings,
      image: if std.objectHas(cr.spec.receivers, 'image') then cr.spec.receivers.image else obs.thanos.receivers.config.image,
      version: if std.objectHas(cr.spec.receivers, 'version') then cr.spec.receivers.version else obs.thanos.receivers.config.version,
      replicas: if std.objectHas(cr.spec.receivers, 'replicas') then cr.spec.receivers.replicas else obs.thanos.receivers.config.replicas,
      objectStorageConfig: cr.spec.objectStorageConfig.thanos,
      logLevel: 'info',
      debug: '',
    }),

    rule:: thanos.rule(obs.thanos.rule.config {
      image: if std.objectHas(cr.spec.rule, 'image') then cr.spec.rule.image else obs.thanos.rule.config.image,
      version: if std.objectHas(cr.spec.rule, 'version') then cr.spec.rule.version else obs.thanos.rule.config.version,
      replicas: if std.objectHas(cr.spec.rule, 'replicas') then cr.spec.rule.replicas else obs.thanos.rule.config.replicas,
      objectStorageConfig: cr.spec.objectStorageConfig.thanos,
    }),

    store:: thanos.storeShards(obs.thanos.store.config {
      image: if std.objectHas(cr.spec.store, 'image') then cr.spec.store.image else obs.thanos.store.config.image,
      version: if std.objectHas(cr.spec.store, 'version') then cr.spec.store.version else obs.thanos.store.config.version,
      objectStorageConfig: cr.spec.objectStorageConfig.thanos,
      logLevel: 'info',
    }),

    storeCache:: memcached(obs.thanos.storeCache.config {
      image: if std.objectHas(cr.spec.store, 'cache') && std.objectHas(cr.spec.store.cache, 'image') then cr.spec.store.cache.image else obs.thanos.storeCache.config.image,
      version: if std.objectHas(cr.spec.store, 'cache') && std.objectHas(cr.spec.store.cache, 'version') then cr.spec.store.cache.version else obs.thanos.storeCache.config.version,
      exporterImage: if std.objectHas(cr.spec.store, 'cache') && std.objectHas(cr.spec.store.cache, 'exporterImage') then cr.spec.store.cache.exporterImage else obs.thanos.storeCache.config.exporterImage,
      exporterVersion: if std.objectHas(cr.spec.store, 'cache') && std.objectHas(cr.spec.store.cache, 'exporterVersion') then cr.spec.store.cache.exporterVersion else obs.thanos.storeCache.config.exporterVersion,
      replicas: if std.objectHas(cr.spec.store, 'cache') && std.objectHas(cr.spec.store.cache, 'replicas') then cr.spec.store.cache.replicas else obs.thanos.storeCache.config.replicas,
      memoryLimitMb: if std.objectHas(cr.spec.store, 'cache') && std.objectHas(cr.spec.store.cache, 'memoryLimitMb') then cr.spec.store.cache.memoryLimitMb else obs.thanos.storeCache.config.memoryLimitMb,
    }),

    query:: thanos.query(obs.thanos.query.config {
      image: if std.objectHas(cr.spec, 'query') && std.objectHas(cr.spec.query, 'image') then cr.spec.query.image else obs.thanos.config.image,
      version: if std.objectHas(cr.spec, 'query') && std.objectHas(cr.spec.query, 'version') then cr.spec.query.version else obs.thanos.config.version,
      replicas: if std.objectHas(cr.spec, 'query') && std.objectHas(cr.spec.query, 'replicas') then cr.spec.query.replicas else obs.thanos.config.replicas,
    }),

    queryFrontend:: thanos.queryFrontend(obs.thanos.queryFrontend.config {
      image: if std.objectHas(cr.spec, 'queryFrontend') && std.objectHas(cr.spec.queryFrontend, 'image') then cr.spec.queryFrontend.image else obs.thanos.queryFrontend.config.image,
      version: if std.objectHas(cr.spec, 'queryFrontend') && std.objectHas(cr.spec.queryFrontend, 'version') then cr.spec.queryFrontend.version else obs.thanos.queryFrontend.config.version,
      replicas: if std.objectHas(cr.spec, 'queryFrontend') && std.objectHas(cr.spec.queryFrontend, 'replicas') then cr.spec.queryFrontend.replicas else obs.thanos.queryFrontend.config.replicas,
      queryRangeCache: {},
      labelsCache: {},
    }),

    queryFrontendCache:: {},
  },

  config+:: {
    loki+:: if std.objectHas(cr.spec, 'loki') then {  // NOTICE: Will be removed after loki refactor.
      image: if std.objectHas(cr.spec.loki, 'image') then cr.spec.loki.image else obs.loki.config.image,
      replicas: if std.objectHas(cr.spec.loki, 'replicas') then cr.spec.loki.replicas else obs.loki.config.replicas,
      version: if std.objectHas(cr.spec.loki, 'version') then cr.spec.loki.version else obs.loki.config.version,
      objectStorageConfig: if cr.spec.objectStorageConfig.loki != null then cr.spec.objectStorageConfig.loki else obs.loki.config.objectStorageConfig,
    } else {},
  },

  loki+:: loki.withVolumeClaimTemplate {  // NOTICE: Will be removed after loki refactor.
    config+:: if std.objectHas(cr.spec, 'loki') then obs.loki.config else {},
  },

  gubernator:: {},

  // TODO(kakkoyun): This should be removed.
  apiQuery:: api(obs.api.config {
    image: if std.objectHas(cr.spec, 'apiQuery') && std.objectHas(cr.spec.apiQuery, 'image') then cr.spec.apiQuery.image else obs.api.config.image,
    version: if std.objectHas(cr.spec, 'apiQuery') && std.objectHas(cr.spec.apiQuery, 'version') then cr.spec.apiQuery.version else obs.api.config.version,
  }),

  api:: api(obs.api.config {
    image: if std.objectHas(cr.spec, 'api') && std.objectHas(cr.spec.api, 'image') then cr.spec.api.image else obs.api.config.image,
    version: if std.objectHas(cr.spec, 'api') && std.objectHas(cr.spec.api, 'version') then cr.spec.api.version else obs.api.config.version,
    replicas: if std.objectHas(cr.spec, 'api') && std.objectHas(cr.spec.api, 'replicas') then cr.spec.api.replicas else obs.api.config.replicas,
    tls: if std.objectHas(cr.spec, 'api') && std.objectHas(cr.spec.api, 'tls') then cr.spec.api.tls else obs.api.config.tls,
    rbac: if std.objectHas(cr.spec, 'api') && std.objectHas(cr.spec.api, 'rbac') then cr.spec.api.rbac else obs.api.config.rbac,
    tenants: if std.objectHas(cr.spec, 'api') && std.objectHas(cr.spec.api, 'tenants') then { tenants: cr.spec.api.tenants } else obs.api.config.tenants,
    rateLimiter: {},
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
    ),
  }, operatorObs.manifests),
}
