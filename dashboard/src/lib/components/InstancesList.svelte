<script lang="ts">
  import { slide } from "svelte/transition";
  import { cubicOut } from "svelte/easing";
  import type { DownloadProgress } from "$lib/stores/app.svelte";

  interface Props {
    instances: Record<string, any>;
    runners: Record<string, any>;
    downloads: Record<string, any>;
    topologyData: any;
    debugEnabled?: boolean;
    compact?: boolean;
    onInstanceClick?: (instanceId: string, modelId: string) => void;
    onDeleteInstance?: (instanceId: string) => void;
    hoveredInstanceId?: string | null;
    onHover?: (instanceId: string | null) => void;
    // Helper functions passed as props
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
    instanceDownloadExpandedNodes?: Set<string>;
    onToggleDownloadDetails?: (nodeId: string) => void;
  }

  let {
    instances,
    runners,
    downloads,
    topologyData,
    debugEnabled = false,
    compact = false,
    onInstanceClick,
    onDeleteInstance,
    hoveredInstanceId = null,
    onHover,
    getInstanceDownloadStatus,
    getInstanceModelId,
    getInstanceInfo,
    getInstanceConnections,
    deriveInstanceStatus,
    formatBytes,
    formatSpeed,
    formatEta,
    getStatusColor,
    instanceDownloadExpandedNodes = new Set(),
    onToggleDownloadDetails,
  }: Props = $props();

  const instanceEntries = $derived(Object.entries(instances));
</script>

<div
  class="space-y-3 overflow-y-auto overflow-x-hidden py-px {compact
    ? 'max-h-48'
    : 'max-h-72 xl:max-h-96'}"
