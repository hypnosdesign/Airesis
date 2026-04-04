/**
 * Minimal jQuery shim for .js.erb templates.
 *
 * Implements only the subset of jQuery API used in server-rendered JS responses.
 * This is a transitional shim — each .js.erb should be converted to Turbo Streams
 * or vanilla JS over time, then this file can be removed.
 */

class JQueryShim {
  constructor(elements) {
    this.elements = elements || [];
    this.length = this.elements.length;
  }

  each(fn) {
    this.elements.forEach((el, i) => fn.call(el, i, el));
    return this;
  }

  html(content) {
    if (content === undefined) {
      return this.elements[0]?.innerHTML || '';
    }
    this.elements.forEach(el => { el.innerHTML = content; });
    return this;
  }

  text(content) {
    if (content === undefined) {
      return this.elements[0]?.textContent || '';
    }
    this.elements.forEach(el => { el.textContent = content; });
    return this;
  }

  append(content) {
    this.elements.forEach(el => {
      if (typeof content === 'string') {
        el.insertAdjacentHTML('beforeend', content);
      } else if (content instanceof JQueryShim) {
        content.elements.forEach(c => el.appendChild(c));
      } else if (content instanceof HTMLElement) {
        el.appendChild(content);
      }
    });
    return this;
  }

  prepend(content) {
    this.elements.forEach(el => {
      if (typeof content === 'string') {
        el.insertAdjacentHTML('afterbegin', content);
      } else if (content instanceof JQueryShim) {
        content.elements.forEach(c => el.insertBefore(c, el.firstChild));
      } else if (content instanceof HTMLElement) {
        el.insertBefore(content, el.firstChild);
      }
    });
    return this;
  }

  remove() {
    this.elements.forEach(el => el.remove());
    return this;
  }

  hide(duration, callback) {
    this.elements.forEach(el => { el.style.display = 'none'; });
    if (typeof duration === 'number' && callback) {
      setTimeout(callback, duration);
    } else if (typeof duration === 'function') {
      duration();
    }
    return this;
  }

  show(duration, callback) {
    this.elements.forEach(el => { el.style.display = ''; });
    if (typeof duration === 'number' && callback) {
      setTimeout(callback, duration);
    } else if (typeof duration === 'function') {
      duration();
    }
    return this;
  }

  fadeIn(duration) {
    this.elements.forEach(el => { el.style.display = ''; });
    return this;
  }

  fadeOut(duration, callback) {
    this.elements.forEach(el => { el.style.display = 'none'; });
    if (typeof callback === 'function') {
      setTimeout(callback, typeof duration === 'number' ? duration : 0);
    }
    return this;
  }

  val(value) {
    if (value === undefined) {
      return this.elements[0]?.value || '';
    }
    this.elements.forEach(el => { el.value = value; });
    return this;
  }

  find(selector) {
    const found = [];
    this.elements.forEach(el => {
      found.push(...el.querySelectorAll(selector));
    });
    return new JQueryShim(found);
  }

  closest(selector) {
    const found = [];
    this.elements.forEach(el => {
      const match = el.closest(selector);
      if (match) found.push(match);
    });
    return new JQueryShim(found);
  }

  parent() {
    const found = [];
    this.elements.forEach(el => {
      if (el.parentElement) found.push(el.parentElement);
    });
    return new JQueryShim(found);
  }

  children(selector) {
    const found = [];
    this.elements.forEach(el => {
      if (selector) {
        found.push(...el.querySelectorAll(':scope > ' + selector));
      } else {
        found.push(...el.children);
      }
    });
    return new JQueryShim(found);
  }

  addClass(className) {
    this.elements.forEach(el => el.classList.add(...className.split(' ')));
    return this;
  }

  removeClass(className) {
    this.elements.forEach(el => el.classList.remove(...className.split(' ')));
    return this;
  }

  toggleClass(className) {
    this.elements.forEach(el => el.classList.toggle(className));
    return this;
  }

  css(prop, value) {
    if (typeof prop === 'string' && value === undefined) {
      return getComputedStyle(this.elements[0])?.[prop] || '';
    }
    if (typeof prop === 'object') {
      this.elements.forEach(el => Object.assign(el.style, prop));
    } else {
      this.elements.forEach(el => { el.style[prop] = value; });
    }
    return this;
  }

  attr(name, value) {
    if (value === undefined) {
      return this.elements[0]?.getAttribute(name);
    }
    this.elements.forEach(el => el.setAttribute(name, value));
    return this;
  }

  removeAttr(name) {
    this.elements.forEach(el => el.removeAttribute(name));
    return this;
  }

