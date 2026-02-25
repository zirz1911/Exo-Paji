<script lang="ts">
  import { onMount } from 'svelte';

  // Props
  interface Props {
    leftContent?: any;
    rightContent?: any;
    leftHeader?: string;
    rightHeader?: string;
    defaultRatio?: number;
    minRatio?: number;
    maxRatio?: number;
    storageKey?: string;
  }

  let {
    leftContent,
    rightContent,
    leftHeader = "LEFT PANEL",
    rightHeader = "RIGHT PANEL",
    defaultRatio = 50,
    minRatio = 30,
    maxRatio = 70,
    storageKey = 'exo-split-ratio'
  }: Props = $props();

  // State
  let leftWidth = $state(defaultRatio);
  let isDragging = $state(false);
  let containerRef = $state<HTMLElement | null>(null);

  // Derived
  const rightWidth = $derived(100 - leftWidth);

  // Load saved ratio from localStorage
  onMount(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem(storageKey);
      if (saved) {
        const ratio = parseInt(saved);
        if (ratio >= minRatio && ratio <= maxRatio) {
          leftWidth = ratio;
        }
      }
    }
  });

  // Save ratio to localStorage
  function saveRatio(ratio: number) {
    if (typeof window !== 'undefined') {
      localStorage.setItem(storageKey, ratio.toString());
    }
  }

  // Start dragging
  function startDrag(e: MouseEvent) {
    e.preventDefault();
    isDragging = true;
    document.addEventListener('mousemove', onDrag);
    document.addEventListener('mouseup', stopDrag);
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';
  }

  // During drag
  function onDrag(e: MouseEvent) {
    if (!isDragging || !containerRef) return;

    const containerRect = containerRef.getBoundingClientRect();
    const x = e.clientX - containerRect.left;
    const newRatio = (x / containerRect.width) * 100;

    // Clamp between min and max
    leftWidth = Math.max(minRatio, Math.min(maxRatio, newRatio));
  }

  // Stop dragging
  function stopDrag() {
    if (isDragging) {
      isDragging = false;
      document.removeEventListener('mousemove', onDrag);
      document.removeEventListener('mouseup', stopDrag);
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
      saveRatio(Math.round(leftWidth));
    }
  }

  // Double-click to reset
  function resetRatio() {
    leftWidth = defaultRatio;
    saveRatio(defaultRatio);
  }

  // Keyboard shortcuts
  function handleKeydown(e: KeyboardEvent) {
    if (e.ctrlKey || e.metaKey) {
      if (e.key === '[') {
        e.preventDefault();
        leftWidth = Math.max(minRatio, leftWidth - 5);
        saveRatio(Math.round(leftWidth));
      } else if (e.key === ']') {
        e.preventDefault();
        leftWidth = Math.min(maxRatio, leftWidth + 5);
        saveRatio(Math.round(leftWidth));
      } else if (e.key === '0') {
        e.preventDefault();
        resetRatio();
      }
    }
  }
</script>

<svelte:window onkeydown={handleKeydown} />

<div
  bind:this={containerRef}
  class="flex flex-1 overflow-hidden relative"
>
  <!-- LEFT PANEL -->
  <section
    class="flex flex-col overflow-hidden border-r-2 transition-all duration-200 {isDragging ? 'border-exo-green/40' : 'border-exo-green/20'}"
    style="width: {leftWidth}%"
  >
    <!-- Panel Header -->
    {#if leftHeader}
      <div class="panel-header">
        {leftHeader}
      </div>
    {/if}

    <!-- Panel Content -->
    <div class="flex-1 overflow-hidden flex flex-col">
      {@render leftContent?.()}
    </div>
  </section>

  <!-- DIVIDER -->
  <div
    class="divider-container group"
    class:dragging={isDragging}
    role="separator"
    aria-orientation="vertical"
    aria-valuenow={Math.round(leftWidth)}
    aria-valuemin={minRatio}
    aria-valuemax={maxRatio}
    onmousedown={startDrag}
    ondblclick={resetRatio}
    tabindex="0"
  >
    <div class="divider-line"></div>
    <div class="divider-grip">
      <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 24 24">
        <circle cx="12" cy="6" r="1.5"/>
        <circle cx="12" cy="12" r="1.5"/>
        <circle cx="12" cy="18" r="1.5"/>
      </svg>
    </div>
  </div>

  <!-- RIGHT PANEL -->
  <section
    class="flex flex-col overflow-hidden"
    style="width: {rightWidth}%"
  >
    <!-- Panel Header -->
    {#if rightHeader}
      <div class="panel-header">
        {rightHeader}
      </div>
    {/if}

    <!-- Panel Content -->
    <div class="flex-1 overflow-hidden flex flex-col">
      {@render rightContent?.()}
    </div>
  </section>
</div>

<style>
  /* Panel Header */
  .panel-header {
    background: oklch(0.12 0 0); /* exo-black */
    border-bottom: 1px solid oklch(0.85 0.20 142 / 0.2); /* exo-green/20 */
    padding: 0.5rem 1rem;
    font-family: 'Silkscreen', monospace;
    font-size: 0.75rem;
    text-transform: uppercase;
    color: oklch(0.85 0.20 142); /* exo-green */
    letter-spacing: 0.1em;
    font-weight: normal;
    flex-shrink: 0;
  }

  /* Divider Container */
  .divider-container {
    position: relative;
    width: 8px;
    cursor: col-resize;
    flex-shrink: 0;
    display: flex;
    align-items: center;
    justify-content: center;
    background: oklch(0.12 0 0 / 0.5);
    transition: all 0.2s ease;
  }

  .divider-container:hover,
  .divider-container:focus {
    background: oklch(0.12 0 0 / 0.8);
  }

  .divider-container.dragging {
    background: oklch(0.85 0.20 142 / 0.2);
  }

  /* Divider Line */
  .divider-line {
    position: absolute;
    left: 50%;
    top: 0;
    bottom: 0;
    width: 2px;
    background: oklch(0.85 0.20 142 / 0.3);
    transform: translateX(-50%);
    transition: background 0.2s ease;
  }

  .divider-container:hover .divider-line,
  .divider-container.dragging .divider-line {
    background: oklch(0.85 0.20 142 / 0.8);
  }

  /* Divider Grip */
  .divider-grip {
    position: relative;
    z-index: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 0.5rem;
    color: oklch(0.85 0.20 142 / 0.4);
    opacity: 0;
    transition: opacity 0.2s ease;
  }

  .divider-container:hover .divider-grip,
  .divider-container:focus .divider-grip,
  .divider-container.dragging .divider-grip {
    opacity: 1;
    color: oklch(0.85 0.20 142);
  }

  /* Focus outline */
  .divider-container:focus {
    outline: 2px solid oklch(0.85 0.20 142 / 0.5);
    outline-offset: -2px;
  }
</style>
