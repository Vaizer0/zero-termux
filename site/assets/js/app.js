/* Zero-Termux — shared site behavior: nav, copy, explorers, search, meta */
(function () {
  "use strict";

  var $ = function (sel, ctx) { return (ctx || document).querySelector(sel); };
  var $$ = function (sel, ctx) { return Array.prototype.slice.call((ctx || document).querySelectorAll(sel)); };

  /* ---------- nav (mobile) + active link ---------- */
  function initNav() {
    var toggle = $(".nav-toggle");
    var links = $(".nav-links");
    if (toggle && links) {
      toggle.addEventListener("click", function () {
        links.classList.toggle("open");
      });
    }
    var here = location.pathname.split("/").pop() || "index.html";
    $$(".nav-links a").forEach(function (a) {
      var href = a.getAttribute("href");
      if (href && href.split("#")[0] === here) a.classList.add("active");
    });
  }

  /* ---------- copy buttons ---------- */
  function copyText(txt, btn) {
    function done() {
      var old = btn.textContent;
      btn.textContent = "COPIED ✓";
      btn.classList.add("copied");
      setTimeout(function () {
        btn.textContent = old;
        btn.classList.remove("copied");
      }, 1600);
    }
    function fallback() {
      var ta = document.createElement("textarea");
      ta.value = txt;
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.select();
      try { document.execCommand("copy"); } catch (e) {}
      document.body.removeChild(ta);
      done();
    }
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(txt).then(done, fallback);
    } else {
      fallback();
    }
  }

  function initCopy() {
    // Static copy buttons: <button class="copy-btn" data-copy="text">
    $$("[data-copy]").forEach(function (btn) {
      btn.addEventListener("click", function () { copyText(btn.getAttribute("data-copy"), btn); });
    });
    // Copy buttons for <pre><code> blocks
    $$("pre").forEach(function (pre) {
      if (pre.querySelector(".copy-btn")) return;
      if ($("[data-explorer]", pre)) return;
      var btn = document.createElement("button");
      btn.className = "copy-btn";
      btn.textContent = "COPY";
      btn.setAttribute("type", "button");
      btn.addEventListener("click", function () { copyText(pre.innerText.replace(/\n$/, ""), btn); });
      pre.appendChild(btn);
    });
  }

  /* ---------- helpers ---------- */
  function esc(s) {
    return String(s == null ? "" : s)
      .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;").replace(/'/g, "&#39;");
  }

  function debounce(fn, ms) {
    var t;
    return function () {
      clearTimeout(t);
      var args = arguments;
      t = setTimeout(function () { fn.apply(null, args); }, ms);
    };
  }

  /* ---------- explorers ---------- */
  var demos = { "zero --version": "Show version" };

  function renderCommands(list) {
    var out = list.map(function (c) {
      var ex = (c.examples || []).map(function (e) {
        return '<div class="cmd"><code>zero ' + esc(e.replace(/^zero\s+/, "")) + "</code></div>";
      }).join("");
      return (
        "<details><summary>zero " + esc(c.name) + "</summary><div class='body'>" +
        "<p>" + esc(c.summary) + "</p>" +
        (c.syntax ? "<pre><code>" + esc(c.syntax) + "</code></pre>" : "") +
        (ex ? "<p><strong>Examples</strong></p>" + ex : "") +
        (c.notes ? "<p><em>" + esc(c.notes) + "</em></p>" : "") +
        "</div></details>"
      );
    }).join("");
    return out;
  }

  function renderModules(list) {
    return list.map(function (m) {
      var tools = m.tools.map(function (t) {
        return (
          '<div class="card tool-card"><h3><span class="mono">' + esc(t.name) + "</span></h3>" +
          "<p>" + esc(t.blurb) + "</p>" +
          '<span class="cmd">' + esc(t.install) + "</span></div>"
        );
      }).join("");
      return (
        '<section class="mod-group" id="' + esc(m.name) + '" data-name="' + esc(m.name).toLowerCase() + '" data-title="' + esc(m.title).toLowerCase() + '">' +
        '<h2><span class="mono">' + esc(m.name) + "</span> — " + esc(m.title) + ' <span class="count">' + m.tools.length + " tools</span></h2>" +
        "<p>" + esc(m.description) + "</p>" +
        '<div class="grid">' + tools + "</div></section>"
      );
    }).join("");
  }

  function renderPackages(list) {
    var rows = list.map(function (p) {
      return (
        "<tr><td><strong>" + esc(p.name) + "</strong><br><span class='cmd'>" + esc(p.install) + "</span></td>" +
        '<td class="ver">' + esc(p.version) + "</td>" +
        "<td>" + esc(p.description) + "</td>" +
        '<td class="cat">' + esc(p.category) + "</td></tr>"
      );
    }).join("");
    return (
      "<div class='table-scroll pkg-table'><table><thead><tr>" +
      "<th>Package (install)</th><th>Version</th><th>Description</th><th>Category</th>" +
      "</tr></thead><tbody>" + rows + "</tbody></table></div>"
    );
  }

  function initExplorer() {
    var root = $("[data-explorer]");
    if (!root) return;
    var kind = root.getAttribute("data-explorer");
    var url = "data/" + kind + ".json";
    var wrap = $(".explorer-wrap", root);
    if (!wrap) wrap = root;

    fetch(url).then(function (r) { return r.json(); }).then(function (data) {
      var all = data;
      var state = { filter: "", cat: "all" };
      var q = '[data-search="' + kind + '"]';
      var input = $(q, root) || $("[data-search]", root);
      var catSel = $('[data-cat="' + kind + '"]', root);

      function apply() {
        var list = all.filter(function (item) {
          var hit = !state.filter ||
            (kind === "commands"
              ? (item.name + " " + item.summary + " " + (item.syntax || "")).toLowerCase().indexOf(state.filter) !== -1
              : kind === "modules"
                ? (item.name + " " + item.title + " " + item.description + " " + item.tools.map(function (t) { return t.name; }).join(" ")).toLowerCase().indexOf(state.filter) !== -1
                : (item.name + " " + item.description).toLowerCase().indexOf(state.filter) !== -1);
          if (kind === "packages" && state.cat !== "all" && item.category !== state.cat) hit = false;
          if (kind === "modules" && state.cat !== "all" && item.name !== state.cat) hit = false;
          return hit;
        });
        var html;
        if (kind === "commands") html = renderCommands(list);
        else if (kind === "modules") html = renderModules(list);
        else html = renderPackages(list);
        wrap.innerHTML = html || "<p class='search-meta'>No results for “" + esc(state.filter) + "”.</p>";
        var metaEl = $(".search-meta", root);
        var count = kind === "modules"
          ? list.reduce(function (n, m) { return n + m.tools.length; }, 0)
          : list.length;
        if (metaEl) metaEl.textContent = count + " of " + all.length + " shown";
        initCopy();
      }

      if (input) {
        input.addEventListener("input", debounce(function () {
          state.filter = input.value.trim().toLowerCase();
          apply();
        }, 120));
      }
      if (catSel) {
        catSel.addEventListener("change", function () {
          state.cat = catSel.value;
          apply();
        });
        if (kind === "packages") {
          var cats = {};
          all.forEach(function (p) { cats[p.category] = true; });
          Object.keys(cats).sort().forEach(function (c) {
            var o = document.createElement("option");
            o.value = c; o.textContent = c;
            catSel.appendChild(o);
          });
        }
      }
      apply();
      var initial = $(".explorer-init", root);
      if (initial) initial.style.display = "none";
    }).catch(function () {
      wrap.innerHTML = "<p class='warn'>Could not load " + url + ". Regenerate site data: python3 scripts/site/generate-data.py</p>";
    });
  }

  /* ---------- meta stats on landing ---------- */
  function initStats() {
    var host = $("[data-stats]");
    if (!host) return;
    fetch("data/meta.json").then(function (r) { return r.json(); }).then(function (m) {
      var map = { packages: m.package_count, tools: m.tool_count, categories: m.category_count, commands: m.command_count, version: m.version };
      $$("[data-stat]", host).forEach(function (el) {
        var k = el.getAttribute("data-stat");
        if (k in map) el.textContent = map[k];
      });
    }).catch(function () {});
  }

  /* ---------- footer year ---------- */
  function initYear() {
    var y = $("[data-year]");
    if (y) y.textContent = new Date().getFullYear();
  }

  document.addEventListener("DOMContentLoaded", function () {
    initNav();
    initCopy();
    initExplorer();
    initStats();
    initYear();
  });
})();