  data(key, value) {
    if (value === undefined) {
      const el = this.elements[0];
      if (!el) return undefined;
      return el.dataset?.[key];
    }
    this.elements.forEach(el => { el.dataset[key] = value; });
    return this;
  }

  on(event, selectorOrHandler, handler) {
    if (typeof selectorOrHandler === 'function') {
      this.elements.forEach(el => el.addEventListener(event, selectorOrHandler));
    } else {
      // delegated events
      this.elements.forEach(el => {
        el.addEventListener(event, (e) => {
          const target = e.target.closest(selectorOrHandler);
          if (target && el.contains(target)) {
            handler.call(target, e);
          }
        });
      });
    }
    return this;
  }

  click(handler) {
    if (handler) {
      return this.on('click', handler);
    }
    this.elements.forEach(el => el.click());
    return this;
  }

  // Foundation stubs — no-op
  foundation() { return this; }
  destroy() { return this; }

  // Animation stubs
  animate(props, duration, callback) {
    if (typeof callback === 'function') callback();
    return this;
  }

  stop() { return this; }
  slideDown() { return this.show(); }
  slideUp() { return this.hide(); }
  slideToggle() {
    this.elements.forEach(el => {
      el.style.display = el.style.display === 'none' ? '' : 'none';
    });
    return this;
  }
}

function $(selector) {
  if (typeof selector === 'function') {
    // $(document).ready() or $(function)
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', selector);
    } else {
      selector();
    }
    return;
  }
  if (selector instanceof JQueryShim) return selector;
  if (selector instanceof HTMLElement || selector === document || selector === window) {
    return new JQueryShim([selector]);
  }
  if (typeof selector === 'string') {
    if (selector.trim().startsWith('<')) {
      // Create element from HTML string
      const temp = document.createElement('div');
      temp.innerHTML = selector.trim();
      return new JQueryShim([...temp.children]);
    }
    try {
      return new JQueryShim([...document.querySelectorAll(selector)]);
    } catch {
      return new JQueryShim([]);
    }
  }
  return new JQueryShim([]);
}

// Static methods
$.ajax = function(options) {
  const opts = typeof options === 'string' ? { url: options } : options;
  const fetchOpts = {
    method: opts.type || opts.method || 'GET',
    headers: {
      'X-Requested-With': 'XMLHttpRequest',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || '',
    },
  };
  if (opts.data) {
    if (fetchOpts.method === 'GET') {
      const params = new URLSearchParams(typeof opts.data === 'string' ? opts.data : opts.data);
      opts.url += (opts.url.includes('?') ? '&' : '?') + params.toString();
    } else {
      if (typeof opts.data === 'string') {
        fetchOpts.body = opts.data;
        fetchOpts.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      } else {
        fetchOpts.body = new URLSearchParams(opts.data).toString();
        fetchOpts.headers['Content-Type'] = 'application/x-www-form-urlencoded';
      }
    }
  }
  if (opts.dataType === 'script') {
    fetchOpts.headers['Accept'] = 'text/javascript';
  } else if (opts.dataType === 'json') {
    fetchOpts.headers['Accept'] = 'application/json';
  }

  return fetch(opts.url, fetchOpts)
    .then(response => {
      if (opts.dataType === 'json') return response.json();
      if (opts.dataType === 'script') {
        return response.text().then(text => {
          eval(text);
          return text;
        });
      }
      return response.text();
    })
    .then(data => {
      if (opts.success) opts.success(data);
    })
    .catch(err => {
      if (opts.error) opts.error(err);
    })
    .finally(() => {
      if (opts.complete) opts.complete();
    });
};

$.param = function(obj) {
  return new URLSearchParams(obj).toString();
};

$.extend = function(deep, target, ...sources) {
  if (typeof deep !== 'boolean') {
    sources.unshift(target);
    target = deep;
    deep = false;
  }
  return Object.assign(target, ...sources);
};

$.fn = JQueryShim.prototype;
$.fx = { off: false };

// Expose globally
window.$ = window.jQuery = $;

// No-op stubs for legacy global functions called by un-migrated .js.erb files.
// These prevent "X is not defined" errors during incremental migration.
// Remove these as each module is converted to Turbo Streams + Stimulus.
window.execute_page_js = function() {};
window.disegnaCountdown = function() {};
window.disegnaProgressBar = function() {};
window.checkScroll = function() {};
window.airesis_reveal = function() {};
window.ProposalsShow = {
  init_text_areas: function() {},
  checkScroll: function() {},
  destroy_countdowns: function() {},
  init_countdowns: function() {},
  firstCheck: false,
  checkActive: false,
  contributes: []
};
