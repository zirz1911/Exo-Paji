<script lang="ts">
  import type { Snippet } from "svelte";
  import { fade } from "svelte/transition";

  interface Props {
    // State
    chatStarted: boolean;
    sidebarVisible?: boolean;

    // Display state
    launchState?: "idle" | "launching" | "downloading" | "loading" | "ready";
    launchModelName?: string;
    launchDownloadProgress?: {
      percentage: number;
      downloadedBytes: number;
      totalBytes: number;
      speed: number;
      etaMs: number;
    } | null;
    launchLoadProgress?: {
      layersLoaded: number;
      totalLayers: number;
      percentage: number;
    } | null;

    // Model selector state
    showModelSelector?: boolean;
    selectedChatCategory?: string | null;
    suggestedPrompts?: string[];

    // Helper functions
    formatBytes?: (bytes: number, decimals?: number) => string;
    formatEta?: (ms: number) => string;

    // Callbacks
    onSuggestedPromptClick?: (prompt: string) => void;

    // Child components as snippets
    chatMessages?: Snippet;
    chatForm?: Snippet;
    chatSidebar?: Snippet;
    chatModelSelector?: Snippet;
  }

  let {
    chatStarted,
    sidebarVisible = false,
    launchState = "idle",
    launchModelName,
    launchDownloadProgress,
    launchLoadProgress,
    showModelSelector = false,
    selectedChatCategory = null,
    suggestedPrompts = [],
    formatBytes = (bytes) => `${(bytes / 1024 / 1024 / 1024).toFixed(2)} GB`,
    formatEta = (ms) => {
      const sec = Math.floor(ms / 1000);
      const min = Math.floor(sec / 60);
      const hr = Math.floor(min / 60);
      if (hr > 0) return `${hr}h ${min % 60}m`;
      if (min > 0) return `${min}m ${sec % 60}s`;
      return `${sec}s`;
    },
    onSuggestedPromptClick,
    chatMessages,
    chatForm,
    chatSidebar,
    chatModelSelector,
  }: Props = $props();

  const isLaunching = $derived(
    launchState !== "idle" && launchState !== "ready"
  );
  const hasMessages = $derived(chatStarted);
</script>

