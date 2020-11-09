local t = (import 'github.com/thanos-io/kube-thanos/jsonnet/kube-thanos/thanos.libsonnet');
local loki = import 'github.com/observatorium/deployments/components/loki.libsonnet';
local config = import './operator-config.libsonnet';
local obs = ((import 'github.com/observatorium/deployments/components/observatorium.libsonnet') + {
               config+:: config,
             } + (import 'github.com/observatorium/deployments/components/observatorium-configure.libsonnet'));

local patchObs = obs {
  compact+::
    t.compact.withVolumeClaimTemplate {
      config+:: obs.compact.config,
    },

  rule+::
    t.rule.withVolumeClaimTemplate {
      config+:: obs.rule.config,
    } + (if std.objectHas(obs.rule.config, 'alertmanagersURL') then 
      t.rule.withAlertmanagers {
        config+:: {
          alertmanagersURL: obs.rule.config.alertmanagersURL,
        }
      } else {}
    ) + (if std.objectHas(obs.rule.config, 'rulesConfig') then 
      t.rule.withRules {
        config+:: {
          rulesConfig: obs.rule.config.rulesConfig
        }
      } else {}
    ),

  receivers+:: {
    [hashring.hashring]+:
      t.receive.withVolumeClaimTemplate {
        config+:: obs.receivers[hashring.hashring].config,
      }
    for hashring in obs.config.hashrings
  },

  store+:: {
    ['shard' + i]+:
      t.store.withVolumeClaimTemplate {
        config+:: obs.store['shard' + i].config,
      }
    for i in std.range(0, obs.config.store.shards - 1)
  },

  loki+:: loki.withVolumeClaimTemplate {
    config+:: obs.loki.config,
  },
};

{
  manifests: std.mapWithKey(function(k, v) v {
    metadata+: {
      ownerReferences: [{
        apiVersion: config.apiVersion,
        blockOwnerdeletion: true,
        controller: true,
        kind: config.kind,
        name: config.name,
        uid: config.uid,
      }],
    },
    spec+: (
      if (std.objectHas(obs.config, 'nodeSelector') && (v.kind == 'StatefulSet' || v.kind == 'Deployment')) then {
        template+: {
          spec+:{
            nodeSelector: obs.config.nodeSelector,
          },
        },
      } else {}
    ) + (
      if (std.objectHas(obs.config, 'affinity') && (v.kind == 'StatefulSet' || v.kind == 'Deployment')) then {
        template+: {
          spec+:{
            affinity: obs.config.affinity,
          },
        },
      } else {}
    ),
  }, patchObs.manifests),
}
