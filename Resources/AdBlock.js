(() => {
  'use strict';
  if (window.__ytcarAdblock) return;
  window.__ytcarAdblock = true;

  // 1. Strip ad data from player responses before the player reads it.
  const AD_KEYS = ['adPlacements', 'playerAds', 'adSlots'];
  const strip = (o) => {
    if (o && typeof o === 'object') {
      for (const k of AD_KEYS) if (k in o) delete o[k];
    }
  };
  const clean = (o) => {
    if (o && typeof o === 'object') {
      strip(o);
      strip(o.playerResponse);
    }
    return o;
  };

  const origParse = JSON.parse;
  JSON.parse = function () {
    return clean(origParse.apply(this, arguments));
  };

  const origJson = Response.prototype.json;
  Response.prototype.json = function () {
    return origJson.apply(this, arguments).then(clean);
  };

  // The first player response is assigned inline by the page, not fetched.
  let initialPlayerResponse;
  try {
    Object.defineProperty(window, 'ytInitialPlayerResponse', {
      configurable: true,
      get() { return initialPlayerResponse; },
      set(v) { initialPlayerResponse = clean(v); },
    });
  } catch (_) { /* property already locked; the fallbacks below still run */ }

  // 2. Hide leftover ad containers.
  const style = document.createElement('style');
  style.textContent = [
    'ytm-promoted-sparkles-web-renderer',
    'ytm-promoted-video-renderer',
    'ytm-companion-ad-renderer',
    'ytm-statement-banner-renderer',
    'ytm-ad-slot-renderer',
    'ad-slot-renderer',
    '.ytp-ad-overlay-container',
    '.ytp-ad-image-overlay',
    '.ytp-paid-content-overlay',
    'ytm-rich-item-renderer:has(ad-slot-renderer)',
    'ytm-rich-item-renderer:has(ytm-ad-slot-renderer)',
  ].join(',') + '{display:none !important}';
  (document.head || document.documentElement).appendChild(style);

  // 3. Fallback: if an ad still plays, mute it, jump to the end, press skip.
  let mutedByUs = false;
  const SKIP = [
    '.ytp-skip-ad-button',
    '.ytp-ad-skip-button',
    '.ytp-ad-skip-button-modern',
    '.ytp-ad-skip-button-container button',
    '.ytm-skip-ad-button',
  ].join(',');

  setInterval(() => {
    const player = document.querySelector('#movie_player, .html5-video-player');
    const video = document.querySelector('video');
    const adShowing = !!(player && player.classList.contains('ad-showing'));

    if (video && adShowing) {
      if (!video.muted) { video.muted = true; mutedByUs = true; }
      if (isFinite(video.duration) && video.duration > 0) {
        video.currentTime = video.duration;
      }
    } else if (video && mutedByUs) {
      video.muted = false;
      mutedByUs = false;
    }

    document.querySelectorAll(SKIP).forEach((b) => b.click());
  }, 300);
})();