<div class="flex-1 flex overflow-hidden">
  <!-- Optional Sidebar -->
  {#if sidebarVisible && chatSidebar}
    <div class="w-80 flex-shrink-0 border-r border-exo-green/10">
      {@render chatSidebar()}
    </div>
  {/if}

  <!-- Main Chat Area -->
  <div
    class="flex-1 flex flex-col min-w-0 overflow-hidden"
    in:fade={{ duration: 300, delay: 100 }}
  >
    {#if isLaunching}
      <!-- Model launching/downloading/loading: show progress -->
      <div class="flex-1 flex items-center justify-center px-8 py-6">
        <div class="flex flex-col items-center gap-6 max-w-md w-full">
          <!-- Model name -->
          {#if launchModelName}
            <p class="text-sm text-white font-mono tracking-wide">
              {launchModelName.split("/").pop()?.replace(/-/g, " ") ||
                launchModelName}
            </p>
          {/if}

          {#if launchState === "launching"}
            <div class="flex flex-col items-center gap-3">
              <div
                class="w-8 h-8 border-2 border-exo-green/30 border-t-exo-green rounded-full animate-spin"
              ></div>
              <p
                class="text-xs text-exo-light-gray font-mono uppercase tracking-wider"
              >
                Preparing to launch&hellip;
              </p>
            </div>
          {:else if launchState === "downloading"}
            <div class="w-full flex flex-col gap-3">
              <div class="flex items-center justify-between text-xs font-mono">
                <span class="text-exo-green uppercase tracking-wider"
                  >Downloading</span
                >
                {#if launchDownloadProgress}
                  <span class="text-exo-light-gray tabular-nums">
                    {launchDownloadProgress.percentage.toFixed(1)}%
                  </span>
                {/if}
              </div>
              <div
                class="w-full h-2 bg-exo-dark-gray rounded-full overflow-hidden border border-exo-medium-gray/30"
              >
                <div
                  class="h-full bg-gradient-to-r from-exo-green/80 to-exo-green rounded-full transition-all duration-300"
                  style="width: {launchDownloadProgress?.percentage ?? 0}%"
                ></div>
              </div>
              {#if launchDownloadProgress}
                <div
                  class="flex justify-between text-[10px] text-exo-light-gray/60 font-mono"
                >
                  <span
                    >{formatBytes(launchDownloadProgress.downloadedBytes)} / {formatBytes(
                      launchDownloadProgress.totalBytes,
                    )}</span
                  >
                  <span>
                    {#if launchDownloadProgress.speed > 0}
                      {formatBytes(launchDownloadProgress.speed)}/s
                    {/if}
                    {#if launchDownloadProgress.etaMs > 0}
                      &middot; {formatEta(launchDownloadProgress.etaMs)}
                    {/if}
                  </span>
                </div>
              {/if}
            </div>
          {:else if launchState === "loading"}
            <div class="w-full flex flex-col gap-3">
              <div class="flex items-center justify-between text-xs font-mono">
                <span class="text-exo-green uppercase tracking-wider"
                  >Loading model</span
                >
                {#if launchLoadProgress}
                  <span class="text-exo-light-gray tabular-nums">
                    {launchLoadProgress.layersLoaded}/{launchLoadProgress.totalLayers}
                    layers
                  </span>
                {/if}
              </div>
              <div
                class="w-full h-2 bg-exo-dark-gray rounded-full overflow-hidden border border-exo-medium-gray/30"
              >
                <div
                  class="h-full bg-gradient-to-r from-exo-green/80 to-exo-green rounded-full transition-all duration-300"
                  style="width: {launchLoadProgress?.percentage ?? 0}%"
                ></div>
              </div>
            </div>
          {/if}
        </div>
      </div>
      <div
        class="flex-shrink-0 px-8 pb-6 pt-4 bg-gradient-to-t from-exo-black via-exo-black to-transparent"
      >
        <div class="max-w-7xl mx-auto">
          {#if chatForm}
            {@render chatForm()}
          {/if}
        </div>
      </div>
    {:else if hasMessages || launchState === "ready"}
      <!-- Normal chat: show messages -->
      <div
        class="flex-1 overflow-y-auto px-8 py-6"
        role="log"
        aria-live="polite"
        aria-label="Chat messages"
      >
        <div class="max-w-7xl mx-auto">
          {#if chatMessages}
            {@render chatMessages()}
          {/if}
          {#if launchState === "ready" && selectedChatCategory && suggestedPrompts.length > 0}
            <div
              class="flex flex-col items-center gap-4 mt-12"
              in:fade={{ duration: 300 }}
            >
              <p
                class="text-xs text-exo-light-gray/60 font-mono uppercase tracking-wider"
              >
                Try asking
              </p>
              <div class="grid grid-cols-2 gap-2 max-w-lg w-full">
                {#each suggestedPrompts as prompt}
                  <button
                    type="button"
                    onclick={() => onSuggestedPromptClick?.(prompt)}
                    class="text-left px-3 py-2.5 text-xs text-exo-light-gray hover:text-white font-mono rounded-lg border border-exo-medium-gray/30 hover:border-exo-green/30 bg-exo-dark-gray/30 hover:bg-exo-dark-gray/60 transition-all duration-200 cursor-pointer"
                  >
                    {prompt}
                  </button>
                {/each}
              </div>
            </div>
          {/if}
        </div>
      </div>
      <div
        class="flex-shrink-0 px-8 pb-6 pt-4 bg-gradient-to-t from-exo-black via-exo-black to-transparent"
      >
        <div class="max-w-7xl mx-auto">
          {#if chatForm}
            {@render chatForm()}
          {/if}
        </div>
      </div>
    {:else}
      <!-- No running instance, no messages: show model selector -->
      <div
        class="flex-1 overflow-y-auto flex items-center justify-center px-8 py-6"
      >
        {#if chatModelSelector}
          {@render chatModelSelector()}
        {/if}
      </div>
      <div
        class="flex-shrink-0 px-8 pb-6 pt-4 bg-gradient-to-t from-exo-black via-exo-black to-transparent"
      >
        <div class="max-w-7xl mx-auto">
          {#if chatForm}
            {@render chatForm()}
          {/if}
        </div>
      </div>
    {/if}
  </div>
</div>
