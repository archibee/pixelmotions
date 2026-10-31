(() => {
  'use strict';

  const $ = (selector) => document.querySelector(selector);
  const state = {
    frames: [],
    selectedId: null,
    currentIndex: 0,
    durationMs: 100,
    playing: false,
    playTimer: 0,
    dragId: null,
  };

  const fileInput = $('#fileInput');
  const frameList = $('#frameList');
  const previewCanvas = $('#previewCanvas');
  const previewContext = previewCanvas.getContext('2d', { alpha: true });
  const MAX_FRAMES = 200;
  const MAX_TOTAL_PIXELS = 24_000_000;

  function setStatus(message, kind = '') {
    const status = $('#statusMessage');
    status.textContent = message;
    status.className = `status-message ${kind}`.trim();
  }

  function frameDimensions() {
    return {
      width: state.frames.reduce((max, frame) => Math.max(max, frame.width), 0),
      height: state.frames.reduce((max, frame) => Math.max(max, frame.height), 0),
    };
  }

  function formatDuration(milliseconds) {
    return `${(milliseconds / 1000).toFixed(milliseconds % 1000 === 0 ? 1 : 2)}초`;
  }

  function updateDuration() {
    const total = state.frames.length * state.durationMs;
    $('#durationSummary').textContent = `루프 길이 ${state.frames.length ? formatDuration(total) : '—'}`;
    $('#customDuration').value = (state.durationMs / 1000).toFixed(2);
  }

  function updateStats() {
    const count = state.frames.length;
    const { width, height } = frameDimensions();
    $('#frameCount').textContent = `${count}장`;
    $('#frameCountHero').textContent = `${count} frame${count === 1 ? '' : 's'}`;
    $('#canvasSizeHero').textContent = count ? `${width} × ${height}` : '— × —';
    $('#emptyHint').hidden = count > 0;
    $('#exportButton').disabled = count === 0;
    $('#clearFrames').disabled = count === 0;
    $('#previousFrame').disabled = count < 2;
    $('#nextFrame').disabled = count < 2;
    $('#playButton').disabled = count === 0;
    $('#frameScrubber').disabled = count === 0;
    $('#frameScrubber').max = Math.max(0, count - 1);
    $('#frameScrubber').value = Math.min(state.currentIndex, Math.max(0, count - 1));
    updateDuration();
  }

  function updatePreviewCanvasSize() {
    const { width, height } = frameDimensions();
    if (!width || !height) {
      previewCanvas.hidden = true;
      $('#previewEmpty').hidden = false;
      return;
    }
    if (previewCanvas.width !== width || previewCanvas.height !== height) {
      previewCanvas.width = width;
      previewCanvas.height = height;
    }
    previewCanvas.hidden = false;
    $('#previewEmpty').hidden = true;
  }

  function drawFrame(index) {
    if (!state.frames.length) return;
    state.currentIndex = (index + state.frames.length) % state.frames.length;
    const frame = state.frames[state.currentIndex];
    const { width, height } = frameDimensions();
    if (previewCanvas.width !== width || previewCanvas.height !== height) {
      previewCanvas.width = width;
      previewCanvas.height = height;
    }
    previewContext.clearRect(0, 0, width, height);
    previewContext.imageSmoothingEnabled = false;
    previewContext.drawImage(frame.bitmap, Math.floor((width - frame.width) / 2), Math.floor((height - frame.height) / 2));
    previewCanvas.hidden = false;
    $('#previewEmpty').hidden = true;
    $('#previewCaption').textContent = `${frame.name} · ${frame.width} × ${frame.height}`;
    $('#stageFrameLabel').textContent = `FRAME ${String(state.currentIndex + 1).padStart(2, '0')} / ${String(state.frames.length).padStart(2, '0')}`;
    $('#frameScrubber').value = state.currentIndex;
    updateSelectionHighlight();
  }

  function updateSelectionHighlight() {
    frameList.querySelectorAll('.frame-item').forEach((item, index) => {
      item.classList.toggle('selected', index === state.currentIndex);
      item.querySelector('.frame-order').textContent = String(index + 1).padStart(2, '0');
    });
  }

  function stopPlayback() {
    state.playing = false;
    if (state.playTimer) clearInterval(state.playTimer);
    state.playTimer = 0;
    $('#playIcon').textContent = '▶';
    $('#playText').textContent = '재생';
  }

  function startPlayback() {
    if (!state.frames.length) return;
    stopPlayback();
    state.playing = true;
    $('#playIcon').textContent = 'Ⅱ';
    $('#playText').textContent = '일시정지';
    state.playTimer = setInterval(() => drawFrame(state.currentIndex + 1), state.durationMs);
  }

  function togglePlayback() {
    if (state.playing) stopPlayback();
    else startPlayback();
  }

  function selectFrame(index) {
    if (!state.frames.length) return;
    drawFrame(index);
    if (state.playing) startPlayback();
  }

  function renderFrameList() {
    frameList.replaceChildren();
    state.frames.forEach((frame, index) => {
      const item = document.createElement('li');
      item.className = `frame-item${index === state.currentIndex ? ' selected' : ''}`;
      item.draggable = true;
      item.dataset.frameId = frame.id;
      item.setAttribute('aria-label', `프레임 ${index + 1}: ${frame.name}`);

      const order = document.createElement('span');
      order.className = 'frame-order';
      order.textContent = String(index + 1).padStart(2, '0');
      const thumbnail = document.createElement('img');
      thumbnail.className = 'frame-thumb';
      thumbnail.src = frame.url;
      thumbnail.alt = '';
      const info = document.createElement('span');
      info.className = 'frame-info';
      const name = document.createElement('strong');
      name.textContent = frame.name;
      name.title = frame.name;
      const dimensions = document.createElement('small');
      dimensions.textContent = `${frame.width} × ${frame.height}`;
      info.append(name, dimensions);

      const actions = document.createElement('span');
      actions.className = 'frame-actions-mini';
      actions.append(
        makeFrameAction('↑', `프레임 ${index + 1} 위로 이동`, () => moveFrame(index, index - 1), index === 0),
        makeFrameAction('↓', `프레임 ${index + 1} 아래로 이동`, () => moveFrame(index, index + 1), index === state.frames.length - 1),
        makeFrameAction('×', `프레임 ${index + 1} 제거`, () => removeFrame(frame.id), false),
      );
      item.append(order, thumbnail, info, actions);
      item.addEventListener('click', () => {
        state.selectedId = frame.id;
        selectFrame(index);
      });
      item.addEventListener('dragstart', (event) => {
        state.dragId = frame.id;
        item.classList.add('dragging');
        event.dataTransfer.effectAllowed = 'move';
        event.dataTransfer.setData('text/plain', frame.id);
      });
      item.addEventListener('dragend', () => {
        state.dragId = null;
        item.classList.remove('dragging');
        frameList.querySelectorAll('.drag-target').forEach((node) => node.classList.remove('drag-target'));
      });
      item.addEventListener('dragover', (event) => {
        event.preventDefault();
        item.classList.add('drag-target');
      });
      item.addEventListener('dragleave', () => item.classList.remove('drag-target'));
      item.addEventListener('drop', (event) => {
        event.preventDefault();
        item.classList.remove('drag-target');
        const fromId = state.dragId || event.dataTransfer.getData('text/plain');
        const from = state.frames.findIndex((candidate) => candidate.id === fromId);
        const to = state.frames.findIndex((candidate) => candidate.id === frame.id);
        if (from < 0 || to < 0 || from === to) return;
        const rect = item.getBoundingClientRect();
        let targetIndex = to + (event.clientY > rect.top + rect.height / 2 ? 1 : 0);
        if (from < targetIndex) targetIndex--;
        moveFrame(from, targetIndex);
      });
      frameList.append(item);
    });
    updateStats();
    updatePreviewCanvasSize();
    if (state.frames.length) drawFrame(Math.min(state.currentIndex, state.frames.length - 1));
  }

  function makeFrameAction(label, ariaLabel, action, disabled) {
    const button = document.createElement('button');
    button.type = 'button';
    button.textContent = label;
    button.title = ariaLabel;
    button.setAttribute('aria-label', ariaLabel);
    button.disabled = disabled;
    button.addEventListener('click', (event) => {
      event.stopPropagation();
      action();
    });
    return button;
  }

  function moveFrame(from, to) {
    if (from < 0 || from >= state.frames.length || to < 0 || to >= state.frames.length) return;
    const [frame] = state.frames.splice(from, 1);
    state.frames.splice(to, 0, frame);
    state.currentIndex = state.frames.findIndex((candidate) => candidate.id === frame.id);
    state.selectedId = frame.id;
    renderFrameList();
  }

  function removeFrame(id) {
    const index = state.frames.findIndex((frame) => frame.id === id);
    if (index < 0) return;
    const [frame] = state.frames.splice(index, 1);
    URL.revokeObjectURL(frame.url);
    frame.bitmap.close();
    if (!state.frames.length) {
      stopPlayback();
      state.selectedId = null;
      state.currentIndex = 0;
      $('#previewCaption').textContent = '프레임을 불러와 시작하세요';
      $('#stageFrameLabel').textContent = 'FRAME — / —';
      $('#previewEmpty').hidden = false;
      previewCanvas.hidden = true;
    } else {
      state.currentIndex = Math.min(index, state.frames.length - 1);
      state.selectedId = state.frames[state.currentIndex].id;
    }
    renderFrameList();
  }

  function clearFrames() {
    stopPlayback();
    state.frames.forEach((frame) => {
      URL.revokeObjectURL(frame.url);
      frame.bitmap.close();
    });
    state.frames = [];
    state.currentIndex = 0;
    state.selectedId = null;
    $('#previewCaption').textContent = '프레임을 불러와 시작하세요';
    $('#stageFrameLabel').textContent = 'FRAME — / —';
    $('#previewEmpty').hidden = false;
    previewCanvas.hidden = true;
    renderFrameList();
    setStatus('PNG 프레임을 추가하면 내보낼 수 있습니다.');
  }

  function naturalFileSort(a, b) {
    return a.name.localeCompare(b.name, undefined, { numeric: true, sensitivity: 'base' });
  }

  async function importFiles(fileList) {
    const files = Array.from(fileList).filter((file) => file.type === 'image/png' || file.name.toLowerCase().endsWith('.png')).sort(naturalFileSort);
    if (!files.length) {
      setStatus('PNG 파일만 불러올 수 있습니다.', 'error');
      return;
    }
    const available = MAX_FRAMES - state.frames.length;
    if (available <= 0) {
      setStatus(`한 프로젝트에는 최대 ${MAX_FRAMES}개 프레임까지 추가할 수 있습니다.`, 'error');
      return;
    }
    if (files.length > available) setStatus(`최대 ${MAX_FRAMES}개까지 추가할 수 있어 ${available}개만 처리합니다.`);
    let imported = 0;
    for (const file of files.slice(0, available)) {
      try {
        const bitmap = await createImageBitmap(file);
        if (!bitmap.width || !bitmap.height) {
          bitmap.close();
          continue;
        }
        state.frames.push({
          id: crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`,
          name: file.name,
          width: bitmap.width,
          height: bitmap.height,
          bitmap,
          url: URL.createObjectURL(file),
        });
        imported++;
      } catch {
        setStatus(`${file.name} 파일을 열지 못했습니다. PNG 파일인지 확인하세요.`, 'error');
      }
    }
    if (state.frames.length && !state.selectedId) {
      state.currentIndex = 0;
      state.selectedId = state.frames[0].id;
    }
    renderFrameList();
    if (imported) setStatus(`${imported}개 PNG를 프레임 목록에 추가했습니다. 순서는 드래그하거나 화살표로 바꿀 수 있습니다.`, 'success');
    fileInput.value = '';
  }

  function normalizeDuration(milliseconds) {
    return Math.max(20, Math.min(10000, Math.round(milliseconds / 10) * 10));
  }

  function updateDurationFromInput() {
    const seconds = Number($('#customDuration').value);
    if (!Number.isFinite(seconds)) return;
    state.durationMs = normalizeDuration(seconds * 1000);
    $('#customDuration').value = (state.durationMs / 1000).toFixed(2);
    updateDuration();
    if (state.playing) startPlayback();
  }

  function rgbKey(r, g, b) {
    return (r << 16) | (g << 8) | b;
  }

  function histogramKey(r, g, b) {
    return ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
  }

  function makeGlobalPalette(histogram, limit) {
    let boxes = [[...histogram.values()].map((color) => ({
      r: color.r / color.count,
      g: color.g / color.count,
      b: color.b / color.count,
      count: color.count
    }))];
    if (!boxes[0].length) boxes = [];
    while (boxes.length < limit) {
      let chosen = -1;
      let chosenChannel = 'r';
      let bestScore = -1;
      for (let boxIndex = 0; boxIndex < boxes.length; boxIndex++) {
        const box = boxes[boxIndex];
        if (box.length < 2) continue;
        const channels = ['r', 'g', 'b'].map((channel) => {
          let min = 255;
          let max = 0;
          box.forEach((color) => {
            min = Math.min(min, color[channel]);
            max = Math.max(max, color[channel]);
          });
          return { channel, range: max - min };
        }).sort((a, b) => b.range - a.range);
        const weight = box.reduce((sum, color) => sum + color.count, 0);
        const score = channels[0].range * Math.sqrt(weight);
        if (score > bestScore) {
          bestScore = score;
          chosen = boxIndex;
          chosenChannel = channels[0].channel;
        }
      }
      if (chosen < 0) break;
      const box = boxes[chosen].sort((a, b) => a[chosenChannel] - b[chosenChannel]);
      const total = box.reduce((sum, color) => sum + color.count, 0);
      let weight = 0;
      let splitAt = 1;
      for (; splitAt < box.length; splitAt++) {
        weight += box[splitAt - 1].count;
        if (weight >= total / 2) break;
      }
      boxes.splice(chosen, 1, box.slice(0, splitAt), box.slice(splitAt));
    }
    return boxes.map((box) => {
      let r = 0;
      let g = 0;
      let b = 0;
      let count = 0;
      box.forEach((color) => {
        r += color.r * color.count;
        g += color.g * color.count;
        b += color.b * color.count;
        count += color.count;
      });
      return [Math.round(r / count), Math.round(g / count), Math.round(b / count)];
    });
  }

  function buildGifPalette(histogram, hasTransparency) {
    const colors = makeGlobalPalette(histogram, hasTransparency ? 255 : 256);
    return hasTransparency ? [[0, 0, 0], ...colors] : colors;
  }

  function nearestColorIndex(r, g, b, palette, startIndex) {
    let bestIndex = startIndex;
    let bestDistance = Infinity;
    for (let i = startIndex; i < palette.length; i++) {
      const color = palette[i];
      const dr = r - color[0];
      const dg = g - color[1];
      const db = b - color[2];
      const distance = 0.299 * dr * dr + 0.587 * dg * dg + 0.114 * db * db;
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = i;
      }
    }
    return bestIndex;
  }

  function buildDitherLookup(palette, startIndex) {
    const lookup = new Uint8Array(1 << 15);
    for (let r = 0; r < 32; r++) {
      for (let g = 0; g < 32; g++) {
        for (let b = 0; b < 32; b++) {
          const key = (r << 10) | (g << 5) | b;
          lookup[key] = nearestColorIndex(r * 8 + 4, g * 8 + 4, b * 8 + 4, palette, startIndex);
        }
      }
    }
    return lookup;
  }

  async function mapFrameWithDithering(raster, width, height, lookup, palette, hasTransparency) {
    const visibleStart = hasTransparency ? 1 : 0;
    const indexes = new Uint8Array(width * height);
    let currentR = new Float32Array(width + 2);
    let currentG = new Float32Array(width + 2);
    let currentB = new Float32Array(width + 2);
    let nextR = new Float32Array(width + 2);
    let nextG = new Float32Array(width + 2);
    let nextB = new Float32Array(width + 2);

    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const pixelIndex = y * width + x;
        const sourceIndex = pixelIndex * 4;
        if (hasTransparency && raster[sourceIndex + 3] < 128) {
          indexes[pixelIndex] = 0;
          continue;
        }

        let errorIndex = x + 1;
        const r = Math.max(0, Math.min(255, raster[sourceIndex] + currentR[errorIndex]));
        const g = Math.max(0, Math.min(255, raster[sourceIndex + 1] + currentG[errorIndex]));
        const b = Math.max(0, Math.min(255, raster[sourceIndex + 2] + currentB[errorIndex]));
        const lookupKey = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
        const paletteIndex = lookup[lookupKey];
        indexes[pixelIndex] = paletteIndex;

        const color = palette[paletteIndex] || palette[visibleStart];
        const errorR = r - color[0];
        const errorG = g - color[1];
        const errorB = b - color[2];
        if (x + 1 < width && (!hasTransparency || raster[sourceIndex + 7] >= 128)) {
          currentR[errorIndex + 1] += errorR * (7 / 16);
          currentG[errorIndex + 1] += errorG * (7 / 16);
          currentB[errorIndex + 1] += errorB * (7 / 16);
        }
        if (y + 1 < height) {
          const below = sourceIndex + width * 4;
          if (x > 0 && (!hasTransparency || raster[below - 1] >= 128)) {
            nextR[errorIndex - 1] += errorR * (3 / 16);
            nextG[errorIndex - 1] += errorG * (3 / 16);
            nextB[errorIndex - 1] += errorB * (3 / 16);
          }
          if (!hasTransparency || raster[below + 3] >= 128) {
            nextR[errorIndex] += errorR * (5 / 16);
            nextG[errorIndex] += errorG * (5 / 16);
            nextB[errorIndex] += errorB * (5 / 16);
          }
          if (x + 1 < width && (!hasTransparency || raster[below + 7] >= 128)) {
            nextR[errorIndex + 1] += errorR * (1 / 16);
            nextG[errorIndex + 1] += errorG * (1 / 16);
            nextB[errorIndex + 1] += errorB * (1 / 16);
          }
        }
      }

      [currentR, nextR] = [nextR, currentR];
      [currentG, nextG] = [nextG, currentG];
      [currentB, nextB] = [nextB, currentB];
      nextR.fill(0);
      nextG.fill(0);
      nextB.fill(0);
      if ((y + 1) % 64 === 0) await new Promise((resolve) => setTimeout(resolve, 0));
    }
    return indexes;
  }

  async function mapFramesToPalette(rasters, width, height, palette, hasTransparency, dither) {
    const visibleStart = hasTransparency ? 1 : 0;
    const lookup = dither ? buildDitherLookup(palette, visibleStart) : null;
    const colorMap = new Map();
    const indexes = [];
    for (let frameIndex = 0; frameIndex < rasters.length; frameIndex++) {
      const raster = rasters[frameIndex];
      if (dither) {
        indexes.push(await mapFrameWithDithering(raster, width, height, lookup, palette, hasTransparency));
        setStatus(`고품질 색상 변환 중… ${frameIndex + 1}/${rasters.length}`);
        continue;
      }
      const frameIndexes = new Uint8Array(raster.length / 4);
      for (let sourceIndex = 0, pixelIndex = 0; sourceIndex < raster.length; sourceIndex += 4, pixelIndex++) {
        const alpha = raster[sourceIndex + 3];
        if (alpha < 128 && hasTransparency) {
          frameIndexes[pixelIndex] = 0;
          continue;
        }
        const r = raster[sourceIndex];
        const g = raster[sourceIndex + 1];
        const b = raster[sourceIndex + 2];
        const key = rgbKey(r, g, b);
        let paletteIndex = colorMap.get(key);
        if (paletteIndex === undefined) {
          paletteIndex = nearestColorIndex(r, g, b, palette, visibleStart);
          colorMap.set(key, paletteIndex);
        }
        frameIndexes[pixelIndex] = paletteIndex;
      }
      indexes.push(frameIndexes);
      setStatus(`색상 변환 중… ${frameIndex + 1}/${rasters.length}`);
      await new Promise((resolve) => setTimeout(resolve, 0));
    }
    return indexes;
  }

  function packLzw(indices, minCodeSize) {
    const clearCode = 1 << minCodeSize;
    const endCode = clearCode + 1;
    const codeSize = minCodeSize + 1;
    // Keep each dictionary below the next code-width boundary. Frequent clear
    // codes trade some compression for reliable bit alignment across decoders.
    const safeChunkSize = Math.max(1, Math.min(200, (1 << codeSize) - (endCode + 1)));
    let bitBuffer = 0;
    let bitCount = 0;
    const output = [];
    const writeCode = (code) => {
      bitBuffer |= code << bitCount;
      bitCount += codeSize;
      while (bitCount >= 8) {
        output.push(bitBuffer & 255);
        bitBuffer >>>= 8;
        bitCount -= 8;
      }
    };

    if (!indices.length) writeCode(clearCode);
    for (let chunkStart = 0; chunkStart < indices.length; chunkStart += safeChunkSize) {
      const chunkEnd = Math.min(indices.length, chunkStart + safeChunkSize);
      let nextCode = endCode + 1;
      let prefix = indices[chunkStart];
      const dictionary = new Map();
      writeCode(clearCode);
      for (let i = chunkStart + 1; i < chunkEnd; i++) {
        const symbol = indices[i];
        const key = prefix * 256 + symbol;
        const found = dictionary.get(key);
        if (found !== undefined) {
          prefix = found;
        } else {
          writeCode(prefix);
          dictionary.set(key, nextCode++);
          prefix = symbol;
        }
      }
      writeCode(prefix);
    }
    writeCode(endCode);
    if (bitCount) output.push(bitBuffer & 255);
    return output;
  }

  function makeGif(rasters, width, height, delayMs, loop, hasTransparency, palette, indexes) {
    let tableSize = 2;
    while (tableSize < palette.length) tableSize <<= 1;
    const sizeBits = Math.log2(tableSize) - 1;
    const minCodeSize = Math.max(2, Math.log2(tableSize));
    const bytes = [];
    const writeWord = (value) => bytes.push(value & 255, (value >> 8) & 255);
    const encoder = new TextEncoder();
    const writeText = (value) => bytes.push(...encoder.encode(value));

    writeText('GIF89a');
    writeWord(width);
    writeWord(height);
    bytes.push(0x80 | 0x70 | sizeBits, 0, 0);
    for (let i = 0; i < tableSize; i++) {
      const color = palette[i] || [0, 0, 0];
      bytes.push(color[0], color[1], color[2]);
    }
    if (loop) {
      bytes.push(0x21, 0xff, 0x0b);
      writeText('NETSCAPE2.0');
      bytes.push(3, 1, 0, 0, 0);
    }
    const delayCentiseconds = Math.max(2, Math.round(delayMs / 10));
    const frameCount = rasters.length;
    for (let i = 0; i < frameCount; i++) {
      bytes.push(0x21, 0xf9, 4, 0x08 | (hasTransparency ? 1 : 0));
      writeWord(delayCentiseconds);
      bytes.push(0, 0);
      bytes.push(0x2c);
      writeWord(0);
      writeWord(0);
      writeWord(width);
      writeWord(height);
      bytes.push(0);
      bytes.push(minCodeSize);
      const compressed = packLzw(indexes[i], minCodeSize);
      for (let offset = 0; offset < compressed.length; offset += 255) {
        const length = Math.min(255, compressed.length - offset);
        bytes.push(length);
        for (let j = 0; j < length; j++) bytes.push(compressed[offset + j]);
      }
      bytes.push(0);
    }
    bytes.push(0x3b);
    return new Blob([new Uint8Array(bytes)], { type: 'image/gif' });
  }

  async function exportGif() {
    if (!state.frames.length) return;
    stopPlayback();
    const button = $('#exportButton');
    button.disabled = true;
    setStatus('프레임 색상을 분석하고 GIF를 만드는 중…');
    await new Promise((resolve) => setTimeout(resolve, 0));
    try {
      const { width, height } = frameDimensions();
      const pixelCount = width * height * state.frames.length;
      if (width > 65535 || height > 65535 || pixelCount > MAX_TOTAL_PIXELS) {
        throw new Error(`현재 시퀀스는 내보내기 한도(${MAX_TOTAL_PIXELS.toLocaleString()} 프레임 픽셀)를 넘습니다. 프레임 수나 PNG 크기를 줄여 주세요.`);
      }
      const exportCanvas = document.createElement('canvas');
      exportCanvas.width = width;
      exportCanvas.height = height;
      const exportContext = exportCanvas.getContext('2d', { alpha: true, willReadFrequently: true });
      exportContext.imageSmoothingEnabled = false;
      const rasters = [];
      const histogram = new Map();
      let hasTransparency = false;
      const dither = $('#qualityMode').value === 'high';
      for (let frameIndex = 0; frameIndex < state.frames.length; frameIndex++) {
        const frame = state.frames[frameIndex];
        exportContext.clearRect(0, 0, width, height);
        exportContext.drawImage(frame.bitmap, Math.floor((width - frame.width) / 2), Math.floor((height - frame.height) / 2));
        const raster = exportContext.getImageData(0, 0, width, height).data;
        rasters.push(raster);
        for (let i = 0; i < raster.length; i += 4) {
          if (raster[i + 3] < 128) {
            hasTransparency = true;
            continue;
          }
          const key = histogramKey(raster[i], raster[i + 1], raster[i + 2]);
          let color = histogram.get(key);
          if (!color) {
            color = { r: 0, g: 0, b: 0, count: 0 };
            histogram.set(key, color);
          }
          color.r += raster[i];
          color.g += raster[i + 1];
          color.b += raster[i + 2];
          color.count++;
        }
        if (frameIndex % 12 === 0) setStatus(`색상 분석 중… ${frameIndex + 1}/${state.frames.length}`);
        await new Promise((resolve) => setTimeout(resolve, 0));
      }
      const palette = buildGifPalette(histogram, hasTransparency);
      const indexes = await mapFramesToPalette(rasters, width, height, palette, hasTransparency, dither);
      const blob = makeGif(rasters, width, height, state.durationMs, $('#loopToggle').checked, hasTransparency, palette, indexes);
      const url = URL.createObjectURL(blob);
      const anchor = document.createElement('a');
      anchor.href = url;
      anchor.download = 'pixel-motion.gif';
      anchor.click();
      setTimeout(() => URL.revokeObjectURL(url), 3000);
      setStatus(`GIF 저장 완료 · ${width} × ${height} · ${state.frames.length}프레임 · ${formatDuration(state.durationMs)} 간격`, 'success');
    } catch (error) {
      setStatus(error.message || 'GIF를 내보내지 못했습니다.', 'error');
    } finally {
      button.disabled = state.frames.length === 0;
    }
  }

  $('#addFrames').addEventListener('click', () => fileInput.click());
  $('#addFramesTop').addEventListener('click', () => fileInput.click());
  $('#dropZone').addEventListener('click', () => fileInput.click());
  $('#dropZone').addEventListener('keydown', (event) => {
    if (event.key === 'Enter' || event.key === ' ') {
      event.preventDefault();
      fileInput.click();
    }
  });
  fileInput.addEventListener('change', () => importFiles(fileInput.files));
  $('#dropZone').addEventListener('dragover', (event) => {
    event.preventDefault();
    $('#dropZone').classList.add('drag-over');
  });
  $('#dropZone').addEventListener('dragleave', () => $('#dropZone').classList.remove('drag-over'));
  $('#dropZone').addEventListener('drop', (event) => {
    event.preventDefault();
    $('#dropZone').classList.remove('drag-over');
    importFiles(event.dataTransfer.files);
  });
  $('#clearFrames').addEventListener('click', clearFrames);
  $('#previousFrame').addEventListener('click', () => selectFrame(state.currentIndex - 1));
  $('#nextFrame').addEventListener('click', () => selectFrame(state.currentIndex + 1));
  $('#playButton').addEventListener('click', togglePlayback);
  $('#frameScrubber').addEventListener('input', (event) => selectFrame(Number(event.target.value)));
  $('#exportButton').addEventListener('click', exportGif);
  $('#durationPreset').addEventListener('change', (event) => {
    if (event.target.value === 'custom') {
      $('#customDuration').focus();
      updateDurationFromInput();
      return;
    }
    state.durationMs = Number(event.target.value);
    updateDuration();
    if (state.playing) startPlayback();
  });
  $('#customDuration').addEventListener('input', () => {
    $('#durationPreset').value = 'custom';
    updateDurationFromInput();
  });
  $('#themeToggle').addEventListener('click', () => {
    const dark = document.documentElement.dataset.theme !== 'dark';
    document.documentElement.dataset.theme = dark ? 'dark' : 'light';
    $('#themeToggle').textContent = dark ? '☼' : '◐';
    localStorage.setItem('pixel-motion-theme', dark ? 'dark' : 'light');
  });

  const savedTheme = localStorage.getItem('pixel-motion-theme');
  if (savedTheme === 'dark') {
    document.documentElement.dataset.theme = 'dark';
    $('#themeToggle').textContent = '☼';
  }
  updateStats();
})();
