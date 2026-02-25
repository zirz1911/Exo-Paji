<script lang="ts">
  interface Props {
    tbBridgeCycles: string[][];
    identitiesData: any;
    instanceData: Record<string, any>;
    rdmaCtlData: any;
    topologyData: any;
    compact?: boolean;
    // Helper functions
    getNodeName: (nodeId: string) => string;
    getTbBridgeServiceName: (cycle: string[]) => string;
    copyToClipboard?: (text: string) => Promise<void>;
    copiedCommand?: boolean;
    // Dismissal state
    tb5InfoDismissed?: boolean;
    macStudioEn2Dismissed?: boolean;
    onDismissTb5?: () => void;
    onDismissMacStudioEn2?: () => void;
  }

  let {
    tbBridgeCycles,
    identitiesData,
    instanceData,
    rdmaCtlData,
    topologyData,
    compact = false,
    getNodeName,
    getTbBridgeServiceName,
    copyToClipboard,
    copiedCommand = false,
    tb5InfoDismissed = false,
    macStudioEn2Dismissed = false,
    onDismissTb5,
    onDismissMacStudioEn2,
  }: Props = $props();

  // Warning icon SVG path
  const warningIconPath =
    "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z";

  // Check for macOS version mismatch
  const macosVersionMismatch = $derived.by(() => {
    if (!identitiesData || Object.keys(identitiesData).length === 0)
      return false;
    // Gather all unique macOS versions
    const versions = new Set<string>();
    const versionDetails: Array<{
      friendlyName: string;
      version: string;
      buildVersion: string;
    }> = [];
    for (const [nodeId, identityArray] of Object.entries(identitiesData)) {
      if (!Array.isArray(identityArray)) continue;
      for (const identity of identityArray) {
        const version = identity?.os_version;
        const buildVersion = identity?.build_version;
        if (version) {
          versions.add(version);
          versionDetails.push({
            friendlyName: getNodeName(nodeId),
            version,
            buildVersion: buildVersion || "unknown",
          });
        }
      }
    }
    // If more than 1 unique version, we have a mismatch
    return versions.size > 1 ? versionDetails : false;
  });

  // Check for TB5 hardware without RDMA enabled
  const tb5WithoutRdma = $derived.by(() => {
    if (!identitiesData || !rdmaCtlData) return false;
    // If any instances are running, don't show the banner (to avoid noise)
    if (Object.keys(instanceData).length > 0) return false;
    // Detect TB5 hardware on multiple nodes
    let tb5Count = 0;
    for (const [, identityArray] of Object.entries(identitiesData)) {
      if (!Array.isArray(identityArray)) continue;
      for (const identity of identityArray) {
        if (identity?.thunderbolt?.some((tb: any) => tb?.generation === 5)) {
          tb5Count++;
          break;
        }
      }
    }
    if (tb5Count < 2) return false;
    // Check if RDMA is enabled on any node
    for (const rdmaArray of Object.values(rdmaCtlData)) {
      if (Array.isArray(rdmaArray)) {
        for (const rdma of rdmaArray) {
          if (rdma?.enabled === true) return false;
        }
      }
    }
    return true;
  });

  // Check for Mac Studio en2 RDMA warning
  const macStudioEn2RdmaWarning = $derived.by(() => {
    if (!identitiesData || !rdmaCtlData || !topologyData) return false;
    // Only show if RDMA is enabled somewhere
    let rdmaEnabled = false;
    for (const rdmaArray of Object.values(rdmaCtlData)) {
      if (Array.isArray(rdmaArray)) {
        for (const rdma of rdmaArray) {
          if (rdma?.enabled === true) {
            rdmaEnabled = true;
            break;
          }
        }
      }
      if (rdmaEnabled) break;
    }
    if (!rdmaEnabled) return false;

    // Find all Mac Studios with en2 connections
    const warnings: Array<{
      nodeName: string;
      peerNodeName: string;
    }> = [];
    for (const [nodeId, identityArray] of Object.entries(identitiesData)) {
      if (!Array.isArray(identityArray)) continue;
      let isMacStudio = false;
      for (const identity of identityArray) {
        if (
          identity?.marketing_name?.toLowerCase()?.includes("mac studio") ||
          identity?.model_name?.toLowerCase()?.includes("mac studio")
        ) {
          isMacStudio = true;
          break;
        }
      }
      if (!isMacStudio) continue;

      // Check network interfaces for en2
      const node = topologyData.nodes?.[nodeId];
      if (!node) continue;
      const en2Interface = node.network_interfaces?.find(
        (iface: any) => iface.name === "en2",
      );
      if (!en2Interface) continue;

      // Check if en2 is connected to another node
      for (const [peerId, peerNode] of Object.entries(topologyData.nodes)) {
        if (peerId === nodeId) continue;
        const peerInterfaces = (peerNode as any).network_interfaces || [];
        for (const peerIface of peerInterfaces) {
          const peerAddresses = peerIface.addresses || [];
          const en2Addresses = en2Interface.addresses || [];
          // Check if there's any connection between en2 and peer
          if (
            en2Addresses.some((addr: string) =>
              peerAddresses.some((peerAddr: string) =>
                addr.startsWith(peerAddr.split(".").slice(0, 3).join(".")),
              ),
            )
          ) {
            warnings.push({
              nodeName: getNodeName(nodeId),
              peerNodeName: getNodeName(peerId),
            });
          }
        }
      }
    }
    return warnings.length > 0 ? warnings : false;
  });

  const showWarnings = $derived(
    tbBridgeCycles.length > 0 ||
      macosVersionMismatch ||
      (tb5WithoutRdma && !tb5InfoDismissed) ||
      (macStudioEn2RdmaWarning && !macStudioEn2Dismissed),
  );
