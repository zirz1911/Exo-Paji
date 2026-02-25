<script lang="ts">
  import type { Snippet } from "svelte";
  import ClusterWarnings from "./ClusterWarnings.svelte";
  import InstancesList from "./InstancesList.svelte";
  import type { DownloadProgress } from "$lib/stores/app.svelte";

  interface Props {
    // Topology data
    topologyData: any;
    lastUpdate: number;

    // Instances data
    instances: Record<string, any>;
    runners: Record<string, any>;
    downloads: Record<string, any>;

    // Warnings data
    tbBridgeCycles: string[][];
    identitiesData: any;
    rdmaCtlData: any;

    // State
    minimized?: boolean; // mini-map mode
    topologyOnly?: boolean; // fullscreen topology
    debugEnabled?: boolean;
    nodeFilter?: Set<string>;
    hoveredInstanceId?: string | null;

    // Callbacks
    onInstanceClick?: (instanceId: string, modelId: string) => void;
    onInstanceHover?: (instanceId: string | null) => void;
    onDeleteInstance?: (instanceId: string) => void;
    onToggleTopologyOnly?: () => void;
    onClearFilter?: () => void;

    // Helper functions (pass through to InstancesList)
    getInstanceDownloadStatus: (
      instanceId: string,
      instance: any,
    ) => {
      isDownloading: boolean;
      isFailed: boolean;
      errorMessage: string | null;
      progress: DownloadProgress | null;
      statusText: string;
      perNode: Array<{
        nodeId: string;
        nodeName: string;
        progress: DownloadProgress;
      }>;
    };
    getInstanceModelId: (instance: any) => string;
    getInstanceInfo: (instance: any) => {
      instanceType: string;
      sharding: string;
      nodeNames: string[];
      nodeIds: string[];
      nodeCount: number;
    };
    getInstanceConnections: (instance: any) => Array<{
      from: string;
      to: string;
      ip: string;
      ifaceLabel: string;
      missingIface: boolean;
    }>;
    deriveInstanceStatus: (instance: any) => {
      statusText: string;
      statusClass: string;
      layersLoaded?: number;
      totalLayers?: number;
    };
    formatBytes: (bytes: number, decimals?: number) => string;
    formatSpeed: (bps: number) => string;
    formatEta: (ms: number) => string;
    getStatusColor: (statusText: string) => string;
    getNodeName: (nodeId: string) => string;
    getTbBridgeServiceName: (cycle: string[]) => string;
    copyToClipboard?: (text: string) => Promise<void>;
    instanceDownloadExpandedNodes?: Set<string>;
    onToggleDownloadDetails?: (nodeId: string) => void;

    // Warning dismissal state
    tb5InfoDismissed?: boolean;
    macStudioEn2Dismissed?: boolean;
    copiedCommand?: boolean;
    onDismissTb5?: () => void;
    onDismissMacStudioEn2?: () => void;

    // Child components as snippets
    topologyGraph?: Snippet;
    modelLauncher?: Snippet;
  }

  let {
    topologyData,
    lastUpdate,
    instances,
    runners,
    downloads,
    tbBridgeCycles,
    identitiesData,
    rdmaCtlData,
    minimized = false,
    topologyOnly = false,
    debugEnabled = false,
    nodeFilter = new Set(),
    hoveredInstanceId = null,
    onInstanceClick,
    onInstanceHover,
    onDeleteInstance,
    onToggleTopologyOnly,
    onClearFilter,
    getInstanceDownloadStatus,
    getInstanceModelId,
    getInstanceInfo,
    getInstanceConnections,
    deriveInstanceStatus,
    formatBytes,
    formatSpeed,
    formatEta,
    getStatusColor,
    getNodeName,
    getTbBridgeServiceName,
    copyToClipboard,
    instanceDownloadExpandedNodes = new Set(),
    onToggleDownloadDetails,
    tb5InfoDismissed = false,
    macStudioEn2Dismissed = false,
    copiedCommand = false,
    onDismissTb5,
    onDismissMacStudioEn2,
    topologyGraph,
    modelLauncher,
  }: Props = $props();

  const isFilterActive = $derived(nodeFilter.size > 0);
  const instanceCount = $derived(Object.keys(instances).length);
