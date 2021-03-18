/*

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package v1alpha1

import (
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

// ObservatoriumSpec defines the desired state of Observatorium
type ObservatoriumSpec struct {
	// Objest Storage Configuration
	ObjectStorageConfig ObjectStorageConfig `json:"objectStorageConfig"`
	// Hashrings describes a list of Hashrings
	Hashrings []*Hashring `json:"hashrings"`
	// Thanos CompactSpec
	Compact CompactSpec `json:"compact"`
	// Thanos Receive Controller Spec
	ThanosReceiveController ThanosReceiveControllerSpec `json:"thanosReceiveController,omitempty"`
	// Thanos ThanosPersistentSpec
	Receivers ReceiversSpec `json:"receivers"`
	// Thanos QueryFrontend
	QueryFrontend QueryFrontendSpec `json:"queryFrontend,omitempty"`
	// Thanos StoreSpec
	Store StoreSpec `json:"store"`
	// Thanos RulerSpec
	Rule RuleSpec `json:"rule"`
	// API
	API APISpec `json:"api,omitempty"`
	// Query
	Query QuerySpec `json:"query,omitempty"`
	// Loki
	// +optional
	Loki *LokiSpec `json:"loki,omitempty"`
	// NodeSelector causes all components to be scheduled on nodes with matching labels.
	// +optional
	NodeSelector map[string]string `json:"nodeSelector,omitempty"`
	// Affinity causes all components to be scheduled on nodes with matching rules.
	// +optional
	Affinity *v1.Affinity `json:"affinity,omitempty"`
	// Tolerations causes all components to tolerate specified taints.
	// +optional
	Tolerations []v1.Toleration `json:"tolerations,omitempty"`
	// Security options the pod should run with.
	// +optional
	SecurityContext *v1.SecurityContext `json:"securityContext,omitempty"`
}

type ObjectStorageConfig struct {
	// Object Store Config Secret for Thanos
	Thanos *ThanosObjectStorageConfigSpec `json:"thanos"`
	// Object Store Config Secret for Loki
	// +optional
	Loki *LokiObjectStorageConfigSpec `json:"loki,omitempty"`
}

type ThanosObjectStorageConfigSpec struct {
	// Object Store Config Secret Name
	Name string `json:"name"`
	// Object Store Config key
	Key string `json:"key"`
}

type LokiObjectStorageConfigSpec struct {
	// Object Store Config Secret Name
	SecretName string `json:"secretName"`
	// Object Store Config key for S3_URL
	// +optional
	EndpointKey string `json:"endpointKey"`
	// Object Store Config key for AWS_ACCESS_KEY_ID
	// +optional
	AccessKeyIDKey string `json:"accessKeyIdKey"`
	// Object Store Config key for AWS_SECRET_ACCESS_KEY
	// +optional
	SecretAccessKeyKey string `json:"secretAccessKeyKey"`
	// Object Store Config key for S3_BUCKETS
	// +optional
	BucketsKey string `json:"bucketsKey"`
	// Object Store Config key for S3_REGION
	// +optional
	RegionKey string `json:"regionKey"`
}

type ThanosReceiveControllerSpec struct {
	// Receive Controller image
	Image string `json:"image,omitempty"`
	// Version describes the version of Thanos receive controller to use.
	Version string `json:"version,omitempty"`
	// Compute Resources required by this container.
	// +optional
	Resources v1.ResourceRequirements `json:"resources,omitempty"`
}

type ReceiversSpec struct {
	// Thanos image
	Image string `json:"image,omitempty"`
	// Number of Receiver replicas.
	Replicas *int32 `json:"replicas,omitempty"`
	// Version of Thanos image to be deployed.
	Version string `json:"version,omitempty"`
	// VolumeClaimTemplate
	VolumeClaimTemplate VolumeClaimTemplate `json:"volumeClaimTemplate"`
	// ReplicationFactor defines the number of copies of every time-series
	ReplicationFactor *int32 `json:"replicationFactor,omitempty"`
	// Compute Resources required by this container.
	// +optional
	Resources v1.ResourceRequirements `json:"resources,omitempty"`
}

type StoreSpec struct {
	// Thanos image
	Image string `json:"image,omitempty"`
	// Version of Thanos image to be deployed.
	Version string `json:"version,omitempty"`
	// VolumeClaimTemplate
	VolumeClaimTemplate VolumeClaimTemplate `json:"volumeClaimTemplate"`
	Shards              *int32              `json:"shards,omitempty"`
	// Memcached spec for Store
	Cache StoreCacheSpec `json:"cache,omitempty"`
	// Compute Resources required by this container.
	// +optional
	Resources v1.ResourceRequirements `json:"resources,omitempty"`
}

// StoreCacheSpec describes configuration for Store Memcached
type StoreCacheSpec struct {
	// Memcached image
	Image string `json:"image,omitempty"`
	// Version of Memcached image to be deployed.
	Version string `json:"version,omitempty"`
	// Memcached Prometheus Exporter image
	ExporterImage string `json:"exporterImage,omitempty"`
	// Version of Memcached Prometheus Exporter image to be deployed.
	ExporterVersion string `json:"exporterVersion,omitempty"`
	// Number of Memcached replicas.
	Replicas *int32 `json:"replicas,omitempty"`
	// Memory limit of Memcached in megabytes.
	MemoryLimitMB *int32 `json:"memoryLimitMb,omitempty"`
	// Compute Resources required by this container.
	// +optional
	Resources v1.ResourceRequirements `json:"resources,omitempty"`
	// Compute Resources required by this container.
	// +optional
	ExporterResources v1.ResourceRequirements `json:"exporterResources,omitempty"`
}

// Permission is an Observatorium RBAC permission.
type Permission string

const (
	// Write gives access to write data to a tenant.
	Write Permission = "write"
	// Read gives access to read data from a tenant.
	Read Permission = "read"
)

// RBACRole describes a set of permissions to interact with a tenant.
type RBACRole struct {
	// Name is the name of the role.
	Name string `json:"name"`
	// Resources is a list of resources to which access will be granted.
	Resources []string `json:"resources"`
	// Tenants is a list of tenants whose resources will be considered.
	Tenants []string `json:"tenants"`
	// Permissions is a list of permissions that will be granted.
	Permissions []Permission `json:"permissions"`
}

// SubjectKind is a kind of Observatorium subject.
type SubjectKind string

const (
	// User represents a subject that is a user.
	User SubjectKind = "user"
	// Group represents a subject that is a group.
	Group SubjectKind = "group"
)

// Subject represents a subject to which an RBAC role can be bound.
type Subject struct {
	Kind SubjectKind `json:"kind"`
	Name string      `json:"name"`
}

// RBACRoleBinding binds a set of roles to a set of subjects.
type RBACRoleBinding struct {
	// Name is the name of the role binding.
	Name string `json:"name"`
	// Subjects is a list of subjects who will be given access to the specified roles.
	Subjects []Subject `json:"subjects"`
	// Roles is a list of roles that will be bound.
	Roles []string `json:"roles"`
}

// APIRBAC represents a set of Observatorium API RBAC roles and role bindings.
type APIRBAC struct {
	// Roles is a slice of Observatorium API roles.
	Roles []RBACRole `json:"roles"`
	// RoleBindings is a slice of Observatorium API role bindings.
	RoleBindings []RBACRoleBinding `json:"roleBindings"`
}

// TenantOIDC represents the OIDC configuration for an Observatorium API tenant.
type TenantOIDC struct {
	ClientID      string `json:"clientID"`
	ClientSecret  string `json:"clientSecret,omitempty"`
	IssuerURL     string `json:"issuerURL"`
	RedirectURL   string `json:"redirectURL,omitempty"`
	UsernameClaim string `json:"usernameClaim,omitempty"`
}

// TenantMTLS represents the mTLS configuration for an Observatorium API tenant.
type TenantMTLS struct {
	CAKey string `json:"caKey"`
	// +optional
	SecretName string `json:"secretName,omitempty"`
	// +optional
	ConfigMapName string `json:"configMapName,omitempty"`
}

// APITenant represents a tenant in the Observatorium API.
type APITenant struct {
	Name string `json:"name"`
	ID   string `json:"id"`
	// +optional
	OIDC *TenantOIDC `json:"oidc,omitempty"`
	// +optional
	MTLS *TenantMTLS `json:"mTLS,omitempty"`
}

// TLS contains the TLS configuration for a component.
type TLS struct {
	SecretName string `json:"secretName"`
	CertKey    string `json:"certKey"`
	KeyKey     string `json:"keyKey"`
	// +optional
	ConfigMapName string `json:"configMapName,omitempty"`
	// +optional
	CAKey string `json:"caKey,omitempty"`
	// +optional
	ServerName string `json:"serverName,omitempty"`
	// +optional
	ReloadInterval string `json:"reloadInterval,omitempty"`
}

type APISpec struct {
	// API image
	Image string `json:"image,omitempty"`
	// Number of API replicas.
	Replicas *int32 `json:"replicas,omitempty"`
	// Version describes the version of API to use.
	Version string `json:"version,omitempty"`
	// TLS configuration for the Observatorium API.
	TLS TLS `json:"tls,omitempty"`
	// RBAC is an RBAC configuration for the Observatorium API.
	RBAC APIRBAC `json:"rbac"`
	// Tenants is a slice of tenants for the Observatorium API.
	Tenants []APITenant `json:"tenants"`
	// Compute Resources required by this container.
	// +optional
	Resources v1.ResourceRequirements `json:"resources,omitempty"`
}

type QuerySpec struct {
	// Thanos image
	Image string `json:"image,omitempty"`
	// Number of Query replicas.
	Replicas *int32 `json:"replicas,omitempty"`
	// Version of Thanos image to be deployed.
	Version string `json:"version,omitempty"`
	// Compute Resources required by this container.
	// +optional
	Resources v1.ResourceRequirements `json:"resources,omitempty"`
}

type RuleConfig struct {
	// Rule ConfigMap Name
	Name string `json:"name"`
	// Rule ConfigMap key
	Key string `json:"key"`
}

type RuleSpec struct {
	// Thanos image
	Image string `json:"image,omitempty"`
	// Number of Rule replicas.
	Replicas *int32 `json:"replicas,omitempty"`
	// Version of Thanos image to be deployed.
	Version string `json:"version,omitempty"`
	// VolumeClaimTemplate
	VolumeClaimTemplate VolumeClaimTemplate `json:"volumeClaimTemplate"`
	// RulesConfig configures rules from the configmaps
	// +optional
	RulesConfig []RuleConfig `json:"rulesConfig,omitempty"`
	// AlertmanagersURL
	// +optional
	AlertmanagersURL []string `json:"alertmanagersURL,omitempty"`
	// ReloaderImage is an image of configmap reloader
	// +optional
	ReloaderImage string `json:"reloaderImage,omitempty"`
	// Compute Resources required by this container.
	// +optional
	Resources v1.ResourceRequirements `json:"resources,omitempty"`
	// Compute Resources required by this container.
	// +optional
	ReloaderResources v1.ResourceRequirements `json:"reloaderResources,omitempty"`
}

type CompactSpec struct {
	// Thanos image
	Image string `json:"image,omitempty"`
	// Number of Compact replicas.
	Replicas *int32 `json:"replicas,omitempty"`
	// Version of Thanos image to be deployed.
	Version string `json:"version,omitempty"`
	// VolumeClaimTemplate
	VolumeClaimTemplate VolumeClaimTemplate `json:"volumeClaimTemplate"`
	// RetentionResolutionRaw
	RetentionResolutionRaw string `json:"retentionResolutionRaw"`
	// RetentionResolutionRaw
	RetentionResolution5m string `json:"retentionResolution5m"`
	// RetentionResolutionRaw
	RetentionResolution1h string `json:"retentionResolution1h"`
	// EnableDownsampling enables downsampling.
	EnableDownsampling bool `json:"enableDownsampling,omitempty"`
	// Compute Resources required by this container.
	// +optional
	Resources v1.ResourceRequirements `json:"resources,omitempty"`
}

type VolumeClaimTemplate struct {
	Spec v1.PersistentVolumeClaimSpec `json:"spec"`
}

type QueryFrontendSpec struct {
	// Thanos Query Frontend image
	Image string `json:"image,omitempty"`
	// Number of Query Frontend replicas.
	Replicas *int32 `json:"replicas,omitempty"`
	// Version of Query Frontend image to be deployed.
	Version string `json:"version,omitempty"`
	// Compute Resources required by this container.
	// +optional
	Resources v1.ResourceRequirements `json:"resources,omitempty"`
}

type Hashring struct {
	// Thanos Hashring name
	Hashring string `json:"hashring"`
	// Tenants describes a lists of tenants.
	Tenants []string `json:"tenants,omitempty"`
}

type LokiSpec struct {
	// Loki image
	Image string `json:"image"`
	// Loki replicas per component
	Replicas map[string]int32 `json:"replicas,omitempty"`
	// Version of Loki image to be deployed
	Version string `json:"version,omitempty"`
	// VolumeClaimTemplate
	VolumeClaimTemplate VolumeClaimTemplate `json:"volumeClaimTemplate"`
}

// ObservatoriumStatus defines the observed state of Observatorium
type ObservatoriumStatus struct {
	// INSERT ADDITIONAL STATUS FIELD - define observed state of cluster
	// Important: Run "make" to regenerate code after modifying this file
}

// Observatorium is the Schema for the observatoria API
// +kubebuilder:object:root=true
// +kubebuilder:subresource:status
type Observatorium struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty"`

	Spec   ObservatoriumSpec   `json:"spec,omitempty"`
	Status ObservatoriumStatus `json:"status,omitempty"`
}

// +kubebuilder:object:root=true

// ObservatoriumList contains a list of Observatorium
type ObservatoriumList struct {
	metav1.TypeMeta `json:",inline"`
	metav1.ListMeta `json:"metadata,omitempty"`
	Items           []Observatorium `json:"items"`
}

func init() {
	SchemeBuilder.Register(&Observatorium{}, &ObservatoriumList{})
}