</script>

{#if showWarnings}
  <div
    class="absolute {compact
      ? 'top-2 left-2'
      : 'top-4 left-4'} flex flex-col gap-2 z-40"
  >
    <!-- Thunderbolt Bridge Cycle Warning -->
    {#if tbBridgeCycles.length > 0}
      {@const cycle = tbBridgeCycles[0]}
      {@const serviceName = getTbBridgeServiceName(cycle)}
      {@const disableCmd = `sudo networksetup -setnetworkserviceenabled "${serviceName}" off`}
      <div class="group relative" role="alert">
        <div
          class="flex items-center gap-2 px-3 py-2 rounded border border-yellow-500/50 bg-yellow-500/10 backdrop-blur-sm cursor-help {compact
            ? 'px-2 py-1'
            : ''}"
        >
          <svg
            class="text-yellow-400 flex-shrink-0 {compact
              ? 'w-3.5 h-3.5'
              : 'w-5 h-5'}"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d={warningIconPath}
            />
          </svg>
          <span
            class="font-mono text-yellow-200 {compact
              ? 'text-[10px]'
              : 'text-sm'}"
          >
            {#if compact}
              TB CYCLE
            {:else}
              THUNDERBOLT BRIDGE CYCLE DETECTED
            {/if}
          </span>
        </div>

        {#if !compact}
          <!-- Tooltip on hover -->
          <div
            class="absolute top-full left-0 mt-2 w-80 p-3 rounded border border-yellow-500/30 bg-exo-dark-gray/95 backdrop-blur-sm opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50 shadow-lg"
          >
            <p class="text-xs text-white/80 mb-2">
              A network routing cycle was detected between nodes connected via
              Thunderbolt Bridge. This can cause connectivity issues.
            </p>
            <p class="text-xs text-white/60 mb-2">
              <span class="text-yellow-300">Affected nodes:</span>
              {cycle.map(getNodeName).join(" → ")}
            </p>
            <p class="text-xs text-white/60 mb-1">
              <span class="text-yellow-300">To fix:</span> Disable the Thunderbolt
              Bridge on one of the affected nodes:
            </p>
            {#if copyToClipboard}
              <button
                type="button"
                onclick={() => copyToClipboard?.(disableCmd)}
                class="w-full flex items-center gap-2 text-[10px] font-mono bg-exo-black/60 px-2 py-1.5 rounded text-exo-green break-all text-left hover:bg-exo-black/80 transition-colors cursor-pointer group/copy"
                title="Click to copy"
              >
                <span class="flex-1">{disableCmd}</span>
                <svg
                  class="w-3.5 h-3.5 flex-shrink-0 text-white/40 group-hover/copy:text-exo-green transition-colors"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                  stroke-width="2"
                >
                  {#if copiedCommand}
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M5 13l4 4L19 7"
                    />
                  {:else}
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
                    />
                  {/if}
                </svg>
              </button>
            {/if}
          </div>
        {/if}
      </div>
    {/if}

    <!-- macOS Version Mismatch Warning -->
    {#if macosVersionMismatch}
      <div class="group relative" role="alert">
        <div
          class="flex items-center gap-2 px-3 py-2 rounded border border-yellow-500/50 bg-yellow-500/10 backdrop-blur-sm cursor-help {compact
            ? 'px-2 py-1'
            : ''}"
        >
          <svg
            class="text-yellow-400 flex-shrink-0 {compact
              ? 'w-3.5 h-3.5'
              : 'w-5 h-5'}"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d={warningIconPath}
            />
          </svg>
          <span
            class="font-mono text-yellow-200 {compact
              ? 'text-[10px]'
              : 'text-sm'}"
          >
            {#if compact}
              macOS MISMATCH
            {:else}
              INCOMPATIBLE macOS VERSIONS
            {/if}
          </span>
        </div>

        {#if !compact}
          <!-- Tooltip on hover -->
          <div
            class="absolute top-full left-0 mt-2 w-80 p-3 rounded border border-yellow-500/30 bg-exo-dark-gray/95 backdrop-blur-sm opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50 shadow-lg"
          >
            <p class="text-xs text-white/80 mb-2">
              Nodes in this cluster are running different macOS versions. This
              may cause inference compatibility issues.
            </p>
            <div class="text-xs text-white/60 mb-2">
              <span class="text-yellow-300">Node versions:</span>
              {#each macosVersionMismatch as node}
                <div class="ml-2">
                  {node.friendlyName} — macOS {node.version} ({node.buildVersion})
                </div>
              {/each}
            </div>
            <p class="text-xs text-white/60">
              <span class="text-yellow-300">Suggested action:</span> Update all
              nodes to the same macOS version for best compatibility.
            </p>
          </div>
        {/if}
      </div>
    {/if}

    <!-- TB5 Without RDMA Warning -->
    {#if tb5WithoutRdma && !tb5InfoDismissed}
      <div class="group relative" role="status">
        <div
          class="flex items-center gap-2 px-3 py-2 rounded border border-yellow-500/50 bg-yellow-500/10 backdrop-blur-sm cursor-help {compact
            ? 'px-2 py-1'
            : ''}"
        >
          <svg
            class="text-yellow-400 flex-shrink-0 {compact
              ? 'w-3.5 h-3.5'
              : 'w-5 h-5'}"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d={warningIconPath}
            />
          </svg>
          <span
            class="font-mono text-yellow-200 {compact
              ? 'text-[10px]'
              : 'text-sm'}"
          >
            {#if compact}
              RDMA OFF
            {:else}
              RDMA NOT ENABLED
            {/if}
          </span>
          {#if !compact && onDismissTb5}
            <button
              type="button"
              onclick={onDismissTb5}
              class="ml-1 text-yellow-300/60 hover:text-yellow-200 transition-colors cursor-pointer"
              title="Dismiss"
            >
              <svg
                class="w-4 h-4"
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
        </div>

        {#if !compact}
          <!-- Tooltip on hover -->
          <div
            class="absolute top-full left-0 mt-2 w-80 p-3 rounded border border-yellow-500/30 bg-exo-dark-gray/95 backdrop-blur-sm opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50 shadow-lg"
          >
            <p class="text-xs text-white/80 mb-2">
              Thunderbolt 5 hardware detected on multiple nodes. Enable RDMA
              for significantly faster inter-node communication.
            </p>
            <p class="text-xs text-white/60 mb-1.5">
              <span class="text-yellow-300">To enable:</span>
            </p>
            <ol
              class="text-xs text-white/60 list-decimal list-inside space-y-0.5 mb-1.5"
            >
              <li>Connect nodes with TB5 cables</li>
              <li>Boot to Recovery (hold power 10s → Options)</li>
              <li>
                Run
                <code class="text-yellow-300 bg-yellow-400/10 px-1 rounded"
                  >rdma_ctl enable</code
                >
              </li>
              <li>Reboot</li>
            </ol>
            <p class="text-xs text-white/40">
              Requires macOS 26.2+, TB5 cables, and matching OS versions.
            </p>
          </div>
        {/if}
      </div>
    {/if}

    <!-- Mac Studio en2 RDMA Warning -->
    {#if macStudioEn2RdmaWarning && !macStudioEn2Dismissed}
      <div class="group relative" role="alert">
        <div
          class="flex items-center gap-2 px-3 py-2 rounded border border-red-500/50 bg-red-500/10 backdrop-blur-sm cursor-help {compact
            ? 'px-2 py-1'
            : ''}"
        >
          <svg
            class="text-red-400 flex-shrink-0 {compact
              ? 'w-3.5 h-3.5'
              : 'w-5 h-5'}"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="2"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              d={warningIconPath}
            />
          </svg>
          <span
            class="font-mono text-red-200 {compact ? 'text-[10px]' : 'text-sm'}"
          >
            {#if compact}
              BAD PORT
            {:else}
              RDMA INCOMPATIBLE PORT
            {/if}
          </span>
          {#if !compact && onDismissMacStudioEn2}
            <button
              type="button"
              onclick={onDismissMacStudioEn2}
              class="ml-1 text-red-300/60 hover:text-red-200 transition-colors cursor-pointer"
              title="Dismiss"
            >
              <svg
                class="w-4 h-4"
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
        </div>

        {#if !compact}
          <!-- Expanded tooltip on hover (Mac Studio diagram included in original) -->
          <div
            class="absolute top-full left-0 mt-2 w-96 p-4 rounded border border-red-500/30 bg-[#1a1a1a]/95 backdrop-blur-sm opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all duration-200 z-50 shadow-lg"
          >
            <p class="text-xs text-white/80 mb-3">
              The Thunderbolt 5 port next to the Ethernet port on Mac Studio
              does
              <span class="text-red-400 font-semibold">not support RDMA</span>.
              Move the cable to one of the other three TB5 ports.
            </p>

            <div class="text-xs text-white/60 mb-3">
              <span class="text-red-300">Affected:</span>
              {#each macStudioEn2RdmaWarning as conn}
                <div class="ml-2 mt-0.5">
                  <span class="text-white/80">{conn.nodeName}</span>
                  <span class="text-white/30">&rarr;</span>
                  <span class="text-white/60">{conn.peerNodeName}</span>
                  <span class="text-white/30 ml-1">(en2)</span>
                </div>
              {/each}
            </div>

            <p class="text-xs text-white/50">
              <span class="text-green-400">Fix:</span> Move the Thunderbolt cable
              to any of the three leftmost ports (all support RDMA).
            </p>
          </div>
        {/if}
      </div>
    {/if}
  </div>
{/if}
