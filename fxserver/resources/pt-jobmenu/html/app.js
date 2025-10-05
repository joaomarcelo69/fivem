const app = new Vue({
  el: '#app',
  data: {
    open: false,
    context: { job: null, grade: 0, isBoss: false, onDuty: false },
  fine: { citizenid: '', amount: 0, reason: '', id: '', speed: 0, speedLimit: 0 },
    actions: [],
    routeHud: { show: false, job: '', idx: 0, len: 0, last: 0, total: 0, dist: null },
    stop: { targetSrc: '', docs: null },
  },
  computed: {
    canIssueFine() {
      return this.isLeo(this.context.job) && this.context.onDuty && this.context.grade >= 1 && this.fine.citizenid && this.fine.amount > 0 && this.fine.reason
    },
    canReprint() {
      return this.isLeo(this.context.job) && this.context.onDuty && this.context.grade >= 2 && this.fine.citizenid
    }
  },
  methods: {
    isLeo(job) {
      return job === 'police' || job === 'psp' || job === 'gnr' || job === 'pj'
    },
    close() {
      this.open = false
      fetch(`https:
    },
    execAction(id) {
      const payload = JSON.stringify({ id })
      fetch(`https:
    },
    issueFine() {
      const payload = JSON.stringify(this.fine)
      fetch(`https:
    },
    reprintFine() {
      const payload = JSON.stringify({ citizenid: this.fine.citizenid, id: this.fine.id })
      fetch(`https:
    },
    stopCheckDocs() {
      const payload = JSON.stringify({ target: this.stop.targetSrc })
      fetch(`https:
    },
    stopImpound() {
      const payload = JSON.stringify({ target: this.stop.targetSrc })
      fetch(`https:
    }
  }
})
window.addEventListener('message', (e) => {
  const data = e.data || {}
  if (data.action === 'open') {
    app.context = data.context || app.context
    app.open = true
    fetch(`https:
  } else if (data.action === 'actions') {
    app.actions = Array.isArray(data.actions) ? data.actions : []
  } else if (data.action === 'fine:autoFill') {
    if (data.citizenid) app.fine.citizenid = data.citizenid
    if (typeof data.amount === 'number') app.fine.amount = data.amount
    if (data.reason) app.fine.reason = data.reason
    if (typeof data.speed === 'number') app.fine.speed = data.speed
    if (typeof data.limit === 'number') app.fine.speedLimit = data.limit
    if (!app.open) {
      app.open = true
    }
  } else if (data.action === 'close') {
    app.open = false
  } else if (data.action === 'hud:route') {
    const h = data.hud || {}
    app.routeHud.show = !!h.show
    if (h.job !== undefined) app.routeHud.job = h.job
    if (h.idx !== undefined) app.routeHud.idx = h.idx
    if (h.len !== undefined) app.routeHud.len = h.len
    if (h.last !== undefined) app.routeHud.last = h.last
    if (h.total !== undefined) app.routeHud.total = h.total
    if (h.dist !== undefined) app.routeHud.dist = h.dist
  } else if (data.action === 'stop:docs') {
    app.stop.docs = data.docs || null
  }
})