</script>

<div class="flex-1 flex flex-col overflow-hidden">
  <!-- Topology Graph Area -->
  <div
    class="flex-1 relative overflow-hidden bg-exo-dark-gray/40 rounded-lg m-4"
  >
    {#if topologyGraph}
      {@render topologyGraph()}
    {/if}

    <!-- ClusterWarnings Overlay -->
    <div class="absolute top-4 left-4 flex flex-col gap-2 z-40">
      <ClusterWarnings
        {tbBridgeCycles}
        {identitiesData}
        instanceData={instances}
        {rdmaCtlData}
        {topologyData}
        {getNodeName}
        {getTbBridgeServiceName}
        {copyToClipboard}
        {copiedCommand}
        {tb5InfoDismissed}
        {macStudioEn2Dismissed}
        {onDismissTb5}
        {onDismissMacStudioEn2}
        compact={minimized}
      />
    </div>

    <!-- Node Filter Indicator -->
    {#if isFilterActive}
      <button
        onclick={onClearFilter}
        class="absolute top-2 right-2 flex items-center gap-1.5 px-2 py-1 bg-exo-dark-gray/80 border border-exo-green/40 rounded text-exo-green hover:border-exo-green/60 transition-colors cursor-pointer backdrop-blur-sm"
        title="Clear filter"
      >
        <span class="text-[10px] font-mono tracking-wider">
          FILTER: {nodeFilter.size}
        </span>
        <svg
          class="w-3 h-3"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="2"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="M6 18L18 6M6 6l12 12"
          />
        </svg>
      </button>
    {/if}

    <!-- Exit topology-only mode button -->
    {#if topologyOnly}
      <button
        type="button"
        onclick={onToggleTopologyOnly}
        class="absolute bottom-4 right-4 p-2 rounded border border-exo-green/30 bg-exo-dark-gray/80 hover:border-exo-green/50 hover:bg-exo-dark-gray transition-colors cursor-pointer backdrop-blur-sm"
        title="Exit topology only mode"
        aria-label="Exit topology only mode"
      >
        <svg
          class="w-5 h-5 text-exo-green"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
          stroke-width="2"
        >
          <circle cx="12" cy="5" r="2" fill="currentColor" />
          <circle cx="5" cy="19" r="2" fill="currentColor" />
          <circle cx="19" cy="19" r="2" fill="currentColor" />
          <path stroke-linecap="round" d="M12 7v5m0 0l-5 5m5-5l5 5" />
        </svg>
      </button>
    {/if}
  </div>

  <!-- Instances List (only if not minimized) -->
  {#if !minimized && instanceCount > 0}
    <div class="px-4 max-h-96 overflow-y-auto">
      <div
        class="mb-2 text-xs text-exo-green font-mono uppercase tracking-wider"
      >
        <div class="flex items-center gap-2">
          <div
            class="w-2 h-2 bg-exo-green rounded-full shadow-[0_0_8px_rgba(0,255,65,0.6)] animate-pulse"
          ></div>
          <span>INSTANCES</span>
          <div
            class="flex-1 h-px bg-gradient-to-r from-exo-green/30 to-transparent"
          ></div>
        </div>
      </div>
      <InstancesList
        {instances}
        {runners}
        {downloads}
        {topologyData}
        {debugEnabled}
        onInstanceClick={onInstanceClick}
        onDeleteInstance={onDeleteInstance}
        {hoveredInstanceId}
        onHover={onInstanceHover}
        {getInstanceDownloadStatus}
        {getInstanceModelId}
        {getInstanceInfo}
        {getInstanceConnections}
        {deriveInstanceStatus}
        {formatBytes}
        {formatSpeed}
        {formatEta}
        {getStatusColor}
        {instanceDownloadExpandedNodes}
        {onToggleDownloadDetails}
      />
    </div>
  {/if}

  <!-- Controls (Model Launcher) -->
  {#if modelLauncher && !minimized}
    <div class="p-4 border-t border-exo-green/10">
      {@render modelLauncher()}
    </div>
  {/if}
</div>