>
  {#each instanceEntries as [id, instance]}
    {@const downloadInfo = getInstanceDownloadStatus(id, instance)}
    {@const statusText = downloadInfo.statusText}
    {@const isDownloading = downloadInfo.isDownloading}
    {@const isFailed = statusText === "FAILED"}
    {@const isLoading = statusText === "LOADING"}
    {@const isWarmingUp = statusText === "WARMING UP" || statusText === "WAITING"}
    {@const isReady = statusText === "READY" || statusText === "LOADED"}
    {@const isRunning = statusText === "RUNNING"}
    {@const instanceModelId = getInstanceModelId(instance)}
    {@const instanceInfo = getInstanceInfo(instance)}
    {@const instanceConnections = getInstanceConnections(instance)}
    {@const isHovered = hoveredInstanceId === id}

    <div
      class="relative group cursor-pointer"
      role="button"
      tabindex="0"
      transition:slide={{ duration: 250, easing: cubicOut }}
      onmouseenter={() => onHover?.(id)}
      onmouseleave={() => onHover?.(null)}
      onclick={() => {
        if (
          instanceModelId &&
          instanceModelId !== "Unknown" &&
          instanceModelId !== "Unknown Model"
        ) {
          onInstanceClick?.(id, instanceModelId);
        }
      }}
      onkeydown={(e) => {
        if (e.key === "Enter" || e.key === " ") {
          if (
            instanceModelId &&
            instanceModelId !== "Unknown" &&
            instanceModelId !== "Unknown Model"
          ) {
            onInstanceClick?.(id, instanceModelId);
          }
        }
      }}
    >
      <!-- Corner accents -->
      <div
        class="absolute -top-px -left-px w-2 h-2 border-l border-t {isDownloading
          ? 'border-blue-500/50'
          : isFailed
            ? 'border-red-500/50'
            : isLoading
              ? 'border-yellow-500/50'
              : isReady
                ? 'border-green-500/50'
                : 'border-teal-500/50'}"
      ></div>
      <div
        class="absolute -top-px -right-px w-2 h-2 border-r border-t {isDownloading
          ? 'border-blue-500/50'
          : isFailed
            ? 'border-red-500/50'
            : isLoading
              ? 'border-yellow-500/50'
              : isReady
                ? 'border-green-500/50'
                : 'border-teal-500/50'}"
      ></div>
      <div
        class="absolute -bottom-px -left-px w-2 h-2 border-l border-b {isDownloading
          ? 'border-blue-500/50'
          : isFailed
            ? 'border-red-500/50'
            : isLoading
              ? 'border-yellow-500/50'
              : isReady
                ? 'border-green-500/50'
                : 'border-teal-500/50'}"
      ></div>
      <div
        class="absolute -bottom-px -right-px w-2 h-2 border-r border-b {isDownloading
          ? 'border-blue-500/50'
          : isFailed
            ? 'border-red-500/50'
            : isLoading
              ? 'border-yellow-500/50'
              : isReady
                ? 'border-green-500/50'
                : 'border-teal-500/50'}"
      ></div>

      <div
        class="bg-exo-dark-gray/60 border border-l-2 transition-all duration-200 group-hover:bg-exo-dark-gray/80 {isDownloading
          ? 'border-blue-500/30 border-l-blue-400 group-hover:border-blue-500/50'
          : isFailed
            ? 'border-red-500/30 border-l-red-400 group-hover:border-red-500/50'
            : isLoading
              ? 'border-exo-green/30 border-l-yellow-400 group-hover:border-exo-green/50'
              : isReady
                ? 'border-green-500/30 border-l-green-400 group-hover:border-green-500/50'
                : 'border-teal-500/30 border-l-teal-400 group-hover:border-teal-500/50'} p-3"
      >
        <div class="flex justify-between items-start mb-2 pl-2">
          <div class="flex items-center gap-2">
            <div
              class="w-1.5 h-1.5 {isDownloading
                ? 'bg-blue-400 animate-pulse'
                : isFailed
                  ? 'bg-red-400'
                  : isLoading
                    ? 'bg-yellow-400 animate-pulse'
                    : isReady
                      ? 'bg-green-400'
                      : 'bg-teal-400'} rounded-full shadow-[0_0_6px_currentColor]"
            ></div>
            <span class="text-exo-light-gray font-mono text-sm tracking-wider"
              >{id.slice(0, 8).toUpperCase()}</span
            >
          </div>
          {#if onDeleteInstance}
            <button
              onclick={(e) => {
                e.stopPropagation();
                onDeleteInstance(id);
              }}
              class="text-xs px-2 py-1 font-mono tracking-wider uppercase border border-red-500/30 text-red-400 hover:bg-red-500/20 hover:text-red-400 hover:border-red-500/50 transition-all duration-200 cursor-pointer"
            >
              DELETE
            </button>
          {/if}
        </div>
        <div class="pl-2">
          <div class="text-exo-green text-xs font-mono tracking-wide truncate">
            {instanceModelId}
          </div>
          <div
            class="flex items-center gap-2 text-white/60 text-xs font-mono"
          >
            <span
              >{instanceInfo.sharding} &middot; {instanceInfo.instanceType}</span
            >
            <span
              class="px-1.5 py-0.5 text-[10px] tracking-wider uppercase rounded transition-all duration-300 {isDownloading
                ? 'bg-blue-500/15 text-blue-400'
                : isFailed
                  ? 'bg-red-500/15 text-red-400'
                  : isLoading
                    ? 'bg-yellow-500/15 text-yellow-400'
                    : isReady
                      ? 'bg-green-500/15 text-green-400'
                      : 'bg-teal-500/15 text-teal-400'}"
            >
              {statusText}
            </span>
          </div>
          {#if instanceModelId && instanceModelId !== "Unknown" && instanceModelId !== "Unknown Model"}
            <a
              class="inline-flex items-center gap-1 text-[11px] text-white/60 hover:text-exo-green transition-colors mt-1"
              href={`https://huggingface.co/${instanceModelId}`}
              target="_blank"
              rel="noreferrer noopener"
              aria-label="View model on Hugging Face"
              onclick={(e) => e.stopPropagation()}
            >
              <span>Hugging Face</span>
              <svg
                class="w-3.5 h-3.5"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path d="M14 3h7v7" />
                <path d="M10 14l11-11" />
                <path
                  d="M21 14v6a1 1 0 0 1-1 1h-16a1 1 0 0 1-1-1v-16a1 1 0 0 1 1-1h6"
                />
              </svg>
            </a>
          {/if}
          {#if instanceInfo.nodeNames.length > 0}
            <div class="text-white/60 text-xs font-mono">
              {instanceInfo.nodeNames.join(", ")}
            </div>
          {/if}
          {#if debugEnabled && instanceConnections.length > 0}
            <div class="mt-2 space-y-1">
              {#each instanceConnections as conn}
                <div class="text-[11px] leading-snug font-mono text-white/70">
                  <span>{conn.from} -> {conn.to}: {conn.ip}</span>
                  <span
                    class={conn.missingIface ? "text-red-400" : "text-white/60"}
                  >
                    ({conn.ifaceLabel})</span
                  >
                </div>
              {/each}
            </div>
          {/if}

          <!-- Download Progress -->
          {#if downloadInfo.isDownloading && downloadInfo.progress}
            <div class="mt-2 space-y-1">
              <div class="flex justify-between text-xs font-mono">
                <span class="text-blue-400"
                  >{downloadInfo.progress.percentage.toFixed(1)}%</span
                >
                <span class="text-exo-light-gray"
                  >{formatBytes(downloadInfo.progress.downloadedBytes)}/{formatBytes(
                    downloadInfo.progress.totalBytes,
                  )}</span
                >
              </div>
              <div
                class="relative h-1.5 bg-exo-black/60 rounded-sm overflow-hidden"
              >
                <div
                  class="absolute inset-y-0 left-0 bg-gradient-to-r from-blue-500 to-blue-400 transition-all duration-300"
                  style="width: {downloadInfo.progress.percentage}%"
                ></div>
              </div>
              <div
                class="flex justify-between text-xs font-mono text-exo-light-gray"
              >
                <span>{formatSpeed(downloadInfo.progress.speed)}</span>
                <span>ETA: {formatEta(downloadInfo.progress.etaMs)}</span>
                <span
                  >{downloadInfo.progress.completedFiles}/{downloadInfo.progress
                    .totalFiles} files</span
                >
              </div>
            </div>
            {#if downloadInfo.perNode.length > 0}
              <div class="mt-2 space-y-2 max-h-48 overflow-y-auto pr-1">
                {#each downloadInfo.perNode as nodeProg}
                  {@const nodePercent = Math.min(
                    100,
                    Math.max(0, nodeProg.progress.percentage),
                  )}
                  {@const isExpanded = instanceDownloadExpandedNodes.has(
                    nodeProg.nodeId,
                  )}
                  <div
                    class="rounded border border-exo-medium-gray/40 bg-exo-black/30 p-2"
                  >
                    <button
                      type="button"
                      class="w-full text-left space-y-1.5"
                      onclick={(e) => {
                        e.stopPropagation();
                        onToggleDownloadDetails?.(nodeProg.nodeId);
                      }}
                    >
                      <div
                        class="flex items-center justify-between text-[11px] font-mono text-exo-light-gray"
                      >
                        <span class="text-white/80 truncate pr-2"
                          >{nodeProg.nodeName}</span
                        >
                        <span class="flex items-center gap-1 text-blue-300">
                          {nodePercent.toFixed(1)}%
                          <svg
                            class="w-3 h-3 text-exo-light-gray"
                            viewBox="0 0 20 20"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                          >
                            <path
                              d="M6 8l4 4 4-4"
                              class={isExpanded
                                ? "transform rotate-180 origin-center transition-transform duration-150"
                                : "transition-transform duration-150"}
                            ></path>
                          </svg>
                        </span>
                      </div>
                      <div
                        class="relative h-1.5 bg-exo-black/60 rounded-sm overflow-hidden"
                      >
                        <div
                          class="absolute inset-y-0 left-0 bg-gradient-to-r from-blue-500 to-blue-400 transition-all duration-300"
                          style="width: {nodePercent.toFixed(1)}%"
                        ></div>
                      </div>
                      <div
                        class="flex items-center justify-between text-[11px] font-mono text-exo-light-gray"
                      >
                        <span
                          >{formatBytes(nodeProg.progress.downloadedBytes)} / {formatBytes(
                            nodeProg.progress.totalBytes,
                          )}</span
                        >
                        <span
                          >{formatSpeed(nodeProg.progress.speed)} • ETA {formatEta(
                            nodeProg.progress.etaMs,
                          )}</span
                        >
                      </div>
                    </button>

                    {#if isExpanded}
                      <div class="mt-2 space-y-1.5">
                        {#if nodeProg.progress.files.length === 0}
                          <div
                            class="text-[11px] font-mono text-exo-light-gray/70"
                          >
                            No file details reported.
                          </div>
                        {:else}
                          {#each nodeProg.progress.files as f}
                            {@const filePercent = Math.min(
                              100,
                              Math.max(0, f.percentage ?? 0),
                            )}
                            {@const isFileComplete = filePercent >= 100}
                            <div
                              class="rounded border border-exo-medium-gray/30 bg-exo-black/40 p-2"
                            >
                              <div
                                class="flex items-center justify-between text-[10px] font-mono text-exo-light-gray/90"
                              >
                                <span class="truncate pr-2">{f.name}</span>
                                <span
                                  class={isFileComplete
                                    ? "text-green-400"
                                    : "text-white/80"}
                                  >{filePercent.toFixed(1)}%</span
                                >
                              </div>
                              <div
                                class="relative h-1 bg-exo-black/60 rounded-sm overflow-hidden mt-1"
                              >
                                <div
                                  class="absolute inset-y-0 left-0 bg-gradient-to-r {isFileComplete
                                    ? 'from-green-500 to-green-400'
                                    : 'from-exo-green to-exo-green/70'} transition-all duration-300"
                                  style="width: {filePercent.toFixed(1)}%"
                                ></div>
                              </div>
                              <div
                                class="flex items-center justify-between text-[10px] text-exo-light-gray/70 mt-0.5"
                              >
                                <span
                                  >{formatBytes(f.downloadedBytes)} / {formatBytes(
                                    f.totalBytes,
                                  )}</span
                                >
                                <span
                                  >{formatSpeed(f.speed)} • ETA {formatEta(
                                    f.etaMs,
                                  )}</span
                                >
                              </div>
                            </div>
                          {/each}
                        {/if}
                      </div>
                    {/if}
                  </div>
                {/each}
              </div>
            {/if}
            <div class="mt-2 space-y-1">
              <div class="text-xs text-blue-400 font-mono tracking-wider">
                DOWNLOADING
              </div>
              <p class="text-[11px] text-white/50 leading-relaxed">
                Downloading model files. Model runs on your devices so needs to
                be downloaded before you can chat.
              </p>
            </div>
          {:else}
            <div class="mt-1 space-y-1">
              <div
                class="text-xs {getStatusColor(
                  downloadInfo.statusText,
                )} font-mono tracking-wider"
              >
                {downloadInfo.statusText}
              </div>
              {#if isLoading}
                {@const loadStatus = deriveInstanceStatus(instance)}
                {#if loadStatus.totalLayers && loadStatus.totalLayers > 0}
                  <div class="mt-1 space-y-1">
                    <div class="flex justify-between text-xs font-mono">
                      <span class="text-yellow-400"
                        >{(
                          ((loadStatus.layersLoaded ?? 0) /
                            loadStatus.totalLayers) *
                          100
                        ).toFixed(0)}%</span
                      >
                      <span class="text-exo-light-gray"
                        >{loadStatus.layersLoaded ?? 0} / {loadStatus.totalLayers}
                        layers</span
                      >
                    </div>
                    <div
                      class="relative h-1.5 bg-exo-black/60 rounded-sm overflow-hidden"
                    >
                      <div
                        class="absolute inset-y-0 left-0 bg-gradient-to-r from-yellow-500 to-yellow-400 transition-all duration-300"
                        style="width: {((loadStatus.layersLoaded ?? 0) /
                          loadStatus.totalLayers) *
                          100}%"
                      ></div>
                    </div>
                  </div>
                {/if}
              {/if}
            </div>
          {/if}
        </div>
      </div>
    </div>
  {/each}
</div>
